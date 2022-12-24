`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    localparam [4:0] i_tops[0:3][0:2] = '{
        '{0, 3, 6},
        '{1, 2, 3},
        '{0, 26, 4},
        '{4, 5, 6}
    };

    localparam [4:0] i_prev_tops[0:3][0:2] = '{
        '{0, 3, 5},
        '{1, 2, 3},
        '{26, 0, 4},
        '{1, 4, 7}
    };

    logic clk, rst, i_next, o_next;
    logic [4:0] tops[0:2], prev_tops[0:2];

    initial clk = 0;
    initial i_next = 0;
    always #HCLK clk = ~clk;

    Dedup dedup(
        .i_clk(clk),
        .i_rst_n(rst),
        .i_next(i_next),
        .i_tops(tops),
        .i_prev_tops(prev_tops),
        .o_next(o_next)
    );

    initial begin
        $fsdbDumpfile("dedup.fsdb");
        $fsdbDumpvars;
        rst <= 0;
        #(2 * CLK);
        rst <= 1;
        @(posedge clk) rst <= 0;

        for (int i = 0; i < 4; i++) begin
            $display("=========inputs============");
            for (int j = 0; j < 3; ++j) begin
                tops[j] = i_tops[i][j];
                prev_tops[j] = i_prev_tops[i][j];
            end
            $display("tops : %0d\t%0d\t%0d", tops[0], tops[1], tops[2]);
            $display("prevs: %0d\t%0d\t%0d", prev_tops[0], prev_tops[1], prev_tops[2]);
            @(posedge clk) i_next = 1'b1;
            @(posedge clk) i_next = 1'b0;
            for (int j = 0; j < 5; j++) begin
                @(posedge clk);
                if (o_next == 1) begin
                    $display("next? %d", o_next);
                end
            end
        end
        

        $finish;

    end

endmodule

