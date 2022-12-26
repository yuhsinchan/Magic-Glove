`timescale 1ns / 100ps
module DTW(
	input  i_DTW_clk,
	input  i_DTW_rst_n,
	input  i_DTW_start,
    input  [119:0] i_DTW_word,
	input  [119:0] i_DTW_candidate_word [0:19],
	output o_DTW_finish,
	output [119:0] o_DTW_word,
    output [2:0] o_state
);	
	localparam S_IDLE      = 3'd0;
    localparam S_LEN_CALC  = 3'd1;
    localparam S_PRE_CALC  = 3'd2;
	localparam S_CALC      = 3'd3;
    localparam S_POST_CALC = 3'd4;
    localparam S_DONE      = 3'd5;

    localparam WORD_LEN   = 4;   // bits
    localparam VALUE_LEN  = 5;   // bits
    localparam CHAR_NUM   = 15;  // number
	
	logic [2:0]   state_r, state_w;
	logic         finish_r, finish_w;
 	logic [119:0] word_r, word_w;
    logic [3:0]   word_length_r, word_length_w;

    logic [WORD_LEN - 1:0] candidate_word_length_w [0:19], candidate_word_length_r [0:19];

    logic [VALUE_LEN - 1:0] counter_r, counter_w;
    logic [VALUE_LEN - 1:0] total_length_r, total_length_w;

    wire                    DTW_valid_w    [0:CHAR_NUM - 1];
	wire  [VALUE_LEN - 1:0] DTW_table_w    [0:CHAR_NUM - 1];
    reg   [VALUE_LEN - 1:0] DTW_table_d_w  [0:CHAR_NUM - 1], DTW_table_d_r  [0:CHAR_NUM - 1];
	reg   [VALUE_LEN - 1:0] DTW_table_dd_w [0:CHAR_NUM - 1], DTW_table_dd_r [0:CHAR_NUM - 1];

    logic DTW_table_diff_w [0:CHAR_NUM - 1][0:CHAR_NUM - 1], DTW_table_diff_r [0:CHAR_NUM - 1][0:CHAR_NUM - 1];

    logic [VALUE_LEN + 10 - 1:0] DTW_value_w [0:19], DTW_value_r [0:19];
    logic [VALUE_LEN + 10 - 1:0] min_value_w, min_value_r;
    logic [VALUE_LEN - 1:0] wd_w, wd_r;

    integer i, j;
	
	assign o_DTW_finish = finish_r;
    assign o_DTW_word = word_r;
    assign o_state = state_r;

    genvar gv;
    generate
        for (gv = 0; gv < CHAR_NUM; gv = gv + 1) begin: PEs
            if (gv == 0) begin
                DTW_PE_single dtw(
                    .clk(i_DTW_clk),
                    .rst(i_DTW_rst_n),
                    .i_debug((gv == 1)),
                    .i_valid((state_r == S_CALC) && (counter_r < candidate_word_length_r[wd_r])),
                    .i_diff(DTW_table_diff_r[gv][counter_r - gv]),
                    .i_first_column((counter_r - gv == 0)),
                    .i_first_row(1'b0),
                    .i_top_score(5'b11111),
                    .i_diagonal_score(5'b11111),
                    .i_left_score(DTW_table_d_r[gv]),
                    .o_score(DTW_table_w[gv]),
                    .o_valid(DTW_valid_w[gv])
                );
            end else begin
                DTW_PE_single dtw(
                    .clk(i_DTW_clk),
                    .rst(i_DTW_rst_n),
                    .i_debug(1'b0),
                    .i_valid(DTW_valid_w[gv - 1]),
                    .i_diff(DTW_table_diff_r[gv][counter_r - gv]),
                    .i_first_column((counter_r - gv == 0)),
                    .i_first_row(1'b0),
                    .i_top_score(DTW_table_d_r[gv - 1]),
                    .i_diagonal_score(DTW_table_dd_r[gv - 1]),
                    .i_left_score(DTW_table_d_r[gv]), 
                    .o_score(DTW_table_w[gv]),
                    .o_valid(DTW_valid_w[gv])
                );
            end
        end 
    endgenerate

	always_comb begin
		state_w = state_r;
		finish_w = finish_r;
        word_w = word_r;
        word_length_w = word_length_r;
        candidate_word_length_w = candidate_word_length_r;
        counter_w = counter_r;
        total_length_w = total_length_r;
        DTW_table_d_w  = DTW_table_d_r;
	    DTW_table_dd_w = DTW_table_dd_r;
        DTW_table_diff_w = DTW_table_diff_r;
        DTW_value_w = DTW_value_r;
        min_value_w = min_value_r;
        wd_w = wd_r;
        

		case (state_r)
			S_IDLE: begin
                finish_w = 1'b0;
                counter_w = 0;
                wd_w = 0;
				if (i_DTW_start) begin
					state_w = S_LEN_CALC;
				end
			end
            S_LEN_CALC: begin
				// calculate word length
                for (i = 0; i < 120; i = i + 8) begin
                    if (i_DTW_word[i+7 -: 8] != 8'b0) begin
                        word_length_w = word_length_w + 1'b1;
                    end
                end

                for (i = 0; i < 20; i = i + 1) begin
                    for (j = 0; j < 120; j = j + 8) begin
                        if (i_DTW_candidate_word[i][j+7 -: 8] != 8'b0) begin
                            candidate_word_length_w[i] = candidate_word_length_w[i] + 1'b1;
                        end
                    end
                end
                state_w = S_PRE_CALC;
			end
            S_PRE_CALC: begin
                if (wd_r > 19) begin
                   state_w = S_DONE; 
                end else begin                                        
                    // reset diff_table
                    for (i = 0; i < CHAR_NUM; i = i + 1) begin
                        for (j = 0; j < CHAR_NUM; j = j + 1) begin
                            DTW_table_diff_w[i][j] = 1'b0;
                        end
                    end
                    // reset all value
                    for (i = 0; i < CHAR_NUM; i = i + 1) begin
                        DTW_table_d_w[i] = 5'b0;
                        DTW_table_dd_w[i] = 5'b0;
                    end
                    
                    

                    // calculate upper limit
                    total_length_w = candidate_word_length_r[wd_r] + word_length_r;
                    
                    // $display();
                    // $display("==========current word==========");
                    // $write("wd_r: ");
                    // $display(wd_r);
                    // $display("word_length: ");
                    // $display(word_length_r);
                    // $display("candidate_word_length: ");
                    // $display(candidate_word_length_r[wd_r]);
                    // $display("total_length: ");
                    // $display(total_length_w);

                    // calculate DTW_table_diff
                    for (i = 0; i < word_length_r; i = i + 1) begin
                        for (j = 0; j < candidate_word_length_r[wd_r]; j = j + 1) begin
                            if (i_DTW_word[i*8+7 -: 8] == i_DTW_candidate_word[wd_r][j*8+7 -: 8]) begin
                                DTW_table_diff_w[i][j] = 1'b0;
                            end else begin
                                DTW_table_diff_w[i][j] = 1'b1;
                            end
                        end
                    end
                    
                    // $display("diff table: ");
                    // for (i = 0; i < CHAR_NUM; i = i + 1) begin
                    //     for (j = 0; j < CHAR_NUM; j = j + 1) begin
                    //         $write(DTW_table_diff_w[i][j]);
                    //         $write(" ");
                    //     end
                    //     $display();
                    // end

                    state_w = S_CALC;
                end
            end
			S_CALC: begin                    
                counter_w = counter_r + 1;
                
                for (i = 0; i < CHAR_NUM; i = i + 1) begin
                    if (DTW_valid_w[i]) begin
                        DTW_table_d_w[i] = DTW_table_w[i];
                    end
                end

                for (i = 0; i < CHAR_NUM; i = i + 1) begin
                    if (DTW_valid_w[i]) begin
                        DTW_table_dd_w[i] = DTW_table_d_r[i];
                    end
                end

                if (counter_r == total_length_r - 1) begin
                    DTW_value_w[wd_r] = DTW_table_d_w[word_length_r - 1] * 1024 / candidate_word_length_r[wd_r];
                    state_w = S_POST_CALC;
                    counter_w = 0;
                end

			end
            S_POST_CALC: begin                
                if (DTW_value_r[wd_r] < min_value_r) begin
                    min_value_w = DTW_value_r[wd_r];
                    word_w = i_DTW_candidate_word[wd_r];
                end
                
                wd_w = wd_r + 1;
                state_w = S_PRE_CALC;
            end
            S_DONE: begin
                finish_w = 1'b1;
				state_w = S_IDLE;
			end
		endcase
	end

	always_ff @(posedge i_DTW_clk or posedge i_DTW_rst_n) begin
		if (i_DTW_rst_n) begin
            finish_r                <= 1'b0;
			state_r                 <= S_IDLE;
            word_r                  <= 119'b0;
            word_length_r           <= 4'b0;
            candidate_word_length_r <= '{20{4'b0}};
            counter_r               <= 5'b0;
            total_length_r          <= 4'b0;
            DTW_table_d_r           <= '{15{5'b0}};
            DTW_table_dd_r          <= '{15{5'b0}};
            DTW_table_diff_r        <= '{'{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}, '{15{1'b0}}};
            DTW_value_r             <= '{20{15'b0}};
            min_value_r             <= 15'b111111111111111;
            wd_r                    <= 5'b0;

        end else begin
			finish_r                <= finish_w;
			state_r                 <= state_w;
            word_r                  <= word_w;
            word_length_r           <= word_length_w;
            candidate_word_length_r <= candidate_word_length_w;
            counter_r               <= counter_w;
            total_length_r          <= total_length_w;
            DTW_table_d_r           <= DTW_table_d_w;
            DTW_table_dd_r          <= DTW_table_dd_w;
            DTW_table_diff_r        <= DTW_table_diff_w;
            DTW_value_r             <= DTW_value_w;
            min_value_r             <= min_value_w;
            wd_r                    <= wd_w;
		end
	end

endmodule

module DTW_PE_single(
    input         clk,
    input         rst,
    input         i_debug,
    input         i_valid,
    input         i_diff,
    input         i_first_column,
    input         i_first_row,
    input  [4:0]  i_top_score,
    input  [4:0]  i_diagonal_score,
    input  [4:0]  i_left_score, 

    output reg [4:0]  o_score,
    output reg        o_valid
);
    always_ff @(negedge clk or posedge rst) begin
        if (rst) begin
            o_score <= 4'b0;
            o_valid <= 1'b0;
        end else begin
            o_valid <= i_valid;
            if (i_valid) begin
                if (i_first_row && i_first_column) begin
                    o_score <= i_diff;
                    if (i_debug) begin
                        $write("first block: ");
                        $write(i_diff);
                        $display(" ");
                    end
                end else if (i_first_row) begin
                    o_score <= i_left_score + 4'b1;
                    if (i_debug) begin
                        $write("first row: ");
                        $write(i_left_score + 4'b1);
                        $display(" ");
                    end
                end else if (i_first_column) begin
                    o_score <= i_top_score + 4'b1;
                    if (i_debug) begin
                        $write("first column: ");
                        $write(i_top_score + 4'b1);
                        $display(" ");
                    end
                end else begin
                    if ((i_diagonal_score + {3'b0, i_diff} < i_top_score + 4'b1) && (i_diagonal_score + {3'b0, i_diff} < i_left_score + 4'b1)) begin
                        o_score <= i_diagonal_score + {3'b0, i_diff};
                        if (i_debug) begin
                            $write("diag: ");
                            $write(i_diagonal_score + {3'b0, i_diff});
                            $display(" ");
                        end
                    end else if ((i_top_score + 4'b1 < i_diagonal_score + {3'b0, i_diff}) && (i_top_score + 4'b1 < i_left_score + 4'b1)) begin
                        o_score <= i_top_score + 4'b1;
                        if (i_debug) begin
                            $write("top: ");
                            $write(i_top_score + 4'b1);
                            $display(" ");
                        end
                    end else begin
                        o_score <= i_left_score + 4'b1;
                        if (i_debug) begin
                            $write("left: ");
                            $write(i_left_score + 4'b1);
                            $display(" ");
                        end
                    end
                end
            end
        end
    end
endmodule
