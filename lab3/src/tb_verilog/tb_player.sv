`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic rst, clk, daclrck, en, aud_dacdat;
    logic [15:0] dac_data;

	initial clk = 0;
	always #HCLK clk = ~clk;

	AudPlayer player(
        .i_rst_n(rst),
        .i_bclk(clk),
        .i_daclrck(daclrck),
        .i_en(en),
        .i_dac_data(dac_data),
        .o_aud_dacdat(aud_dacdat)
    );

	initial begin
		$fsdbDumpfile("lab3_player.fsdb");
		$fsdbDumpvars;
		rst <= 1;
		#(2*CLK)
		rst <= 0;
		daclrck <= 0;
		@(posedge clk) rst <= 1;
		@(posedge clk) en <= 1;
		for (int i = 35000; i < 35144; i++) begin
			@(negedge clk) daclrck <= ~daclrck;
			dac_data <= i;
			for (int j = 0; j < 20; j++) begin
				@(negedge clk);
			end
		end
		$finish;
	end

	// initial begin
	// 	#(37*CLK)
	// 	pause <= 1;

	// 	#(28*CLK)
	// 	pause <= 0;
	// 	start <= 1;
	// 	@(posedge clk) start <= 0;

	// 	#(180*CLK)
	// 	stop <= 1;
	// end

endmodule
