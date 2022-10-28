module I2cInitializer (
    input i_rst_n,
    input i_clk,
    input i_start,
    output o_finished,
    output o_sclk,
    output o_sdat,
    output o_oen  // you are outputing (you are not outputing only when you are "ack"ing.)
);

endmodule
