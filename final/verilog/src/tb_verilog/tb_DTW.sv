`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    localparam bit [119:0] DTW_candidate_word [0:19] = '{
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000100000001001100000101,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000100100000110,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000111,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000111100000101,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010100010000,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000001111,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110001000000010011,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000010100,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000001111,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101000010010000001000010101,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100011010,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101000010010000101000010100,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000010100001010100001001,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110100001000000010110,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101000010101,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011110001000000010101,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000010011,
      120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000110
    };

    logic clk, rst, start, finished;
    logic [2:0] state;
    logic [119:0] word_in = 120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000010010000011000001111;
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
        $fsdbDumpfile("final.fsdb");
        $fsdbDumpvars;

        rst <= 1;
        start <= 0;
        #(2 * CLK);
        rst <= 0;
        @(posedge clk) rst <= 1;

        $display("=========input============");
        $display(word_in);

        start <= 1;
        #(CLK)
        start <= 0;
        // #(10 * CLK);

        while (!finished) begin
            $display(state);
            #(CLK);
        end
        $display("=========output============");
        $display(word_out);
        $finish;

    $finish;


    end

    initial begin
		#(10000*CLK)
		$display("Too Slow, Abort");
		$finish;
	end

endmodule
