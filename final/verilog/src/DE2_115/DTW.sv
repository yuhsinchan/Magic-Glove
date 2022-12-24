module DTW(
	input  i_DTW_clk,
	input  i_DTW_rst_n,
	input  i_DTW_start,
    input  [119:0] i_DTW_word,
	input  [119:0] i_DTW_candidate_word [0:19],
	output o_DTW_finish,
	output [119:0] o_DTW_word,
);	
	localparam S_INIT     = 0;
	localparam S_IDLE     = 1;
    localparam S_PRECALC  = 2;
	localparam S_CALC     = 3;
    localparam S_PASTCALC = 4;
	localparam S_DONE     = 5;
	
	logic [2:0]   state_r, state_w;
	logic         finish_r, finish_w;
	logic [119:0] word_r, word_w;
    logic [3:0]   word_length_r, word_length_w;

    logic [3:0] candidate_word_length_w [0:19];
    logic [3:0] candidate_word_length_r [0:19];

	logic [4:0] DTW_table_w [0:14][0:14];
    logic [4:0] DTW_table_r [0:14][0:14];
    
    logic [4:0] DTW_value_w [0:19];
    logic [4:0] DTW_value_r [0:19];
    logic [4:0] max_value;

    integer i, j;
	
	assign o_DTW_finish = finish_r;
    assign o_DTW_word = word_r;

	always_comb begin
		state_w = state_r;
		finish_w = finish_r;


		initial begin
			for (i = 0; i < 15; i = i + 1) begin
				word_w[i] = word_r[i];
			end
		end


		case (state_r)
			S_INIT: begin
				initial begin
                    for (i = 0; i < 15; i = i + 1) begin
                        initial begin
                            for (j = 0; j < 15; j = j + 1) begin
                                DTW_table_w[i][j] = 5'b0;
                            end
                        end
                    end
                end
				state_w = S_IDLE;
			end
			S_IDLE: begin
				if (i_start) begin
					state_w = S_PRECALC;
				end
			end
            S_PRECALC: begin
				// calculate word length
                initial begin
                    for (i = 0; i < 120; i = i + 8) begin
                        if (i_DTW_word[i: i + 7] != 8'b0) begin
                            word_length_w = word_length_w + 1'b1;
                        end
                    end
                end

                initial begin
                    for (i = 0; i < 20; i = i + 1) begin
                        initial begin
                            for (j = 0; j < 120; j = j + 8) begin
                                if (i_DTW_word[j: j + 7] != 8'b0) begin
                                    candidate_word_length_w[i] = candidate_word_length_w[i] + 1'b1;
                                end
                            end
                        end
                    end
                end

                state_w = S_CALC;
			end
			S_CALC: begin
                // start DTW table with 20 words
                integer wd;
                initial begin
                    for (wd = 0; wd < 20; wd = wd + 1) begin
                        // reset DTW table
                        // logic [4:0] DTW_table_w [0:14][0:14];
                        initial begin
                            for (i = 0; i < 15; i = i + 1) begin
                                initial begin
                                    for (j = 0; j < 15; j = j + 1) begin
                                        DTW_table_w[i][j] = 5'b0;
                                    end
                                end
                            end
                        end
                        
                        (i_DTW_candidate_word[wd][0:7] == i_DTW_word[0:7]) ? DTW_table_w[0][0] = 4'b0 : DTW_table_w[0][0] = 4'd2
                        
                        // initialize row
                        initial begin
                            for (i = 1; i < 15; i = i + 1) begin
                                (i_DTW_word[i*8:i*8 + 7] == i_DTW_candidate_word[wd][0:7]) ? (DTW_table_w[i][0] = DTW_table_w[i][0] +  4'b0) : (DTW_table_w[i][0] = DTW_table_w[i - 1][0] +  4'd2)
                            end
                        end
                        // initialize column
                        initial begin
                            for (j = 1; j < 15; j = j + 1) begin
                                (i_DTW_word[0:7] == i_DTW_candidate_word[wd][j*8:j*8 + 7]) ? (DTW_table_w[0][j] = DTW_table_w[0][j] +  4'b0) : (DTW_table_w[0][j] = DTW_table_w[0][j - 1] +  4'd2)
                            end
                        end
                        

                        initial begin
                            for (i = 1; i < word_length_r; i = i + 1) begin
                                initial begin
                                    for (j = 1; j < candidate_word_length_r[wd]; j = j + 1) begin
                                        if (i_DTW_word[i*8:i*8 + 7] == i_DTW_candidate_word[wd][j*8:j*8 + 7]) begin
                                            // same
                                            if (DTW_table_w[i - 1][j] <= DTW_table_w[i][j - 1] && DTW_table_w[i - 1][j] <= DTW_table_w[i - 1][j - 1]) begin
                                                DTW_table_w[i][j] = DTW_table_w[i - 1][j];
                                            end else if (DTW_table_w[i][j - 1] <= DTW_table_w[i - 1][j] && DTW_table_w[i][j - 1] <= DTW_table_w[i - 1][j - 1]) begin
                                                DTW_table_w[i][j] = DTW_table_w[i][j - 1];
                                            end else begin
                                                DTW_table_w[i][j] = DTW_table_w[i - 1][j - 1];
                                            end
                                        end else begin
                                            if (DTW_table_w[i - 1][j] <= DTW_table_w[i][j - 1] && DTW_table_w[i - 1][j] + 4'b1 <= DTW_table_w[i - 1][j - 1]) begin
                                                DTW_table_w[i][j] = DTW_table_w[i - 1][j] + 4'd2;
                                            end else if (DTW_table_w[i][j - 1] <= DTW_table_w[i - 1][j] && DTW_table_w[i][j - 1] + 4'b1 <= DTW_table_w[i - 1][j - 1]) begin
                                                DTW_table_w[i][j] = DTW_table_w[i][j - 1] + 4'd2;
                                            end else begin
                                                DTW_table_w[i][j] = DTW_table_w[i - 1][j - 1] + 4'b1;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        DTW_value_w[wd] = DTW_table_w[word_length_r][candidate_word_length_r[wd]];
                    end
                end
                // output biggest value word

				state_w = S_POSTCALC;
			end
            S_POSTCALC: begin
                initial begin
                    for (i = 0; i < 20; i = i + 1) begin
                        if (DTW_value_r[i] >= max_value) begin
                            max_value = DTW_value_r[i];
                            word_w = candidate_word_length_r[i];
                        end
                        DTW_table_w[i] = 5'b0;
                    end
                end
                finish_w = 1'b1;
				state_w = S_IDLE;
			end
			S_DONE: begin
				finish_w = 1'b0;
				state_w = S_IDLE;
			end
		endcase
		
	end

	always_ff @ (posedge i_clk or negedge i_rst_n) begin
		if (!i_rst_n) begin
			finish_r <= 1'b0;
			state_r <= S_INIT;
	        word_r <= 119'b0;
            word_length_r <= 4'b0;
            candidate_word_length_r <= '{20{4'b0}};
            DTW_table_r <= '{15'{15{5'b0}}};
            DTW_value_r <= '{20{5'b0}};
            max_value <= 5'b0;
		end else begin
			finish_r <= finish_w;
			state_r <= state_w;
            word_r <= word_w;
            word_length_r <= word_length_w;
            candidate_word_length_r <= candidate_word_length_w;
            DTW_table_r <= DTW_table_w;
            DTW_value_r <= DTW_value_w;
		end
	end
endmodule
