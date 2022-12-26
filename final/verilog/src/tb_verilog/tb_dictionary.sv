`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    logic clk, rst, start, finished;
    logic [1:0] state;
    logic [119:0] word_in = 120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000001010001100000010100;
    logic [119:0] word_out;
    logic [119:0] DTW_candidate_word [0:19];


    initial clk = 0;
    always #HCLK clk = ~clk;

    Dictionary dict(
        .i_clk(clk),
        .i_rst_n(rst),
        .i_start(start),
        .i_word(word_in),
        .o_finish(finished),
        .o_word(word_out),
        .o_state(state)
        // .o_DTW_candidate_word(DTW_candidate_word)
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
            #(CLK);
        end

        $display("==========output=============");
        $display("%b", word_out);
        
        $display("==========candidate==========");
        for (int i = 0; i < 20; i++) begin
            $display("%b", DTW_candidate_word[i]);
        end

        $finish;

    end

    initial begin
		#(500000*CLK)
		$display("Too Slow, Abort");
		$finish;
	end

endmodule