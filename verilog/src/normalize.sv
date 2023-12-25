module Normalize (
    // input        i_clk,
    // input        i_reset_n,
    input  [15:0] i_data,  // int
    input  [15:0] i_std,   // int
    input  [15:0] i_mean,  // int
    output [15:0] o_norm   // fixed point
);
    // logic [23:0] ext_data_r, ext_data_w;
    // logic [23:0] ext_norm_r, ext_data_w;

    logic [23:0] ext_data, ext_norm;

    assign ext_data = {i_data - i_mean, 8'b0};
    assign ext_norm = ($signed(ext_data) > 0) ? (ext_data / i_std) : -(-ext_data / i_std);
    assign o_norm   = ext_norm[15:0];

    // always_comb begin
    //   ext_data_w = ext_data_r;
    //   ext_norm_w = ext_norm_r;
    //   
    //   ext_data_w = {i_data - i_mean, 8'b0};
    //   ext_norm_w = ($signed(ext_data_r) > 0) ? (ext_data_r / i_std) : -(-ext_data_r / i_std);
    // end

endmodule
