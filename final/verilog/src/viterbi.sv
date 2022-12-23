module Viterbi (
    input i_clk,
    input i_rst_n,
    input i_start,
    input i_next,
    input [31:0] i_prob[0:2],
    input [4:0] i_char[0:2],
    output [119:0] o_seq,
    output o_stepped,
    output o_finished
);
    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_TOP = 2'd2;
    localparam S_DONE = 2'd3;

    logic [4:0] prev_char_r[0:2], prev_char_w[0:2];
    logic [1:0] state_r, state_w;
    logic [31:0] topN_prob0_r, topN_prob0_w, topN_prob1_r, topN_prob1_w, topN_prob2_r, topN_prob2_w;
    logic [31:0] tmp_prob0_r, tmp_prob0_w, tmp_prob1_r, tmp_prob1_w, tmp_prob2_r, tmp_prob2_w;
    logic [31:0] this_prob_r[0:2], this_prob_w[0:2];
    logic [119:0] tmp_seq_r[0:2], tmp_seq_w[0:2];
    logic [119:0] topN_seq0_r, topN_seq0_w, topN_seq1_r, topN_seq1_w, topN_seq2_r, topN_seq2_w;
    logic [119:0] top_seq_r, top_seq_w;
    logic [4:0] counter_r, counter_w;
    logic stepped_r, stepped_w, finish_r, finish_w;

    assign o_prob[0] = topN_prob0_r;
    assign o_prob[1] = topN_prob1_r;
    assign o_prob[2] = topN_prob2_r;
    assign o_seq = top_seq_r;

    assign o_stepped = stepped_r;
    assign o_finished = finish_r;

    always_comb begin
        state_w = state_r;
        topN_prob0_w = topN_prob0_r;
        topN_prob1_w = topN_prob1_r;
        topN_prob2_w = topN_prob2_r;
        topN_seq0_w = topN_seq0_r;
        topN_seq1_w = topN_seq1_r;
        topN_seq2_w = topN_seq2_r;
        top_seq_w = top_seq_r;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_CALC;
                    topN_prob0_w = 32'b0;
                    topN_prob1_w = 32'b0;
                    topN_prob2_w = 32'b0;
                    topN_seq0_w = 90'b0;
                    topN_seq1_w = 90'b0;
                    topN_seq2_w = 90'b0;
                end
                if (i_next) begin
                    state_w = S_CALC;
                end
                counter_w = 0;
            end
            S_CALC: begin
                if (topN_seq0_r == 0) begin
                    topN_prob0_w = i_prob[0] * transition_prob[i_char[0]];
                    topN_prob1_w = i_prob[1] * transition_prob[i_char[1]];
                    topN_prob2_w = i_prob[2] * transition_prob[i_char[2]];
                    topN_seq0_w = {112'b0, i_char[0]};
                    topN_seq1_w = {112'b0, i_char[1]};
                    topN_seq2_w = {112'b0, i_char[2]};
                    state_w = S_REST;
                    prev_char_w = i_char;
                end else begin
                    if (counter_r < 4) begin
                        if (counter_r < 3) begin
                            tmp_prob0_w = topN_prob0_r * i_prob[counter_w] * transition_prob[prev_char_r[0] * 27 + i_char[counter_r]];
                            tmp_prob1_w = topN_prob1_r * i_prob[counter_w] * transition_prob[prev_char_r[1] * 27 + i_char[counter_r]];
                            tmp_prob2_w = topN_prob2_r * i_prob[counter_w] * transition_prob[prev_char_r[2] * 27 + i_char[counter_r]];
                        end
                        if (counter_r > 0) begin
                            if (tmp_prob0_r > tmp_prob1_r & tmp_prob0_r > tmp_prob2_r) begin
                                tmp_seq_w[counter_r]   = {topN_seq0_r[111:0], 3'b0, i_char[counter_r] + 1};
                                this_prob_w[counter_r] = tmp_prob0_w;
                            end else if (tmp_prob1_r > tmp_prob0_r & tmp_prob1_r > tmp_prob2_r) begin
                                tmp_seq_w[counter_r]   = {topN_seq1_r[111:0], 3'b0, i_char[counter_r] + 1};;
                                this_prob_w[counter_r] = tmp_prob1_w;
                            end else if (tmp_prob2_r > tmp_prob0_r & tmp_prob2_r > tmp_prob1_r) begin
                                tmp_seq_w[counter_r]   = {topN_seq2_r[111:0], 3'b0, i_char[counter_r] + 1};;
                                this_prob_w[counter_r] = tmp_prob2_w;
                            end
                        end
                        counter_w = counter_r + 1;
                    end else begin
                        topN_prob0_w = this_prob_r[0];
                        topN_prob1_w = this_prob_r[1];
                        topN_prob2_w = this_prob_r[2];
                        topN_seq0_w = this_seq_r[0];
                        topN_seq1_w = this_seq_r[1];
                        topN_seq2_w = this_seq_r[2];
                        state_w = S_TOP;
                        counter_w = 0;
                    end
                end
            end
            S_TOP: begin
                if (topN_prob0_r > topN_prob1_r & topN_prob0_r > topN_prob2_r) begin
                    top_seq_w = topN_seq0_r;
                end else if (topN_prob1_r > topN_prob0_r & topN_prob1_r > topN_prob2_r) begin
                    top_seq_w = topN_seq1_r;
                end else if (topN_prob2_r > topN_prob0_r & topN_prob2_r > topN_prob1_r) begin
                    top_seq_w = topN_seq2_r;
                end
                state_w = S_IDLE;
            end
        endcase
    end

    always_ff @ (posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            prev_char_r <= '{3{5'b0}};
            state_r <= S_IDLE;
            topN_prob0_r <= 32'b0;
            topN_prob1_r <= 32'b0;
            topN_prob2_r <= 32'b0;
            tmp_prob0_r <= 32'b0;
            tmp_prob1_r <= 32'b0;
            tmp_prob2_r <= 32'b0;
            this_prob_r <= '{3{32'b0}};
            tmp_seq_r <= '{3{32'b0}};
            topN_seq0_r <= 120'b0;
            topN_seq1_r <= 120'b0;
            topN_seq2_r <= 120'b0;
            top_seq_r <= 120'b0;
            counter_r <= 5'b0;
            stepped_r <= 1'b0;
            finish_r <= 1'b0;
        end 
        else begin
            prev_char_r <= prev_char_w;
            state_r <= state_w;
            topN_prob0_r <= topN_prob0_w;
            topN_prob1_r <= topN_prob1_w;
            topN_prob2_r <= topN_prob2_w;
            tmp_prob0_r <= tmp_prob0_w;
            tmp_prob1_r <= tmp_prob1_w;
            tmp_prob2_r <= tmp_prob2_w;
            this_prob_r <= this_prob_w;
            tmp_seq_r <= tmp_seq_w;
            topN_seq0_r <= topN_seq0_w;
            topN_seq1_r <= topN_seq1_w;
            topN_seq2_r <= topN_seq2_w;
            top_seq_r <= top_seq_w;
            counter_r <= counter_w;
            stepped_r <= stepped_w;
            finish_r <= finish_w;
        end       
    end

endmodule
