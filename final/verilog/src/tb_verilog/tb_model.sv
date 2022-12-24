`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    /*localparam [15:0] data[0:39] = '{
        211, -353, 945, 307, 312, 305, 300, 299,
        203, -356, 957, 307, 311, 304, 299, 300,
        203, -360, 953, 309, 312, 306, 299, 297,
        207, -356, 949, 308, 314, 304, 297, 294,
        203, -364, 949, 310, 311, 300, 295, 294
    };*/
    
    localparam [15:0] data[0:39] = '{
        227, -356, 949, 306, 310, 302, 297, 298,
        231, -364, 941, 309, 312, 304, 300, 300,
        937, 0, -109, 312, 409, 414, 396, 352,
        996, 39, -149, 322, 411, 411, 391, 352,
        976, 15, -117, 332, 411, 414, 392, 349
    };

    logic clk, rst, start, finished;
    logic [31:0] logits[0:2];
    logic [4:0] chars[0:2];
    logic [23:0] cnn_output[0:29];
    logic [15:0] norm_data[0:39];

    initial clk = 0;
    always #HCLK clk = ~clk;

    Model WYSL (
        .i_clk(clk),
        .i_rst_n(rst),
        .i_start(start),
        .i_data(data),
        .o_norm(norm_data),
        .o_cnn(cnn_output),
        .o_logits(logits),
        .o_char(chars),
        .o_finished(finished)
    );

    initial begin
        $fsdbDumpfile("final.fsdb");
        $fsdbDumpvars;
        rst <= 0;
        #(2 * CLK);
        rst <= 1;
        @(posedge clk) rst <= 0;
        $display("=========inputs============");
        for (int i = 0; i < 5; i++) begin
            $display("%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\n", $signed(data[i*8]),
                     $signed(data[i*8+1]), $signed(data[i*8+2]), $signed(data[i*8+3]),
                     $signed(data[i*8+4]), $signed(data[i*8+5]), $signed(data[i*8+6]),
                     $signed(data[i*8+7]));
        end



        @(posedge clk) start <= 1;
        @(posedge clk) start <= 0;

        for (int i = 0; i < 200; i++) begin
            @(posedge clk);
        end

        $display("=========norm============");
        for (int i = 0; i < 5; i++) begin
            $display("%0f\t%0f\t%0f\t%0f\t%0f\t%0f\t%0f\t%0f\n",
                     $itor($signed(norm_data[i*8]) * SF), $itor($signed(norm_data[i*8+1]) * SF),
                     $itor($signed(norm_data[i*8+2]) * SF), $itor($signed(norm_data[i*8+3]) * SF),
                     $itor($signed(norm_data[i*8+4]) * SF), $itor($signed(norm_data[i*8+5]) * SF),
                     $itor($signed(norm_data[i*8+6]) * SF), $itor($signed(norm_data[i*8+7]) * SF));
        end

        $display("=========cnn============");
        for (int i = 0; i < 10; i++) begin
            $display("%f\t%f\t%f", $itor($signed(cnn_output[i*3]) * SF),
                     $itor($signed(cnn_output[i*3+1]) * SF), 
                     $itor($signed(cnn_output[i*3+2]) * SF));
        end

        $display("=========fc============");
        for (int i = 0; i < 3; i++) begin
            $display("output %c: %f", chars[i] + 'h41, $itor($signed(logits[i]) * SF));
        end

        $finish;

    end

endmodule
