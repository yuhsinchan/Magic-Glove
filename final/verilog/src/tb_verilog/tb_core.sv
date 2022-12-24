`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    logic [15:0] data[0:39];
    integer fp;
        
    logic clk, rst, i_next, o_next, o_finished;
    logic [7:0] o_letter;
    logic [119:0] o_word;
    logic [3:0] o_length;
    
    initial clk = 0;    
    initial i_next = 0;
    always #HCLK clk = ~clk;

    Core core(
        .i_clk(clk),
        .i_rst_n(rst),
        .i_next(i_next),
        .i_data(data),
        .o_next(o_next),
        .o_finished(o_finished),
        .o_letter(o_letter),
        .o_word(o_word),
        .o_length(o_length)
    );

    initial begin
        $fsdbDumpfile("core.fsdb");
        $fsdbDumpvars;
        fp = $fopen("./shit.bin", "rb");
        rst <= 0;
        #(2 * CLK);
        rst <= 1;
        @(posedge clk) rst <= 0;
        $display("===============sim start===============");
        for (int d = 0; d < 191; d++) begin
            for (int i = 0; i < 4; i++) begin
                for (int j = 0; j < 8; j++) begin
                    data[i*8+j] = data[(i+1)*8+j];
                end
            end
            for (int i = 0; i < 8; i++) begin
                $fread(data[32+i], fp);
            end
            // $display("%d: %d\t%d\t%d\t%d\t%d\t%d\t%d\t%d", d, $signed(data[32]), $signed(data[33]), $signed(data[34]), $signed(data[35]), $signed(data[36]), $signed(data[37]), $signed(data[38]), $signed(data[39]));
            if (d >= 4) begin
                @(posedge clk) i_next <= 1;
                @(posedge clk) i_next <= 0;
            end
            for (int i = 0; i < 500; i++) begin
                @(posedge clk);
                if (o_finished) begin
                    $display("===========finished===========");
                    for (int k = 0; k < o_length; k++) begin
                        $display("%c\t%b", o_word[(k*8)+7 -: 7] + 'h40, o_word[(k*8)+7 -: 7]);
                    end
                    $finish;
                end else if (o_next) begin
                    $display("%c", o_letter + 'h40);
                end
            end
        end
        $display("%c\t%d", o_letter + 'h40, o_letter);
        $finish;
    end
endmodule
