config = {
    "in_fn": "unigram_freq.csv",
    "out_fn": "dictionary.sv",
    "module_name": "dictionary",
    "inputs": {
        "i_clk": {},
        "i_rst_n": {},
        "i_start": {},
        "i_word": {"bits": 8 * 15}
    },
    "outputs": {
        "o_finish": {},
        "o_word": {"bits": 8 * 15},
    },
    "dict_size": 500,
    "bits": 8 * 15, 
    "similarity_num": 20
}

def character2byte(fp, c):
    num = ord(c) - ord('a') + 2
    buffer = []
    for i in range(8):
        buffer.append(num % 2)
        num = num // 2
    buffer.reverse()
    for i in range(8):
        fp.write(f"{buffer[i]}")



if __name__ == "__main__":

    with open(config["out_fn"], "w") as out_fp:
        out_fp.write(f"module {config['module_name']}(\n")

        # configure inputs and outputs

        for port, setting in config["inputs"].items():
            out_fp.write("\tinput ")
            if setting.get("bits"):
                out_fp.write(f"[{config['bits'] - 1}:0] ")
            out_fp.write(f"{port},\n")
            

        for port, setting in config["outputs"].items():
            out_fp.write("\toutput ")
            if setting.get("bits"):
                out_fp.write(f"[{config['bits'] - 1}:0] ")
            out_fp.write(f"{port}\n")

        out_fp.write(");\n")

        # initialize dictionary
        out_fp.write(f"\tparameter DICT_SIZE = {config['dict_size']};\n")
        out_fp.write("\tlocalparam bit [119:0] dict [0:DICT_SIZE - 1] = '{\n")
        with open(config["in_fn"], "r") as in_fp:
            lines = in_fp.readlines()
            for i, line in enumerate(lines):
                if i < 500:
                    line = (line.split(",")[0])[::-1] # reverse order
                    # print(line)
                    length = len(line.split(",")[0]) 
                    out_fp.write("\t\t120'b")
                    # out_fp.write(f"\t\t\t\tdict[{'{:>3}'.format(i)}] = {config['bits']}'b")
                    for j in range(length * 8, config['bits']):
                        out_fp.write(f"0")

                    for j, character in enumerate(line):
                        character2byte(out_fp, character)
                    out_fp.write(",\n")
                else:
                    continue
        out_fp.write("\t}")
        out_fp.write(f"\t\n")
        out_fp.write(f"\t\n")
        
        # localparameter
        out_fp.write(f"\tlocalparam S_IDLE = 0;\n")
        out_fp.write(f"\tlocalparam S_CALC = 1;\n")
        out_fp.write(f"\tlocalparam S_DONE = 2;\n")
        out_fp.write(f"\t\n")

        # logic
        out_fp.write(f"\tlogic [1:0] state_r, state_w;\n")
        out_fp.write(f"\tlogic finish_r, finish_w;\n")
        
        out_fp.write(f"\tlogic similarity_start_r, similarity_start_w;\n")
        out_fp.write(f"\tlogic similarity_finish_r, similarity_finish_w, pre_similarity_finish;\n")
        
        out_fp.write(f"\tlogic DTW_start_r, DTW_start_w;\n")
        out_fp.write(f"\tlogic DTW_finish_r, DTW_finish_w;\n")
        ## similarity words and values
        out_fp.write(f"\tlogic similarity_word_w [0:{config['dict_size'] - 1}]\n")
        out_fp.write(f"\tlogic similarity_word_r [0:{config['dict_size'] - 1}]\n")
        ## DTW word and value
        out_fp.write(f"\tlogic [{config['bits'] - 1}:0] DTW_candidate_word_w [0:{config['similarity_num'] - 1}]\n")
        out_fp.write(f"\tlogic [{config['bits'] - 1}:0] DTW_candidate_word_r [0:{config['similarity_num'] - 1}]\n")
        out_fp.write(f"\tlogic [{config['bits'] - 1}:0] DTW_word_r, DTW_word_w;\n")
        out_fp.write(f"\t\n")

        # integer
        out_fp.write(f"\tinterger i;\n")

        # assign
        out_fp.write(f"\tassign o_finished = finish_r;\n")
        out_fp.write(f"\tassign o_word = DTW_word_r;\n")
        out_fp.write(f"\t\n")

        # submodules
        ## similarity
        out_fp.write(f"\tsimilarity sim1(\n")
        out_fp.write(f"\t\t.i_similarity_clk(i_clk),\n")
        out_fp.write(f"\t\t.i_similarity_rst_n(i_rst_n),\n")
        out_fp.write(f"\t\t.i_similarity_start(similarity_start_r),\n")
        out_fp.write(f"\t\t.i_similarity_word(i_word),\n")
        out_fp.write(f"\t\t.o_similarity_finish(similarity_finish_r),\n")
        out_fp.write(f"\t\t.o_similarity_word(similarity_word_r),\n")
        out_fp.write(f"\t);\n")
        out_fp.write(f"\t\n")
        ## DTW
        out_fp.write(f"\tDTW dtw1(\n")
        out_fp.write(f"\t\t.i_DTW_clk(i_clk),\n")
        out_fp.write(f"\t\t.i_DTW_rst_n(i_rst_n),\n")
        out_fp.write(f"\t\t.i_DTW_start(DTW_start_r),\n")
        out_fp.write(f"\t\t.i_DTW_word(i_word),\n")
        out_fp.write(f"\t\t.i_DTW_candidate_word(DTW_candidate_word_r),\n")
        out_fp.write(f"\t\t.o_DTW_finish(DTW_finish_r),\n")
        out_fp.write(f"\t\t.o_DTW_word(DTW_word_r),\n")
        out_fp.write(f"\t);\n")
        out_fp.write(f"\t\n")


        
        # always_comb
        out_fp.write("\talways_comb begin\n")

        # initialize
        out_fp.write(f"\t\tstate_w = state_r;\n")
        out_fp.write(f"\t\tfinish_w = finish_r;\n")

        out_fp.write(f"\t\tsimilarity_start_w = similarity_start_r;\n")
        out_fp.write(f"\t\tsimilarity_finish_w = similarity_finish_r;\n")
        
        out_fp.write(f"\t\tDTW_start_w = DTW_start_r;\n")
        out_fp.write(f"\t\tDTW_finish_w = DTW_finish_r;\n")
        out_fp.write(f"\t\tDTW_word_w = DTW_word_r;\n")
        out_fp.write(f"\t\t\n")
        
        out_fp.write(f"\t\tinitial begin\n")
        out_fp.write(f"\t\t\tfor (i = 0; i < {config['similarity_num']}; i = i + 1) begin\n")
        out_fp.write(f"\t\t\t\tDTW_candidate_word_w[i] = DTW_candidate_word_w[i];\n")
        out_fp.write(f"\t\t\tend\n")
        out_fp.write(f"\t\tend\n")
        out_fp.write(f"\t\t\n")

        out_fp.write(f"\t\tinitial begin\n")
        out_fp.write(f"\t\t\tfor (i = 0; i < {config['dict_size']}; i = i + 1) begin\n")
        out_fp.write(f"\t\t\t\tsimilarity_word_r[i] = similarity_word_w[i];\n")
        out_fp.write(f"\t\t\tend\n")
        out_fp.write(f"\t\tend\n")
        out_fp.write(f"\t\t\n")
        
        out_fp.write("\t\tcase (state_r)\n")
        # =================================================================
        out_fp.write("\t\t\tS_IDLE: begin\n")
        # state S_IDLE
        out_fp.write("\t\t\t\tif (i_start) begin\n")
        out_fp.write("\t\t\t\t\tstate_w = S_CALC\n")
        out_fp.write("\t\t\t\tend\n")
        # end
        out_fp.write("\t\t\tend\n")
        # =================================================================
        out_fp.write("\t\t\tS_CALC: begin\n")
        # state S_CALC
        # TODO: cal_SIM
        # TODO: cal_DTW

        out_fp.write("\t\t\t\tsimilarity_start_w = i_start;\n")
        # precalculate the words for DTW

        out_fp.write("\t\t\t\tif (similarity_finish_r) begin;\n")
        out_fp.write("\t\t\t\t\tinteger ptr = 0;\n")
        out_fp.write("\t\t\t\t\tinitial begin\n")
        out_fp.write("\t\t\t\t\t\tfor (i = 0; i < COUNT_DICT_SIZE; i = i + 1) begin\n")
        out_fp.write("\t\t\t\t\t\t\tif(similarity_word_r[i] == 0'b1) begin\n")
        out_fp.write("\t\t\t\t\t\t\t\tDTW_candidate_word_w[ptr] = dict[i];\n")
        out_fp.write("\t\t\t\t\t\t\tend\n")
        out_fp.write("\t\t\t\t\t\tend\n")
        out_fp.write("\t\t\t\t\tend\n")
        out_fp.write("\t\t\t\tend else if (pre_similarity_finish && !similarity_finish_r) begin\n")
        out_fp.write("\t\t\t\t\tDTW_start_w = 0'b1;\n")
        out_fp.write("\t\t\t\tend\n")

        # if (similarity_finish_r) begin
        #     integer ptr = 0;
        #     initial begin
        #         for (i = 0; i < COUNT_DICT_SIZE; i = i + 1) begin
        #             if(similarity_word_r[i] == 0'b1) begin
        #                 DTW_candidate_word_w[ptr] = dict[i];
        #                 ptr = ptr + 1;
        #             end
        #         end
        #     end
        # end else if (pre_similarity_finish && !similarity_finish_r) begin
        #     DTW_start_w = 0'b1;
        # end


        out_fp.write("\t\t\t\tfinish_w = DTW_finish_r;\n")
        out_fp.write("\t\t\t\t\n")

        out_fp.write("\t\t\t\tif (finish_r) begin\n")
        out_fp.write("\t\t\t\t\tstate_w = S_DONE\n")
        out_fp.write("\t\t\t\tend\n")
        
        # end
        out_fp.write("\t\t\tend\n")
        # =================================================================
        out_fp.write("\t\t\tS_DONE: begin\n")
        # state S_IDLE
        out_fp.write("\t\t\t\tfinish_w = 1'b0;\n")
        out_fp.write("\t\t\t\tstate_w = S_IDLE;\n")
        # end
        out_fp.write("\t\t\tend\n")
        # =================================================================
        out_fp.write("\t\tendcase\n")
        out_fp.write("\t\t\n")

        out_fp.write("\tend\n")
        out_fp.write("\n")
        # end_comb

        # always_ff
        out_fp.write(f"\talways_ff @ (posedge i_clk or negedge i_rst_n) begin\n")

        out_fp.write(f"\t\tif (!i_rst_n) begin\n")
        ## inside rst
        out_fp.write(f"\t\t\tstate_r <= S_IDLE;\n")
        out_fp.write(f"\t\t\tfinish_r <= 1'b0;\n")
        out_fp.write(f"\t\t\tsimilarity_start_r <= 1'b0;\n")
        out_fp.write(f"\t\t\tsimilarity_finish_r <= 1'b0;\n")
        out_fp.write(f"\t\t\tpre_similarity_finish <= 1'b0;\n")
        out_fp.write(f"\t\t\tDTW_start_r <= 1'b0;\n")
        out_fp.write(f"\t\t\tDTW_finish_r <= 1'b0;\n")
        out_fp.write(f"\t\t\tDTW_word_r <= 120'b0;\n")
        out_fp.write("\t\t\tDTW_candidate_word_r[i] = '{20{120'b0}};\n")
        out_fp.write("\t\t\tsimilarity_word_r <= '{500{1'b0}};\n")
        out_fp.write("\t\t\t\n")

        out_fp.write("\t\tend else begin\n")
        ## inside rst else
        out_fp.write("\t\t\tfinish_r <= finish_w;\n")
        out_fp.write("\t\t\tstate_r <= state_w;\n")
        out_fp.write("\t\t\tsimilarity_start_r <= similarity_start_w;\n")
        out_fp.write("\t\t\tsimilarity_finish_r <= similarity_finish_w;\n")
        out_fp.write("\t\t\tpre_similarity_finish <= similarity_finish_r;\n")
        
        out_fp.write("\t\t\tDTW_start_r <= DTW_start_w;\n")
        out_fp.write("\t\t\tDTW_finish_r <= DTW_finish_w;\n")
        out_fp.write("\t\t\tDTW_word_r <= DTW_word_w;\n")
        out_fp.write("\t\t\t\n")
        out_fp.write("\t\t\tDTW_candidate_word_r <= DTW_candidate_word_w;\n")
        out_fp.write("\t\t\tsimilarity_word_r <= similarity_word_w;\n")
        out_fp.write("\t\tend\n")
        out_fp.write("\tend\n")
        # end_ff

        out_fp.write("endmodule\n")

        
            
