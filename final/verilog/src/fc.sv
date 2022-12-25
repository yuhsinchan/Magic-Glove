module FC(
    input i_clk,
    input i_rst_n,
    input i_start,
    input [15:0] i_weight [0:29],
    input [23:0] i_data [0:29],
    input [15:0] i_bias,
    output [31:0] o_output,
    output o_finished
);
    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_DONE = 2'd2;

    logic [1:0] state_r, state_w;
    logic signed [39:0] weighted_sum_r, weighted_sum_w;
    logic finish_r, finish_w;

    assign o_output = weighted_sum_r[39:8];
    assign o_finished = finish_r;

    always_comb begin
        finish_w = finish_r;
        state_w = state_r;
        weighted_sum_w = weighted_sum_r;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_CALC;
                end
            end
            S_CALC: begin
                weighted_sum_w = $signed(i_data[0])*$signed(i_weight[0]) + $signed(i_data[1])*$signed(i_weight[1]) + $signed(i_data[2])*$signed(i_weight[2]) + $signed(i_data[3])*$signed(i_weight[3]) + $signed(i_data[4])*$signed(i_weight[4]) + $signed(i_data[5])*$signed(i_weight[5]) + $signed(i_data[6])*$signed(i_weight[6]) + $signed(i_data[7])*$signed(i_weight[7]) + $signed(i_data[8])*$signed(i_weight[8]) + $signed(i_data[9])*$signed(i_weight[9]) + $signed(i_data[10])*$signed(i_weight[10]) + $signed(i_data[11])*$signed(i_weight[11]) + $signed(i_data[12])*$signed(i_weight[12]) + $signed(i_data[13])*$signed(i_weight[13]) + $signed(i_data[14])*$signed(i_weight[14]) + $signed(i_data[15])*$signed(i_weight[15]) + $signed(i_data[16])*$signed(i_weight[16]) + $signed(i_data[17])*$signed(i_weight[17]) + $signed(i_data[18])*$signed(i_weight[18]) + $signed(i_data[19])*$signed(i_weight[19]) + $signed(i_data[20])*$signed(i_weight[20]) + $signed(i_data[21])*$signed(i_weight[21]) + $signed(i_data[22])*$signed(i_weight[22]) + $signed(i_data[23])*$signed(i_weight[23]) + $signed(i_data[24])*$signed(i_weight[24]) + $signed(i_data[25])*$signed(i_weight[25]) + $signed(i_data[26])*$signed(i_weight[26]) + $signed(i_data[27])*$signed(i_weight[27]) + $signed(i_data[28])*$signed(i_weight[28]) + $signed(i_data[29])*$signed(i_weight[29]) + $signed({i_bias, 8'b0});
                state_w = S_DONE;
                finish_w = 1'b1;
            end
            S_DONE: begin
                finish_w = 1'b0;
                state_w = S_IDLE;
            end
        endcase

    end

    always_ff @ (posedge i_clk or posedge i_rst_n) begin
        if (i_rst_n) begin
            weighted_sum_r <= 0;
            finish_r <= 0;
            state_r <= S_IDLE;
        end
        else begin
            weighted_sum_r <= weighted_sum_w;
            finish_r <= finish_w;
            state_r <= state_w;
        end
    end
endmodule

