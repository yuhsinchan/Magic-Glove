module AudDSP (
    input i_rst_n,
    input i_clk,
    input i_start,
    input i_pause,
    input i_stop,
    input i_speed,
    input i_fast,
    input i_slow_0,  // constant interpolation
    input i_slow_1,  // linear interpolation
    input i_daclrck,
    input [15:0] i_sram_data,

    output [15:0] o_dac_data,
    output o_sram_addr
);

endmodule
