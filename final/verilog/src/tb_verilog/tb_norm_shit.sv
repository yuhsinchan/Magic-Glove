`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    logic clk, rst, start, finished;
    logic [15:0] n[0:7];
    logic [15:0] data[0:7];

    integer fp;

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
        $fsdbDumpfile("norm.fsdb");
        $fsdbDumpvars;
        fp = $fopen("./shit.bin", "rb");
        rst <= 0;
        #(2 * CLK);
        rst <= 1;
        @(posedge clk) rst <= 0;
        $display("=========inputs============");
        for (int d = 0; d < 100; d++) begin
            for (int i = 0; i < 8; i++) begin
                $fread(data[i], fp);
            end
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

            $display("%c\t%c\t%c\t%c\t%c\t%c\t%c\t%c\n", n[0][3:0] + 'h41,
                    n[1][3:0] + 'h41, n[2][3:0] + 'h41, n[3][3:0] + 'h41,
                    n[4][3:0] + 'h41, n[5][3:0] + 'h41, n[6][3:0] + 'h41,
                    n[7][3:0] + 'h41);
        end

        $finish;

    end

endmodule
