module Dedup (
    input i_clk,
    input i_rst_n,
    input i_next,
    input [4:0] i_tops[0:2],
    input [4:0] i_prev_tops[0:2],
    output o_finished,
    output o_next
);
    localparam S_IDLE = 3'd0;
    localparam S_VEC = 3'd1;
    localparam S_CHECK = 3'd2;

    logic [2:0] state_r, state_w;
    logic [26:0] prev_vec_r, prev_vec_w;
    logic [26:0] vec_r, vec_w;
    logic next_r, next_w, finish_r, finish_w;
    logic [1:0] sum;

    assign sum = prev_vec_r[i_tops[0]] * vec_r[i_tops[0]] + prev_vec_r[i_tops[1]] * vec_r[i_tops[1]] + prev_vec_r[i_tops[2]] * vec_r[i_tops[2]];
    assign o_next = next_r;
    assign o_finished = finish_r;

    always_comb begin
        state_w = state_r;
        prev_vec_w = prev_vec_r;
        vec_w = vec_r;
        next_w = next_r;
        finish_w = finish_r;

        case (state_r)
            S_IDLE: begin
                next_w = 0;
                finish_w = 1'b0;
                if (i_next) begin
                    state_w = S_VEC;
                    prev_vec_w = 0;
                    vec_w = 0;
                end
            end
            S_VEC: begin
                prev_vec_w[i_prev_tops[0]] = 1'b1;
                prev_vec_w[i_prev_tops[1]] = 1'b1;
                prev_vec_w[i_prev_tops[2]] = 1'b1;
                vec_w[i_tops[0]] = 1'b1;
                vec_w[i_tops[1]] = 1'b1;
                vec_w[i_tops[2]] = 1'b1;
                state_w = S_CHECK;
            end
            S_CHECK: begin
                next_w  = (sum >= 2'd2) ? 0 : 1;
                finish_w = 1'b1;
                state_w = S_IDLE;
            end
        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst_n) begin
        if (i_rst_n) begin
            state_r <= S_IDLE;
            prev_vec_r <= 0;
            vec_r <= 0;
            next_r <= 0;
            finish_r <= 0;
        end else begin
            state_r <= state_w;
            prev_vec_r <= prev_vec_w;
            vec_r <= vec_w;
            next_r <= next_w;
            finish_r <= finish_w;
        end
    end

endmodule
