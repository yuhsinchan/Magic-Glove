module Core (
    input i_clk,
    input i_rst_n,
    input i_next,
    input signed [15:0] i_data[0:39],
    input [5:0] i_mode,
    output o_next,
    output o_finished,
    output [7:0] o_tops[0:2],
    output signed [31:0] o_logits[0:2],
    output [7:0] o_letter,
    output [119:0] o_word,
    output [3:0] o_length
);

    localparam S_IDLE = 0;
    localparam S_NN = 1; // input raw data to model and output top 3 char and prob
    localparam S_DEDUP = 2; // deduplicate
    localparam S_VITER = 3; // do viterbi algorithm
    localparam S_DTW = 4; // dynamic time warping
    localparam S_DONE = 5; // finish a word

    logic [2:0] state_r, state_w;

    logic nn_start_r, nn_start_w; // control start of nn model
    logic [4:0] pre_top_chars_r[0:2], pre_top_chars_w[0:2]; // last top 3 chars
    logic [4:0] pre_top_chars_d_r[0:2], pre_top_chars_d_w[0:2]; // last top 3 chars
    logic nn_finish; // model finished
    logic signed [31:0] nn_logits[0:2]; // top 3 prob
    logic [4:0] nn_top_chars[0:2]; // top 3 chars
    logic [4:0] counter_r, counter_w;

    logic signed [31:0] sum_logits_r[0:26], sum_logits_w[0:26];
    logic signed [31:0] avg_logits_r[0:2], avg_logits_w[0:2];
    logic [6:0] dup_count_r, dup_count_w;
    logic dup_finish;

    logic viter_start_r, viter_start_w;
    logic viter_next_r, viter_next_w;
    logic viter_stepped;
    logic [119:0] viter_seq;
    logic [4:0] viter_o_char;
    logic [119:0] o_seq_r, o_seq_w;

    logic [3:0] seq_length_r, seq_length_w;
    logic [3:0] seq_counter_r, seq_counter_w;
    logic [119:0] tmp_viter_seq_r, tmp_viter_seq_w;

    logic [119:0] dtw_seq;
    logic dict_start_r, dict_start_w;
    logic dict_finish;

    logic next_r, next_w;
    logic finish_r, finish_w;
    logic signed [15:0] data_r[0:39], data_w[0:39];
    logic no_dup;
    logic [4:0] output_char_r, output_char_w;
        
    logic [4:0] top_chars0, top_chars1, top_chars2;

    assign o_next = next_r;
    assign o_finished = finish_r;
    assign o_letter = output_char_r;
    
    // (i_mode == 6'b000000) ? viter_o_char: (
    //     (i_mode == 6'b000001) ? pre_top_chars_d_r[0] + 1: (
    //         (i_mode == 6'b000010) ? pre_top_chars_d_r[1] + 1 : (
    //             (i_mode == 6'b000011) ? pre_top_chars_d_r[2] + 1 : (
    //                 (i_mode == 6'b000100) ? nn_top_chars[0] + 1 : (
    //                     (i_mode == 6'b000101) ? nn_top_chars[1] + 1 : (
    //                         (i_mode == 6'b000110) ? nn_top_chars[2] + 1 : 0
    //                     )
    //                 )
    //             )
    //         )
    //     )
    // );

    assign o_word = dtw_seq;
    assign o_length = (dtw_seq[7:0] != 8'b0) + (dtw_seq[15:8] != 8'b0) + (dtw_seq[23:16] != 8'b0) + (dtw_seq[31:24] != 8'b0) + (dtw_seq[39:32] != 8'b0) + (dtw_seq[47:40] != 8'b0) + (dtw_seq[55:48] != 8'b0) + (dtw_seq[63:56] != 8'b0) + (dtw_seq[71:64] != 8'b0) + (dtw_seq[79:72] != 8'b0) + (dtw_seq[87:80] != 8'b0) + (dtw_seq[95:88] != 8'b0) + (dtw_seq[103:96] != 8'b0) + (dtw_seq[111:104] != 8'b0) + (dtw_seq[119:112] != 8'b0);
    assign o_tops[0] = nn_top_chars[0];
    assign o_tops[1] = nn_top_chars[1];
    assign o_tops[2] = nn_top_chars[2];
    assign o_logits = nn_logits;

    Model NMSL (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(nn_start_r),
        .i_data(data_r),
        .o_logits(nn_logits),
        .o_char(nn_top_chars),
        .o_finished(nn_finish)
    );

    Dedup dedup (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_tops(nn_top_chars),
        .i_prev_tops(pre_top_chars_r),
        .i_next(nn_finish),
        .o_finished(dup_finish),
        .o_next(no_dup)
    );

    Viterbi viterbi (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(viter_start_r),
        .i_next(viter_next_r),
        .i_prob(avg_logits_r),
        .i_char(pre_top_chars_r),
        .o_char(viter_o_char),
        .o_seq(viter_seq),
        .o_stepped(viter_stepped)
    );

    Dictionary dict(
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(dict_start_r),
        .i_word(viter_seq),
        .o_finish(dict_finish),
        .o_word(dtw_seq)
    );

    always_comb begin
        nn_start_w = nn_start_r;
        pre_top_chars_w = pre_top_chars_r;
        pre_top_chars_d_w = pre_top_chars_d_r;
        counter_w = counter_r;

        sum_logits_w = sum_logits_r;
        avg_logits_w = avg_logits_r;
        dup_count_w = dup_count_r;

        viter_start_w = viter_start_r;
        viter_next_w = viter_next_r;
        o_seq_w = o_seq_r;

        seq_length_w = seq_length_r;
        seq_counter_w = seq_counter_r;
        tmp_viter_seq_w = tmp_viter_seq_r;

        output_char_w = output_char_r;
        dict_start_w = dict_start_r;

        next_w = next_r;
        finish_w = finish_r;
        data_w = data_r;

        state_w = state_r;

        case (state_r)
            S_IDLE: begin
                next_w = 1'b0;
                finish_w = 1'b0;
                if (i_next) begin
                    state_w = S_NN;
                    nn_start_w = 1'b1;
                    data_w = i_data;
                end
            end
            S_NN: begin
                nn_start_w = 1'b0;
                if (nn_finish) begin
                    if (i_mode[5]) begin
                        state_w = S_IDLE;
                        case (i_mode[2:0])
                            3'b100: begin
                                output_char_w = nn_top_chars[0] + 1;
                            end
                            3'b101: begin
                                output_char_w = nn_top_chars[1] + 1;
                            end
                            3'b110: begin
                                output_char_w = nn_top_chars[2] + 1;
                            end
                        endcase
                        if (counter_r == 5'd29) begin
                            finish_w = 1'b1;
                            seq_length_w = 0;
                            counter_w = 0;
                        end else begin
                            next_w = 1'b1;
                            counter_w = counter_r + 1;
                        end
                    end else begin
                        state_w = S_DEDUP;
                    end
                end
            end
            S_DEDUP: begin
                if (dup_finish) begin
                    if (no_dup) begin
                        // if previous top 3 chars duplicated for more than 5 times and it is not space
                        // then calculate the average logits of top 3 chars and go to viterbi
                        if (dup_count_r > 5 && pre_top_chars_r[0] != 5'd26 && pre_top_chars_r[1] != 5'd26) begin
                            avg_logits_w[0] = sum_logits_w[pre_top_chars_r[0]] / dup_count_r;
                            avg_logits_w[1] = sum_logits_w[pre_top_chars_r[1]] / dup_count_r;
                            avg_logits_w[2] = sum_logits_w[pre_top_chars_r[2]] / dup_count_r;

                            state_w = S_VITER;

                            pre_top_chars_d_w = pre_top_chars_r;
                            
                            // if viter seq is empty, then rise the viterbi start signal
                            if (o_seq_r == {120{1'b0}}) begin
                                viter_start_w = 1'b1;
                            end else begin // if viter seq is not empty, then rise the viterbi next signal
                                viter_next_w = 1'b1;
                            end
                        end else begin
                            // skip
                            state_w = S_IDLE;
                            dup_count_w = 7'b0;
                            pre_top_chars_w = nn_top_chars;
                        end
                        sum_logits_w = '{27{32'b0}};
                        dup_count_w = 7'b0;
                    end else begin
                        sum_logits_w[nn_top_chars[0]] = sum_logits_r[nn_top_chars[0]] + nn_logits[0];
                        sum_logits_w[nn_top_chars[1]] = sum_logits_r[nn_top_chars[1]] + nn_logits[1];
                        sum_logits_w[nn_top_chars[2]] = sum_logits_r[nn_top_chars[2]] + nn_logits[2];
                        dup_count_w = dup_count_r + 1;

                        // finish or not
                        if (dup_count_r > 30 && (nn_top_chars[0] == 5'd26 || nn_top_chars[1] == 5'd26) && o_seq_r != {120{1'b0}}) begin
                            state_w = S_DTW;
                            dup_count_w = 0;
                            sum_logits_w = '{27{32'b0}};
                            seq_counter_w = 0;
                            tmp_viter_seq_w = viter_seq;
                            o_seq_w = viter_seq;
                            dict_start_w = 1'b1;
                        end else begin
                            state_w = S_IDLE;
                        end
                    end
                end
            end
            S_VITER: begin
                viter_start_w = 1'b0;
                viter_next_w = 1'b0;
                sum_logits_w[nn_top_chars[0]] = nn_logits[0];
                sum_logits_w[nn_top_chars[1]] = nn_logits[1];
                sum_logits_w[nn_top_chars[2]] = nn_logits[2];
                if (viter_stepped) begin
                    case (i_mode[2:0])
                        3'b000: begin
                            output_char_w = viter_o_char;
                        end
                        3'b001: begin
                            output_char_w = pre_top_chars_r[0] + 1;
                        end
                        3'b010: begin
                            output_char_w = pre_top_chars_r[1] + 1;
                        end
                        3'b011: begin
                            output_char_w = pre_top_chars_r[2] + 1;
                        end
                        3'b100: begin
                            output_char_w = nn_top_chars[0] + 1;
                        end
                        3'b101: begin
                            output_char_w = nn_top_chars[1] + 1;
                        end
                        3'b110: begin
                            output_char_w = nn_top_chars[2] + 1;
                        end
                    endcase
                    pre_top_chars_w = nn_top_chars;
                    state_w = S_IDLE;
                    next_w = 1'b1;
                    o_seq_w = viter_seq;
                end
            end
            S_DTW: begin
                dict_start_w = 1'b0;
                // if (seq_counter_r < 4'd15) begin
                //     if (tmp_viter_seq_r[4:0] != 0) begin
                //         seq_length_w = seq_counter_r + 1;
                //         tmp_viter_seq_w = {8'b0, tmp_viter_seq_r[119:8]};
                //     end else begin
                //         finish_w = 1'b1;
                //         state_w = S_DONE;
                //     end
                //     seq_counter_w = seq_counter_r + 1;
                // end else begin
                //     finish_w = 1'b1;
                //     state_w = S_DONE;
                // end
                if (dict_finish) begin
                    // $display("finish");
                    state_w = S_DONE;
                    finish_w = 1'b1;
                end
            end
            S_DONE: begin
                // reset logics
                finish_w = 1'b0;
                state_w = S_IDLE;
                sum_logits_w = '{27{32'b0}};
                avg_logits_w = '{3{32'b0}};
                dup_count_w = 7'b0;
                seq_length_w = 4'b0;
                seq_counter_w = 4'b0;
                tmp_viter_seq_w = 120'b0;
                o_seq_w = 120'b0;
                next_w = 1'b0;
            end
        endcase
    end

    always_ff @ (posedge i_clk or posedge i_rst_n) begin
        if (i_rst_n) begin
            nn_start_r <= 1'b0;
            pre_top_chars_r <= '{3{5'b0}};
            pre_top_chars_d_r <= '{3{5'b0}};
            counter_r <= 5'b0;

            sum_logits_r <= '{27{32'b0}};
            avg_logits_r <= '{3{32'b0}};
            dup_count_r <= 7'b0;

            viter_start_r <= 1'b0;
            viter_next_r <= 1'b0;
            o_seq_r <= 120'b0;

            seq_length_r <= 4'b0;
            seq_counter_r <= 4'b0;
            tmp_viter_seq_r <= 120'b0;

            dict_start_r <= 1'b0;
            output_char_r <= 5'b0;

            next_r <= 1'b0;
            finish_r <= 1'b0;
            data_r <= '{40{16'b0}};

            state_r <= S_IDLE;
        end else begin
            nn_start_r <= nn_start_w;
            pre_top_chars_r <= pre_top_chars_w;
            pre_top_chars_d_r <= pre_top_chars_d_w;
            counter_r <= counter_w;

            sum_logits_r <= sum_logits_w;
            avg_logits_r <= avg_logits_w;
            dup_count_r <= dup_count_w;

            viter_start_r <= viter_start_w;
            viter_next_r <= viter_next_w;
            o_seq_r <= o_seq_w;

            seq_length_r <= seq_length_w;
            seq_counter_r <= seq_counter_w;
            tmp_viter_seq_r <= tmp_viter_seq_w;

            dict_start_r <= dict_start_w;
            output_char_r <= output_char_w;

            next_r <= next_w;
            finish_r <= finish_w;
            data_r <= data_w;

            state_r <= state_w;
        end
    end

endmodule
