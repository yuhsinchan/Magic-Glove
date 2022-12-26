`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    logic clk, rst, start, finished;
    logic [2:0] state;
    logic [119:0] word_in = 120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100010000;
    logic [119:0] word_out;

    initial clk = 0;
    always #HCLK clk = ~clk;

    Dictionary dict(
        .i_clk(clk),
        .i_rst_n(rst),
        .i_start(start),
        .i_word(word_in),
        .o_finish(finished),
        .o_word(word_out)
    );

    initial begin
        $fsdbDumpfile("Dict.fsdb");
        $fsdbDumpvars;

        rst <= 0;
        start <= 0;
        #(2 * CLK);
        rst <= 1;
        @(posedge clk) rst <= 0;

        $display("==========input=============");
        $display("%b", word_in);

        start <= 1;
        #(CLK)
        start <= 0;
        // #(10 * CLK);

        while (!finished) begin
            // $display(word_length);
            #(CLK);
        end
        $display();
        $display("==========output=============");
        $display("%b", word_out);
        $finish;

    end

    initial begin
		#(5000000*CLK)
		$display("Too Slow, Abort");
		$finish;
	end

endmodule
