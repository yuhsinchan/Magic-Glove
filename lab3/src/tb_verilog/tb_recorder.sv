`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, rst, lrc, start, pause, stop, data_adc;
	logic [19:0] address;
	logic [15:0] data_sram;

	initial clk = 0;
	always #HCLK clk = ~clk;

	AudRecorder recorder(
		.i_rst_n(rst),
		.i_clk(clk),
		.i_lrc(lrc),
		.i_start(start),
		.i_pause(pause),
		.i_stop(stop),
		.i_data(data_adc),
		.o_address(address),
		.o_data(data_sram)
	);

	initial begin
		$fsdbDumpfile("lab3_recorder.fsdb");
		$fsdbDumpvars;
		rst <= 1;
		#(2*CLK)
		rst <= 0;
		lrc <= 0;
		@(posedge clk) rst <= 1;
		@(posedge clk) start <= 1;
		@(posedge clk) start <= 0;
		for (int i = 0; i < 30; i++) begin
			lrc <= ~lrc;
			for (int j = 0; j < 20; j++) begin
				@(posedge clk) 
				if (j == 0) begin
					data_adc <= 0;
				end else begin
					data_adc <= j;
				end
			end
		end
		$finish;
	end

	initial begin
		#(37*CLK)
		pause <= 1;

		#(28*CLK)
		pause <= 0;
		start <= 1;
		@(posedge clk) start <= 0;

		#(180*CLK)
		stop <= 1;
	end

endmodule
