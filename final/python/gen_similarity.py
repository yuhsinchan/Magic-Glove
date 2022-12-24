character_length = 8
count_length = 4
count_dict_size = 500
config = {
    "in_fn": "unigram_freq.csv",
    "out_fn": "similarity.sv",
    "module_name": "similarity",
    "inputs": {
        "i_similarity_clk": {},
        "i_similarity_rst_n": {},
        "i_similarity_start": {},
        "i_similarity_word": {"bits": character_length * 15}
    },
    "outputs": {
        "o_similarity_finish": {},
        "o_similarity_word": {"size": 500},
    },
    "bits": character_length * 15,
    "c_bits": count_length * 26, 
    "similarity_num": 20
}


def number2byte(fp, num):
    global count_length
    buffer = []
    for i in range(count_length):
        buffer.append(num % 2)
        num = num // 2
    buffer.reverse()
    for i in range(count_length):
        fp.write(f"{buffer[i]}")

def character2byte(fp, c):
    global character_length
    num = ord(c) - ord('a') + 2
    buffer = []
    for i in range(character_length):
        buffer.append(num % 2)
        num = num // 2
    buffer.reverse()
    for i in range(character_length):
        fp.write(f"{buffer[i]}")



if __name__ == "__main__":

    with open(config["out_fn"], "w") as out_fp:
        out_fp.write(f"module {config['module_name']}(\n")

        # configure inputs and outputs

        for port, setting in config["inputs"].items():
            out_fp.write("\tinput ")
            if setting.get("bits"):
                out_fp.write(f"[{setting['bits'] - 1}:0] ")
            out_fp.write(f"{port},\n")
            

        for port, setting in config["outputs"].items():
            out_fp.write("\toutput ")
            if setting.get("bits"):
                out_fp.write(f"[{setting['bits'] - 1}:0] ")
            out_fp.write(f"{port}")
            if setting.get("size"):
                out_fp.write(f"[0:{setting['size'] - 1}],\n")
            else:
                out_fp.write(f",\n")

        out_fp.write(");\n")
        out_fp.write("\n")

        # initialize dictionary and alphabet
        out_fp.write(f"\tparameter COUNT_DICT_SIZE = {count_dict_size};\n")
        out_fp.write(f"\tlocalparam bit [{config['c_bits'] - 1}:0] count_dict[0:COUNT_DICT_SIZE - 1] = ")
        out_fp.write("'{\n")
        with open(config["in_fn"], "r") as in_fp:
            lines = in_fp.readlines()
            for i, line in enumerate(lines):
                if i < 500:
                    line = (line.split(",")[0])[::-1] # reverse order
                    length = len(line.split(",")[0]) 
                    # out_fp.write(f"\t\t\t\tcount_dict[{'{:>3}'.format(i)}] = {config['bits']}'b")
                    out_fp.write(f"\t\t120'b")
                    
                    character_count = [0] * 26
                    for j, character in enumerate(line):
                        character_count[ord(character) - ord('a')] += 1
                    character_count.reverse()
                    
                    for count in character_count:
                        number2byte(out_fp, count)

                    out_fp.write(",\n")
                else:
                    continue
        
        out_fp.write("\t}\n")
        out_fp.write("\t\n")
        
        out_fp.write(f"\tlocalparam bit [{character_length - 1}:0] alphabet [0:25] = ")
        out_fp.write("'{\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "a"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "b"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "c"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "d"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "e"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "f"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "g"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "h"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "i"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "j"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "k"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "l"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "m"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "n"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "o"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "p"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "q"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "r"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "s"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "t"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "u"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "v"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "w"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "x"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "y"); out_fp.write(",\n")
        out_fp.write(f"\t\t8'b");character2byte(out_fp, "z"); out_fp.write(",\n")
        out_fp.write("\t}\n")
        out_fp.write(f"\t\n")
        
        # localparameter
        out_fp.write(f"\t// local parameters\n")
        out_fp.write(f"\tlocalparam S_IDLE = 0;\n")
        out_fp.write(f"\tlocalparam S_CALC = 1;\n")
        out_fp.write(f"\tlocalparam S_DONE = 2;\n")
        out_fp.write(f"\t\n")

        # logic
        out_fp.write(f"\t// logics\n")
        out_fp.write(f"\tlogic [1:0] state_r, state_w;\n")
        out_fp.write(f"\tlogic finish_r, finish_w;\n")
        out_fp.write(f"\tlogic [{config['c_bits'] - 1}:0] word_count_r, word_count_w;\n")
        out_fp.write(f"\tlogic [{config['bits'] - 1}:0] word_r, word_w;\n")
        # out_fp.write(f"\tlogic [{config['bits'] - 1}:0] value_r, value_w;\n")
        
        ## similarity words and values
        out_fp.write(f"\tlogic similarity_word_w        [0:COUNT_DICT_SIZE - 1]\n")
        out_fp.write(f"\tlogic similarity_word_r        [0:COUNT_DICT_SIZE - 1]\n")
        out_fp.write(f"\tlogic [4:0] similarity_value_w [0:COUNT_DICT_SIZE - 1]\n")
        out_fp.write(f"\tlogic [4:0] similarity_value_r [0:COUNT_DICT_SIZE - 1]\n")
        out_fp.write(f"\tlogic [4:0] max_similarity_value_r, max_similarity_value_w;\n")
        out_fp.write(f"\t\n")

        out_fp.write(f"\tinterger i;\n")
        out_fp.write(f"\t\n")

        # assign
        out_fp.write(f"\t// assign values\n")
        out_fp.write(f"\tassign o_similarity_finished = finish_r;\n")
        out_fp.write(f"\tinitial begin\n")
        out_fp.write(f"\t\tfor (i = 0; i < COUNT_DICT_SIZE; i = i + 1) begin\n")
        out_fp.write(f"\t\t\tassign o_similarity_word[i] = similarity_word_r[i];\n")
        out_fp.write(f"\t\tend\n")
        out_fp.write(f"\tend\n")
        out_fp.write(f"\t\n")
        
        # always_comb
        out_fp.write("\talways_comb begin\n")

        # initialize
        out_fp.write(f"\t\tstate_w = state_r;\n")
        out_fp.write(f"\t\tfinish_w = finish_r;\n")
        out_fp.write(f"\t\tword_count_w = word_count_r;\n")
        out_fp.write(f"\t\tword_w = word_r;\n")
        out_fp.write(f"\t\tmax_similarity_value_w = max_similarity_value_r;\n")
        out_fp.write(f"\t\t\n")

        out_fp.write(f"\t\tinitial begin\n")
        out_fp.write(f"\t\t\tfor (i = 0; i < COUNT_DICT_SIZE; i = i + 1) begin\n")
        out_fp.write(f"\t\t\t\tsimilarity_word_w[i] = similarity_word_r[i];\n")
        out_fp.write(f"\t\t\t\tsimilarity_value_w[i] = similarity_value_r[i];\n")
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

        # for loop 1
        # make i_word into word_count
        """
        interger ptr_word;
        interger charac;
        initial begin
            for (charac = 0; charac < 26; charac = charac + 1) begin
                initial begin
                    for (ptr_word = 0; ptr_word < 120; ptr_word = ptr_word + 8) begin
                        if (alphabet == i_word[ptr_word:ptr_word + 7]) begin
                            word_count_w = word_count_w + charac * 16
                        end
                    end
                end
            end
        end
        """

        # for loop 2
        # compare each word in the count_dict with word_count
        """
        interger wd;
        initial begin
            for (wd = 0; wd < COUNT_DICT_SIZE; wd = wd + 1) begin
                initial begin
                    for (ptr_word = 0; ptr_word < 120; ptr_word = ptr_word + 4) begin
                        // output the smaller value
                        if (count_dict[ptr_word:ptr_word + 3] >= word_count[ptr_word:ptr_word + 3]) begin
                            similarity_value_w[wd] = similarity_value_w[wd] + word_count[ptr_word:ptr_word + 3]
                        end else begin
                            similarity_value_w[wd] = similarity_value_w[wd] + count_dict[ptr_word:ptr_word + 3]
                        end
                    end
                    
                    if (similarity_value_w[wd] > max_similarity_value_w) begin
                        max_similarity_value_w = similarity_value_w[wd]
                    end

                end
            end
        end
        """

        # find the top 20 value
        """
        ptr_word = 0;
        initial begin
            for (i = max_similarity_value_w; i >= 0; i--) begin
                if (ptr_word >= 20) begin
                    break
                end
                initial begin
                    for (wd = 0; wd < COUNT_DICT_SIZE; wd = wd + 1) begin
                        if (ptr_word >= 20) begin
                            break
                        end
                        if (similarity_value_w[wd] == max_similarity_value_w) begin
                            similarity_word_w[ptr_word] = 0'b1
                            ptr_word = ptr_word + 1
                        end
                    end
                end
                max_similarity_value_w = max_similarity_value_w - 1
            end
        end
        
        """
        

        out_fp.write("\t\t\t\tstate_w = S_DONE;\n")
        out_fp.write("\t\t\t\tfinish_w = 1'b1;\n")
        # end
        out_fp.write("\t\t\tend\n")
        # =================================================================
        out_fp.write("\t\t\tS_DONE: begin\n")
        # state S_DONE
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
        out_fp.write("\talways_ff @ (posedge i_clk or negedge i_rst_n) begin\n")

        out_fp.write("\t\tif (!i_rst_n) begin\n")
        ## inside rst
        out_fp.write("\t\t\tfinish_r <= 0;\n")
        out_fp.write("\t\t\tstate_r <= S_IDLE;\n")
        out_fp.write("\t\t\tword_count_r <= 104'b0;\n")
        out_fp.write("\t\t\tword_r <= 120'b0\n")
        out_fp.write("\t\t\tmax_similarity_value_r <= 4'b0;\n")

        out_fp.write(f"\t\t\tinitial begin\n")
        out_fp.write(f"\t\t\t\tfor (i = 0; i < {count_dict_size}; i = i + 1) begin\n")
        out_fp.write(f"\t\t\t\t\tcount_dict[i] = 104'b0;\n")
        out_fp.write(f"\t\t\t\tend\n")
        out_fp.write(f"\t\t\tend\n")

        out_fp.write(f"\t\t\tinitial begin\n")
        out_fp.write(f"\t\t\t\tfor (i = 0; i < 26; i = i + 1) begin\n")
        out_fp.write(f"\t\t\t\t\talphabet[i] = 8'b0;\n")
        out_fp.write(f"\t\t\t\tend\n")
        out_fp.write(f"\t\t\tend\n")

        out_fp.write(f"\t\t\tinitial begin\n")
        out_fp.write(f"\t\t\t\tfor (i = 0; i < COUNT_DICT_SIZE; i = i + 1) begin\n")
        out_fp.write(f"\t\t\t\t\tsimilarity_value_r[i] = 1'b0;\n")
        out_fp.write(f"\t\t\t\t\tsimilarity_value_r[i] = 120'b0;\n")
        out_fp.write(f"\t\t\t\tend\n")
        out_fp.write(f"\t\t\tend\n")

        out_fp.write("\t\tend else begin\n")
        ## inside rst else =============================================================
        out_fp.write("\t\t\tfinish_r <= finish_w;\n")
        out_fp.write("\t\t\tstate_r <= state_w;\n")
        out_fp.write("\t\t\tword_count_r <= word_count_w;\n")
        out_fp.write("\t\t\tword_r <= word_w;\n")
        out_fp.write("\t\t\tmax_similarity_value_r <= max_similarity_value_w;\n")

        out_fp.write(f"\t\t\tinitial begin\n")
        out_fp.write(f"\t\t\t\tfor (i = 0; i < COUNT_DICT_SIZE; i = i + 1) begin\n")
        out_fp.write(f"\t\t\t\t\tsimilarity_word_r[i] = similarity_word_w[i];\n")
        out_fp.write(f"\t\t\t\t\tsimilarity_value_r[i] = similarity_value_w[i];\n")
        out_fp.write(f"\t\t\t\tend\n")
        out_fp.write(f"\t\t\tend\n")

        out_fp.write("\t\tend\n")
        out_fp.write("\tend\n")
        # end_ff

        out_fp.write("endmodule\n")

        
            
