module Normalizer (
    input         i_clk,
    input         i_rst_n,
    input         i_start,
    input  [15:0] i_data    [0:7],  // int
    output [15:0] o_norm    [0:7],  // fixed point
    output        o_finished
);

    localparam bit [15:0] mean[0:7] = '{
        16'h0305,
        -16'h0058,
        16'h0101,
        16'h013e,
        16'h0144,
        16'h014e,
        16'h0154,
        16'h0133
    };

    localparam bit [15:0] std[0:7] = '{
        16'h01f1,
        16'h00fd,
        16'h0110,
        16'h0013,
        16'h002d,
        16'h002b,
        16'h0024,
        16'h0029
    };

    localparam S_IDLE = 2'd0;
    localparam S_EXTD = 2'd1;
    localparam S_CALC = 2'd2;
    localparam S_DONE = 2'd3;

    logic [23:0] ext_data0_r, ext_data0_w;
    logic [23:0] ext_data1_r, ext_data1_w;
    logic [23:0] ext_data2_r, ext_data2_w;
    logic [23:0] ext_data3_r, ext_data3_w;
    logic [23:0] ext_data4_r, ext_data4_w;
    logic [23:0] ext_data5_r, ext_data5_w;
    logic [23:0] ext_data6_r, ext_data6_w;
    logic [23:0] ext_data7_r, ext_data7_w;

    logic [23:0] ext_norm0_r, ext_norm0_w;
    logic [23:0] ext_norm1_r, ext_norm1_w;
    logic [23:0] ext_norm2_r, ext_norm2_w;
    logic [23:0] ext_norm3_r, ext_norm3_w;
    logic [23:0] ext_norm4_r, ext_norm4_w;
    logic [23:0] ext_norm5_r, ext_norm5_w;
    logic [23:0] ext_norm6_r, ext_norm6_w;
    logic [23:0] ext_norm7_r, ext_norm7_w;

    logic [1:0] state_r, state_w;
    logic finish_r, finish_w;

    assign o_norm[0]  = ext_norm0_r[15:0];
    assign o_norm[1]  = ext_norm1_r[15:0];
    assign o_norm[2]  = ext_norm2_r[15:0];
    assign o_norm[3]  = ext_norm3_r[15:0];
    assign o_norm[4]  = ext_norm4_r[15:0];
    assign o_norm[5]  = ext_norm5_r[15:0];
    assign o_norm[6]  = ext_norm6_r[15:0];
    assign o_norm[7]  = ext_norm7_r[15:0];

    assign o_finished = finish_r;

    always_comb begin
        state_w = state_r;
        finish_w = finish_r;

        ext_data0_w = ext_data0_r;
        ext_data1_w = ext_data1_r;
        ext_data2_w = ext_data2_r;
        ext_data3_w = ext_data3_r;
        ext_data4_w = ext_data4_r;
        ext_data5_w = ext_data5_r;
        ext_data6_w = ext_data6_r;
        ext_data7_w = ext_data7_r;

        ext_norm0_w = ext_norm0_r;
        ext_norm1_w = ext_norm1_r;
        ext_norm2_w = ext_norm2_r;
        ext_norm3_w = ext_norm3_r;
        ext_norm4_w = ext_norm4_r;
        ext_norm5_w = ext_norm5_r;
        ext_norm6_w = ext_norm6_r;
        ext_norm7_w = ext_norm7_r;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_EXTD;
                end
            end
            S_EXTD: begin
                ext_data0_w = {i_data[0] - mean[0], 8'b0};
                ext_data1_w = {i_data[1] - mean[1], 8'b0};
                ext_data2_w = {i_data[2] - mean[2], 8'b0};
                ext_data3_w = {i_data[3] - mean[3], 8'b0};
                ext_data4_w = {i_data[4] - mean[4], 8'b0};
                ext_data5_w = {i_data[5] - mean[5], 8'b0};
                ext_data6_w = {i_data[6] - mean[6], 8'b0};
                ext_data7_w = {i_data[7] - mean[7], 8'b0};
                // ext_data0_w = {i_data[0]};
                // ext_data1_w = {i_data[1]};
                // ext_data2_w = {i_data[2]};
                // ext_data3_w = {i_data[3]};
                // ext_data4_w = {i_data[4]};
                // ext_data5_w = {i_data[5]};
                // ext_data6_w = {i_data[6]};
                // ext_data7_w = {i_data[7]};
                state_w = S_CALC;
            end
            S_CALC: begin
                ext_norm0_w = ($signed(ext_data0_r) > 0) ? (ext_data0_r / std[0]) :
                    -(-ext_data0_r / std[0]);
                ext_norm1_w = ($signed(ext_data1_r) > 0) ? (ext_data1_r / std[1]) :
                    -(-ext_data1_r / std[1]);
                ext_norm2_w = ($signed(ext_data2_r) > 0) ? (ext_data2_r / std[2]) :
                    -(-ext_data2_r / std[2]);
                ext_norm3_w = ($signed(ext_data3_r) > 0) ? (ext_data3_r / std[3]) :
                    -(-ext_data3_r / std[3]);
                ext_norm4_w = ($signed(ext_data4_r) > 0) ? (ext_data4_r / std[4]) :
                    -(-ext_data4_r / std[4]);
                ext_norm5_w = ($signed(ext_data5_r) > 0) ? (ext_data5_r / std[5]) :
                    -(-ext_data5_r / std[5]);
                ext_norm6_w = ($signed(ext_data6_r) > 0) ? (ext_data6_r / std[6]) :
                    -(-ext_data6_r / std[6]);
                ext_norm7_w = ($signed(ext_data7_r) > 0) ? (ext_data7_r / std[7]) :
                    -(-ext_data7_r / std[7]);
                state_w = S_DONE;
                finish_w = 1'b1;
            end
            S_DONE: begin
                finish_w = 1'b0;
                state_w  = S_IDLE;
            end

        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst_n) begin
        if (i_rst_n) begin
            ext_data0_r <= 0;
            ext_data1_r <= 0;
            ext_data2_r <= 0;
            ext_data3_r <= 0;
            ext_data4_r <= 0;
            ext_data5_r <= 0;
            ext_data6_r <= 0;
            ext_data7_r <= 0;

            ext_norm0_r <= 0;
            ext_norm1_r <= 0;
            ext_norm2_r <= 0;
            ext_norm3_r <= 0;
            ext_norm4_r <= 0;
            ext_norm5_r <= 0;
            ext_norm6_r <= 0;
            ext_norm7_r <= 0;

            state_r <= S_IDLE;
            finish_r <= 0;
        end else begin
            ext_data0_r <= ext_data0_w;
            ext_data1_r <= ext_data1_w;
            ext_data2_r <= ext_data2_w;
            ext_data3_r <= ext_data3_w;
            ext_data4_r <= ext_data4_w;
            ext_data5_r <= ext_data5_w;
            ext_data6_r <= ext_data6_w;
            ext_data7_r <= ext_data7_w;

            ext_norm0_r <= ext_norm0_w;
            ext_norm1_r <= ext_norm1_w;
            ext_norm2_r <= ext_norm2_w;
            ext_norm3_r <= ext_norm3_w;
            ext_norm4_r <= ext_norm4_w;
            ext_norm5_r <= ext_norm5_w;
            ext_norm6_r <= ext_norm6_w;
            ext_norm7_r <= ext_norm7_w;

            state_r <= state_w;
            finish_r <= finish_w;
        end
    end

endmodule
