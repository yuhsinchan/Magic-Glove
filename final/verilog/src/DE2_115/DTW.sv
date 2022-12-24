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
	localparam S_IDLE     = 3'd0;
    localparam S_LEN_CALC = 3'd1;
    localparam S_PRE_CALC = 3'd2;
	localparam S_CALC     = 3'd3;
    localparam S_POST_CALC = 3'd4;
    localparam S_EVAL     = 3'd5;
	localparam S_DONE     = 3'd6;

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

    logic                   DTW_valid_w    [0:WORD_LEN - 1], DTW_valid_r    [0:WORD_LEN - 1];
	logic [VALUE_LEN - 1:0] DTW_table_w    [0:WORD_LEN - 1], DTW_table_r    [0:WORD_LEN - 1];
    logic [VALUE_LEN - 1:0] DTW_table_d_w  [0:WORD_LEN - 1], DTW_table_d_r  [0:WORD_LEN - 1];
	logic [VALUE_LEN - 1:0] DTW_table_dd_w [0:WORD_LEN - 1], DTW_table_dd_r [0:WORD_LEN - 1];

    logic DTW_table_diff_w [0:WORD_LEN - 1][0:WORD_LEN - 1], DTW_table_diff_r [0:WORD_LEN - 1][0:WORD_LEN - 1];

    logic [VALUE_LEN + 10 - 1:0] DTW_value_w [0:19], DTW_value_r [0:19];
    logic [VALUE_LEN + 10 - 1:0] min_value;

    integer i = 0, j = 0, wd = 0;
	
	assign o_DTW_finish = finish_r;
    assign o_DTW_word = word_r;
    assign o_state = state_r;

    genvar gv;
    generate
        for (gv = 0; gv < WORD_LEN; gv = gv + 1) begin: PEs
            if (gv == 0) begin
                DTW_PE_single dtw(
                    .clk(i_DTW_clk),
                    .rst(i_DTW_rst_n),
                    .i_valid((state_r == S_CALC) && (counter < word_length_r)),
                    .i_i(gv),
                    .i_j(counter - gv),
                    .i_top_score(5'b11111),
                    .i_diagonal_score(5'b11111),
                    .i_left_score(DTW_table_d_r[gv]),
                    .o_score(DTW_table_r[gv]),
                    .o_valid(DTW_valid_r[gv])
                );
            end else begin
                DTW_PE_single dtw(
                    .clk(i_DTW_clk),
                    .rst(i_DTW_rst_n),
                    .i_valid(DTW_valid_r[gv - 1]),
                    .i_i(gv),
                    .i_j(counter - gv),
                    .i_top_score(DTW_table_d_r[gv - 1]),
                    .i_diagonal_score(DTW_table_dd_r[gv - 1]),
                    .i_left_score(DTW_table_d_r[gv]), 
                    .o_score(DTW_table_r[gv]),
                    .o_valid(DTW_valid_r[gv])
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
        DTW_valid_w    = DTW_valid_r;
	    DTW_table_w    = DTW_table_r;
        DTW_table_d_w  = DTW_table_d_r;
	    DTW_table_dd_w = DTW_table_dd_r;
        DTW_table_diff_w = DTW_table_diff_r;
        DTW_value_w = DTW_value_r;
        min_value = 15'b111111111111111;
        

		case (state_r)
			S_IDLE: begin
                counter_w = 0;
                wd = 0;
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
                        if (i_DTW_word[j+7 -: 8] != 8'b0) begin
                            candidate_word_length_w[i] = candidate_word_length_w[i] + 1'b1;
                        end
                    end
                end
                state_w = S_PRE_CALC;
			end
            S_PRE_CALC: begin
                if (wd >= 20) begin
                   state_w = S_EVAL; 
                end else begin
                    // reset DTW table
                    for (i = 0; i < 15; i = i + 1) begin
                        for (j = 0; j < 15; j = j + 1) begin
                            DTW_table_w[i][j] = 5'b0;
                        end
                    end
                    // initialize first block
                    // DTW_table_w[0][0] = ((i_DTW_candidate_word[wd][7:0] == i_DTW_word[7:0]) ? 4'b0 : 4'b1);
                    
                    // calculate upper limit
                    total_length_w = candidate_word_length_r[wd] + word_length_r;

                    // calculate DTW_table_diff
                    for (i = 1; i < word_length_r; i = i + 1) begin
                        for (j = 1; j < candidate_word_length_r[wd]; j = j + 1) begin
                            if (i_DTW_word[i*8+7 -: 8] == i_DTW_candidate_word[wd][j*8+7 -: 8]) begin
                                DTW_table_diff_w[i][j] = 1'b1;
                            end else begin
                                DTW_table_diff_w[i][j] = 1'b0;
                            end
                        end
                    end

                    wd = wd + 1;

                    state_w = S_CALC
                end
            end
			S_CALC: begin
                // fill in DTW table
                counter_w = counter_r + 1
				if (counter_r == 20){
                    state_w = S_POST_CALC;
                    counter_w = 0;
                }

                // calculating highest value
                for (i = 0; i < WORD_LEN; i = i + 1) begin
                    if (counter >= i+1 && counter-i <= seq_A_length) begin
                        if (PE_score_buff_n[i] > row_highest_scores[i]) begin
                            // $display("higher, update");
                            row_highest_scores_n[i] = PE_score_buff_n[i];
                            row_highest_columns_n[i] = counter - i;
                        end
                    end
                end

                
                for (i = 0; i < WORD_LEN; i = i + 1) begin
                    if (DTW_valid_r[i]) begin
                        DTW_table_d_w[i] = DTW_table_r[i];
                    end
                end

                for (i = 0; i < WORD_LEN; i = i + 1) begin
                    if (DTW_valid_r[i]) begin
                        DTW_table_dd_w[i] = DTW_table_d_r[i];
                    end
                end

                if (counter == total_length_r) begin
                    for (i = 0; i < WORD_LEN; i = i + 1) begin
                        DTW_valid_w[i] = 0;
                    end
                    state_w = S_PRE_CALC;
                    counter_n = 0;
                end
			end
            S_POST_CALC: begin
                // save the last block value
                DTW_value_w[wd] = DTW_table_r[WORD_LEN - 1];
                if (DTW_table_r[WORD_LEN - 1] < min_value) begin
                    min_value = DTW_table_r[WORD_LEN - 1];
                    word_w = i_DTW_candidate_word[wd];
                end
                state_w = S_PRE_CALC;
            end
            S_EVAL: begin
                finish_w = 1'b1;
				state_w = S_DONE;
			end
			S_DONE: begin
				finish_w = 1'b0;
				state_w = S_IDLE;
			end
		endcase
	end

	always_ff @(posedge i_DTW_clk or negedge i_DTW_rst_n) begin
		if (!i_DTW_rst_n) begin
           
            finish_r                <= 1'b0;
			state_r                 <= S_IDLE;
            word_r                  <= 119'b0;
            word_length_r           <= 4'b0;
            candidate_word_length_r <= '{20{4'b0}};
            counter_r               <= 5'b0;
            total_length_wr         <= 4'b0;
            DTW_valid_r             <= '{15{1'b0}};
            DTW_table_r             <= '{15{5'b0}};
            DTW_table_d_r           <= '{15{5'b0}};
            DTW_table_dd_r          <= '{15{5'b0}};
            DTW_table_diff_r        <= '{15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}, 15{1'b0}};
            DTW_value_r             <= '{20{15'b0}};

        end else begin
			finish_r                <= finish_w;
			state_r                 <= state_w;
            word_r                  <= word_w;
            word_length_r           <= word_length_w;
            candidate_word_length_r <= candidate_word_length_w;
            counter_r               <= counter_w;
            total_length_wr         <= total_length_w;
            DTW_valid_r             <= DTW_valid_w;
            DTW_table_r             <= DTW_table_w;
            DTW_table_d_r           <= DTW_table_d_w;
            DTW_table_dd_r          <= DTW_table_dd_w;
            DTW_table_diff_r        <= DTW_table_diff_w;
            DTW_value_r             <= DTW_value_w;
		end
	end

endmodule

module DTW_PE_single(
    input        clk,
    input        rst,
    input        i_valid,
    input        i_i,
    input        i_j,
    input  [4:0] i_top_score,
    input  [4:0] i_diagonal_score,
    input  [4:0] i_left_score, 

    output [4:0] o_score,
    output       o_valid,
);
    always@(negedge clk or posedge rst) begin
        if (rst) begin
            o_score <= 4'b0;
            o_valid <= 1'b0;
        end else begin
            o_valid <= i_valid;
            if (i_valid) begin
                if (i == 0 and j == 0) begin
                    o_score <= ((i_DTW_candidate_word[wd][7:0] == i_DTW_word[7:0]) ? 4'b0 : 4'b1);
                end else if (j == 0) begin
                    o_score <= i_top_score + 4'b1;
                end else begin
                    if ((i_diagonal_score + {3'b0, DTW_table_diff_r[i_i][i_j]} < i_top_score + 4'b1) && (i_diagonal_score + {3'b0, DTW_table_diff_r[i_i][i_j]} < i_left_score + 4'b1)) begin
                        o_score <= i_diagonal_score + {3'b0, DTW_table_diff_r[i_i][i_j]};
                    end else if ((i_top_score + 4'b1 < i_diagonal_score + {3'b0, DTW_table_diff_r[i_i][i_j]}) && (i_top_score + 4'b1 < i_left_score + 4'b1)) begin
                        o_score <= i_top_score + 4'b1;
                    end else begin
                        o_score <= i_left_score + 4'b1;
                    end
                end
            end
        end
    end
endmodule
