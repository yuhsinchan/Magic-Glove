module Conv(
    input i_clk,
    input i_rst_n,
    input i_start,
    input [15:0] i_kernel [0:23],
    input [15:0] i_data [0:39],
    input [15:0] i_bias,
    output [23:0] o_weights [0:2],
    output o_finished
);
    localparam S_IDLE = 0;
    localparam S_CALC = 1;
    localparam S_DONE = 2;

    logic [31:0] weighted_sum0_r, weighted_sum0_w;
    logic [31:0] weighted_sum1_r, weighted_sum1_w;
    logic [31:0] weighted_sum2_r, weighted_sum2_w;
    logic [1:0] counter_r, counter_w;
    logic [1:0] state_r, state_w;
    logic finish_r, finish_w;

    assign o_weights[0] = weighted_sum0_r[31:8];
    assign o_weights[1] = weighted_sum1_r[31:8];
    assign o_weights[2] = weighted_sum2_r[31:8];
    assign o_finished = finish_r;

    always_comb begin
        weighted_sum0_w = weighted_sum0_r;
        weighted_sum1_w = weighted_sum1_r;
        weighted_sum2_w = weighted_sum2_r;
        counter_w = counter_r;
        state_w = state_r;
        finish_w = finish_r;
        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_CALC;
                    counter_w = 0;
                end
            end
            S_CALC: begin
                case (counter_r)
                    2'd0: begin
                        weighted_sum0_w = $signed(i_data[0])*$signed(i_kernel[0]) + $signed(i_data[1])*$signed(i_kernel[1]) + $signed(i_data[2])*$signed(i_kernel[2]) + $signed(i_data[5])*$signed(i_kernel[3]) + $signed(i_data[6])*$signed(i_kernel[4]) + $signed(i_data[7])*$signed(i_kernel[5]) + $signed(i_data[10])*$signed(i_kernel[6]) + $signed(i_data[11])*$signed(i_kernel[7]) + $signed(i_data[12])*$signed(i_kernel[8]) + $signed(i_data[15])*$signed(i_kernel[9]) + $signed(i_data[16])*$signed(i_kernel[10]) + $signed(i_data[17])*$signed(i_kernel[11]) + $signed(i_data[20])*$signed(i_kernel[12]) + $signed(i_data[21])*$signed(i_kernel[13]) + $signed(i_data[22])*$signed(i_kernel[14]) + $signed(i_data[25])*$signed(i_kernel[15]) + $signed(i_data[26])*$signed(i_kernel[16]) + $signed(i_data[27])*$signed(i_kernel[17]) + $signed(i_data[30])*$signed(i_kernel[18]) + $signed(i_data[31])*$signed(i_kernel[19]) + $signed(i_data[32])*$signed(i_kernel[20]) + $signed(i_data[35])*$signed(i_kernel[21]) + $signed(i_data[36])*$signed(i_kernel[22]) + $signed(i_data[37])*$signed(i_kernel[23]) + $signed({i_bias, 8'b0});
                    end
                    2'd1: begin
                        weighted_sum1_w = $signed(i_data[1])*$signed(i_kernel[0]) + $signed(i_data[2])*$signed(i_kernel[1]) + $signed(i_data[3])*$signed(i_kernel[2]) + $signed(i_data[6])*$signed(i_kernel[3]) + $signed(i_data[7])*$signed(i_kernel[4]) + $signed(i_data[8])*$signed(i_kernel[5]) + $signed(i_data[11])*$signed(i_kernel[6]) + $signed(i_data[12])*$signed(i_kernel[7]) + $signed(i_data[13])*$signed(i_kernel[8]) + $signed(i_data[16])*$signed(i_kernel[9]) + $signed(i_data[17])*$signed(i_kernel[10]) + $signed(i_data[18])*$signed(i_kernel[11]) + $signed(i_data[21])*$signed(i_kernel[12]) + $signed(i_data[22])*$signed(i_kernel[13]) + $signed(i_data[23])*$signed(i_kernel[14]) + $signed(i_data[26])*$signed(i_kernel[15]) + $signed(i_data[27])*$signed(i_kernel[16]) + $signed(i_data[28])*$signed(i_kernel[17]) + $signed(i_data[31])*$signed(i_kernel[18]) + $signed(i_data[32])*$signed(i_kernel[19]) + $signed(i_data[33])*$signed(i_kernel[20]) + $signed(i_data[36])*$signed(i_kernel[21]) + $signed(i_data[37])*$signed(i_kernel[22]) + $signed(i_data[38])*$signed(i_kernel[23]) + $signed({i_bias, 8'b0});
                    end
                    2'd2: begin
                        weighted_sum2_w = $signed(i_data[2])*$signed(i_kernel[0]) + $signed(i_data[3])*$signed(i_kernel[1]) + $signed(i_data[4])*$signed(i_kernel[2]) + $signed(i_data[7])*$signed(i_kernel[3]) + $signed(i_data[8])*$signed(i_kernel[4]) + $signed(i_data[9])*$signed(i_kernel[5]) + $signed(i_data[12])*$signed(i_kernel[6]) + $signed(i_data[13])*$signed(i_kernel[7]) + $signed(i_data[14])*$signed(i_kernel[8]) + $signed(i_data[17])*$signed(i_kernel[9]) + $signed(i_data[18])*$signed(i_kernel[10]) + $signed(i_data[19])*$signed(i_kernel[11]) + $signed(i_data[22])*$signed(i_kernel[12]) + $signed(i_data[23])*$signed(i_kernel[13]) + $signed(i_data[24])*$signed(i_kernel[14]) + $signed(i_data[27])*$signed(i_kernel[15]) + $signed(i_data[28])*$signed(i_kernel[16]) + $signed(i_data[29])*$signed(i_kernel[17]) + $signed(i_data[32])*$signed(i_kernel[18]) + $signed(i_data[33])*$signed(i_kernel[19]) + $signed(i_data[34])*$signed(i_kernel[20]) + $signed(i_data[37])*$signed(i_kernel[21]) + $signed(i_data[38])*$signed(i_kernel[22]) + $signed(i_data[39])*$signed(i_kernel[23]) + $signed({i_bias, 8'b0});
                        finish_w = 1'b1;
                    end
                endcase
                counter_w = counter_r + 1;
            end
            S_DONE: begin
                finish_w = 0;
            end
        endcase
        
    end

    always_ff @ (posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            weighted_sum0_r <= 0;
            weighted_sum1_r <= 0;
            weighted_sum2_r <= 0;
            counter_r <= 0;
            state_r <= S_IDLE;
            finish_r <= 0;
        end
        else begin
            weighted_sum0_r <= weighted_sum0_w;
            weighted_sum1_r <= weighted_sum1_w;
            weighted_sum2_r <= weighted_sum2_w;
            counter_r <= counter_w;
            state_r <= state_w;
            finish_r <= finish_w;
        end
    end
endmodule
