`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, rst, start, finished, sclk, sdat, oen;
	initial clk = 0;
	always #HCLK clk = ~clk;

	I2cInitializer i2c(
		.i_rst_n(rst),
		.i_clk(clk),
		.i_start(start),
		.o_finished(finished),
		.o_sclk(sclk),
		.o_sdat(sdat),
		.o_oen(oen)
	);

	initial begin
		$fsdbDumpfile("lab3_i2c.fsdb");
		$fsdbDumpvars;
		rst <= 1;
		#(2*CLK)
		rst <= 0;
		@(posedge clk) rst <= 1;
		@(posedge clk) start <= 1;
		@(posedge clk) start <= 0;
		for (int i = 0; i < 500; i++) begin
			@(posedge clk);
		end
		$finish;
	end

endmodule
