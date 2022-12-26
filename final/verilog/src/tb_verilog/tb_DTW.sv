`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    localparam bit [119:0] DTW_candidate_word [0:19] = '{
        120'b000000000000000000000000000000000000000000000000000000000000100000000011000100100000000100000101000100110000010100010010,
		120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000010000010100010010,
		120'b000000000000000000000000000000000000000000000000000000000000000000000000000011000000010100010110000000010001001000010100,
		120'b000000000000000000000000000000000000000000000000000000000000010000000101000101100001001000000101000100110000010100010010,
		120'b000000000000000000000000000000000000000000000000000000000000000000000100000001010001010000000001000011000000010100010010,
		120'b000000000000000000000000000000000000000000000000000000000000110000000001000011100000111100010011000100100000010100010000,
		120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000001100100001100000100000000010100010010,
		120'b000000000000000000000000000000000000000000000000000000000000000000000101000001110000010100001100000011000000111100000011,
		120'b000000000000000000000000000000000000000000000000000000000000000000000101000011000000001100001001000101000001001000000001,
		120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000111000010010000000010000010100001100,
		120'b000000000000000000000000000000000000000000000000000000000001100100010010000011110000011100000101000101000000000100000011,
		120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000111000100100000000100001100,
		120'b000000000000000000000000000000000000000000000000000000000000000000011001000100100000010100001100000011000000000100000111,
		120'b000000000000000000000000000000000000000000000000000000000001001000000101000101000001001100001001000001110000010100010010,
		120'b000000000000000000000000000000000000000000000000000000000000000000011001000100100000000100010010000000100000100100001100,
		120'b000000000000000000000000000000000000000000000000000000000000000000000000000110010000110000001100000000010000010100010010,
		120'b000000000000000000000000000000000000000000000000000000000000000000000000000001010000110000010000000011110000010100010000,
		120'b000000000000000000000000000000000000000000000000000000000000000000000000000001010001001100000001000001010000110000010000,
		120'b000000000000000000000000000000000000000000000000000001010000110000000010000000010000110000001001000000010001011000000001,
		120'b000000000000000000000000000000000000000000000000000000000000000000001100000000010001001000000101000011100000010100000111
    };

    logic clk, rst, start, finished, valid;
    logic [2:0] state;
    logic [4:0] word_num;
    logic [14:0] dp;
    logic [119:0] word_in = 120'b000000000000000000000000000000000000000000000000000000000000000000011001000100100000010100001100000011000000000100000111;
    logic [119:0] word_out;
    initial clk = 0;
    always #HCLK clk = ~clk;

    DTW dtw1 (
        .i_DTW_clk(clk),
        .i_DTW_rst_n(rst),
        .i_DTW_start(start),
        .i_DTW_word(word_in),
        .i_DTW_candidate_word(DTW_candidate_word),
        .o_DTW_finish(finished),
        .o_DTW_word(word_out),
        .o_state(state)
    );

    initial begin
        $fsdbDumpfile("DTW.fsdb");
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
