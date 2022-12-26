`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    logic clk, rst, start, finished;
    logic [2:0] state;
    logic [103:0] word_count;
    logic [119:0] word_in = 120'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100010000;
    logic similarity_word [0:499];
    logic [4:0] similarity_value [0:499];
    logic [4:0] max_similarity_value;

    initial clk = 0;
    always #HCLK clk = ~clk;

    Similarity sim(
	    .i_similarity_clk(clk),
	    .i_similarity_rst_n(rst),
	    .i_similarity_start(start),
	    .i_similarity_word(word_in),
	    .o_similarity_finish(finished),
	    .o_similarity_word(similarity_word),
        .o_similarity_state(state),
        .o_word_count(word_count),
        .o_similarity_value(similarity_value),
        .o_max_similarity_value(max_similarity_value)
    );

    initial begin
        $fsdbDumpfile("similarity.fsdb");
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


        while (!finished) begin
            // $write(".");
            #(CLK);
        end

        $display();
        $display("==========output=============");
        // $display("word count");
        // $display("%b", word_count);

        
        // for (int i = 0; i < 500; i = i + 1) begin
        //     $display(similarity_value[i]);
        //     if (similarity_word[i] == 1) begin
        //         $display("yo");
        //     end
        //     $display(similarity_word[i]);
        // end
        
        // $display("max similarity value: ");
        // $display(max_similarity_value);

        $finish;

    end

    initial begin
		#(5000000*CLK)
		$display("Too Slow, Abort");
		$finish;
	end

endmodule
