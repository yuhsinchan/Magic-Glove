`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    localparam [15:0] data[0:7] = '{
      1012,
      19,
      -3,
      303,
      398,
      403,
      392,
      347
    };

    logic clk, rst, start, finished;
    logic [15:0] n[0:7];

    initial clk = 0;
    always #HCLK clk = ~clk;

    Normalizer norm (
        .i_clk(clk),
        .i_rst_n(rst),
        .i_start(start),
        .i_data(data),
        .o_norm(n),
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
        for (int i = 0; i < 1; i++) begin
            $display("%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\t%0d\n", $signed(data[i*8]),
                     $signed(data[i*8+1]), $signed(data[i*8+2]), $signed(data[i*8+3]),
                     $signed(data[i*8+4]), $signed(data[i*8+5]), $signed(data[i*8+6]),
                     $signed(data[i*8+7]));
        end

        @(posedge clk) start <= 1;
        @(posedge clk) start <= 0;

        for (int i = 0; i < 30; i++) begin
            @(posedge clk);
        end

        for (int i = 0; i < 8; i++) begin
            $display("output %d: %f", i, $itor($signed(n[i]) * SF));
        end

        $finish;

    end

endmodule
