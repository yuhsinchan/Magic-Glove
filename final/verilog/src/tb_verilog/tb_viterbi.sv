`timescale 1ns / 100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK / 2;
    localparam SF = 2.0 ** -8.0;

    localparam [32:0] logits [0:3][0:2] = '{
		'{
			32'h0001028f,
			32'h0000e625,
			32'h0000b7bc
		},
		'{
			32'h0000e2f8,
			32'h0000dea3,
			32'h0000c13d
		},
		'{
			32'h00010692,
			32'h0000bb12,
			32'h00009f57
		},
		'{
			32'h0000e121,
			32'h0000db33,
			32'h0000d99a
		} 
    };

    localparam [4:0] top_chars [0:3][0:2] = '{
        '{
            19,
            4,
            18
        },
        '{
            7,
            10,
            3
        },
        '{
            8,
            18,
            24
        },
        '{
            19,
            4,
            18
        }
    };

    logic clk, rst, i_next, o_next, finished, start;
    logic [4:0] tops[0:2];
    logic [31:0] probs[0:2];
    logic [119:0] seq;

    initial clk = 0;
    initial i_next = 0;
    always #HCLK clk = ~clk;

    Viterbi viterbi(
        .i_clk(clk),
        .i_rst_n(rst),
        .i_start(start),
        .i_next(i_next),
        .i_prob(probs),
        .i_char(tops),
        .o_seq(seq),
        .o_stepped(o_next)
    );

    initial begin
        $fsdbDumpfile("viterbi.fsdb");
        $fsdbDumpvars;
        rst <= 0;
        #(2 * CLK);
        rst <= 1;
        @(posedge clk) rst <= 0;
        @(posedge clk) start <= 0;

        for (int i = 0; i < 4; i++) begin
            $display("=========inputs============");
            for (int j = 0; j < 3; ++j) begin
                tops[j] = top_chars[i][j];
                probs[j] = logits[i][j];
            end
            $display("tops : %0c\t%0c\t%0c", tops[0] + 'h41, tops[1] + 'h41, tops[2] + 'h41);
            $display("probs: %f\t%f\t%f", $itor(probs[0] * SF), $itor(probs[1] * SF), $itor(probs[2] * SF));
            
            if (i == 0) begin
                @(posedge clk) start = 1'b1;
                @(posedge clk) start = 1'b0;    
            end
            else begin
                @(posedge clk) i_next = 1'b1;
                @(posedge clk) i_next = 1'b0;
            end
            for (int j = 0; j < 100; j++) begin
                @(posedge clk);
                if (o_next) begin
                    $display("next: %c", seq[7:0] + 'h40);
                end
            end
        end
        $finish;
    end

endmodule

