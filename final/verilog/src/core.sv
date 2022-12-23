module Core (
    input i_clk,
    input i_rst_n,
    input i_next,
    input [15:0] i_data[0:39],
    output o_next,
    output o_finished,
    output [7:0] o_letter,
    output [119:0] o_word,
    output [3:0] o_length
);

    localparam S_IDLE = 0;
    localparam S_NN = 1;
    localparam S_DEDUP = 2;
    localparam S_VITER = 3;
    localparam S_DTW = 4;
    localparam S_DONE = 5;

    logic [2:0] state_r, state_w;

    logic nn_start_r, nn_start_w;
    logic nn_finish;
    logic [31:0] nn_logits[0:2];
    logic [4:0] nn_top_chars[0:2];
    logic [4:0] pre_top_chars_r[0:2], pre_top_chars_w[0:2];

    logic [31:0] sum_logits_r[0:26], sum_logits_w[0:26];
    logic [31:0] avg_logits_r[0:2], avg_logits_w[0:2];
    logic [6:0] dup_count_r, dup_count_w;

    logic viter_start_r, viter_start_w;
    logic viter_next_r, viter_next_w;
    logic viter_seq, viter_stepped;

    logic [3:0] seq_length_r, seq_length_w;
    logic [3:0] seq_counter_r, seq_counter_w;
    logic [119:0] tmp_viter_seq_r, tmp_viter_seq_w;

    logic next_r, next_w;
    logic finish_r, finish_w;
    logic no_dup;
    logic [7:0] letter_r, letter_w;
    logic [74:0] word_r, word_w;
    logic [15:0] data_r[0:39], data_w[0:39];

    assign o_next = next_r;
    assign o_finished = finish_r;
    assign o_letter = letter_r;
    assign o_word = viter_seq;
    assign o_length = seq_length_r;

    Model NMSL (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(nn_start_r),
        .i_data(data_r),
        .o_logits(nn_logits),
        .o_char(nn_top_chars_r),
        .o_finished(nn_finish)
    );

    Dedup dedup (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_tops(nn_top_chars),
        .i_prev_tops(pre_top_chars),
        .i_next(nn_finish),
        .o_next(no_dup)
    );

    Viterbi viterbi (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(viter_start_r),
        .i_next(viter_next_r),
        .i_prob(avg_logits_r),
        .i_char(pre_top_chars_r),
        .o_seq(viter_seq),
        .o_stepped(viter_stepped)
    );

    always_comb begin
        nn_start_w = nn_start_r;
        nn_logits_w = nn_logits_r;
        nn_finish_w = nn_finish_r;

        next_w = next_r;
        finish_w = finish_r;
        letter_w = letter_r;
        word_w = word_r;

        state_w = state_r;

        case (state_r)
            S_IDLE: begin
                next_w = 1'b0;
                if (i_next) begin
                    state_w = S_NN;
                    nn_start_w = 1'b1;
                    data_w = i_data;
                end
            end
            S_NN: begin
                if (nn_finish_r) begin
                    state_w = S_DEDUP;
                end
            end
            S_DEDUP: begin
                if (no_dup) begin
                    if (dup_count_r > 5 & pre_top_chars[0] != 5'd26 & pre_top_chars[1] != 5'd26) begin
                        // new letter
                        avg_logits_w[0] = sum_logits_w[pre_top_chars[0]] / dup_count_r;
                        avg_logits_w[1] = sum_logits_w[pre_top_chars[1]] / dup_count_r;
                        avg_logits_w[2] = sum_logits_w[pre_top_chars[2]] / dup_count_r;
                        sum_logits_w[nn_top_chars[0]] = nn_logits[0];
                        sum_logits_w[nn_top_chars[1]] = nn_logits[1];
                        sum_logits_w[nn_top_chars[2]] = nn_logits[2];
                        state_w = S_VITER;
                    end else begin
                        // skip
                        sum_logits_w = {27{32'b0}};
                        state_w = S_IDLE;
                        dup_count_w = 7'b0;
                        pre_top_chars_w = nn_top_chars;
                    end
                    dup_count_w = 7'b0;
                end else begin
                    sum_logits_w[nn_top_chars[0]] = sum_logits_r[nn_top_chars[0]] + nn_logits[0];
                    sum_logits_w[nn_top_chars[1]] = sum_logits_r[nn_top_chars[1]] + nn_logits[1];
                    sum_logits_w[nn_top_chars[2]] = sum_logits_r[nn_top_chars[2]] + nn_logits[2];
                    dup_count_w = dup_count_r + 1;

                    if (dup_count_r > 30 & nn_top_chars[0] != 5'd26 & nn_top_chars[1] != 5'd26) begin
                        state_w = S_DTW;
                        dup_count_w = 0;
                        sum_logits_w = {27{32'b0}};
                        seq_counter_w = 0;
                        tmp_viter_seq_w = viter_seq;
                    end else begin
                        state_w = S_IDLE;
                    end
                end
            end
            S_VITER: begin
                if (viter_stepped) begin
                    pre_top_chars_w = nn_top_chars_r;
                    letter_w = viter_seq[7:0];
                    state_w = S_IDLE;
                    next_w = 1'b1;
                end
            end
            S_DTW: begin
                if (seq_counter_r < 4'd15) begin
                    if (tmp_viter_seq_r[7:0] != 0) begin
                        seq_length_w = seq_counter_r + 1;
                        tmp_viter_seq_w = {8'b0, tmp_viter_seq_r[119:8]};
                    end
                end else begin
                    if (tmp_viter_seq_r[7:0] != 0) begin
                        seq_length_w = 4'd15;
                    end
                    finish_w = 1'b1;
                end
            end
            S_DONE: begin
                finish_w = 1'b0;
            end
        endcase
    end

endmodule
