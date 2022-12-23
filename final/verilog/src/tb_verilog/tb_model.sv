`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    localparam [15:0] data[0:39] = '{
        1012,
        19,
        -3,
        303,
        398,
        403,
        392,
        347,
        1015,
        23,
        -3,
        301,
        397,
        402,
        395,
        354,
        1012,
        23,
        -11,
        300,
        394,
        399,
        391,
        350,
        1012,
        15,
        -7,
        301,
        396,
        401,
        393,
        351,
        1019,
        31,
        3,
        301,
        396,
        401,
        393,
        350
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
        rst <= 1;
        #(2 * CLK);
        rst <= 0;
        @(posedge clk) rst <= 1;
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
