config = {
    "fn": "conv.sv",
    "module_name": "Conv",
    "inputs": {
        "i_clk": {},
        "i_rst_n": {},
        "i_kernel": {"bits": 16, "int_bits": 8, "size": [8, 3]},
        "i_data": {"bits": 16, "int_bits": 8, "size": [8, 5]},
        "i_bias": {
            "bits": 16,
            "int_bits": 8,
        },
    },
    "outputs": {
        "o_weights": {"bits": 24, "int_bits": 16, "size": [3, 1]},
    },
}

i_kernel = config["inputs"]["i_kernel"]
i_data = config["inputs"]["i_data"]
o_weights = config["outputs"]["o_weights"]

with open(config["fn"], "w") as fp:
    fp.write(f"module {config['module_name']}(\n")

    # configure inputs and outputs

    for port, setting in config["inputs"].items():
        fp.write("\tinput ")

        if setting.get("bits"):
            fp.write(f"[{setting['bits']-1}:0] ")

        fp.write(f"{port}")

        if setting.get("size"):
            fp.write(f" [0:{setting['size'][0] * setting['size'][1]-1}],\n")
        else:
            fp.write(",\n")

    for port, setting in config["outputs"].items():
        fp.write("\toutput ")

        if setting.get("bits"):
            fp.write(f"[{setting['bits']-1}:0] ")

        fp.write(f"{port}")

        if setting.get("size"):
            fp.write(f" [0:{setting['size'][0] * setting['size'][1]-1}],\n")
        else:
            fp.write(",\n")

    fp.write(");\n")

    # define logics

    for i in range(o_weights["size"][0]):
        fp.write(
            f"\tlogic [{i_kernel['bits'] + i_data['bits'] - 1}:0] weighted_sum{i}_r, weighted_sum{i}_w;\n"
        )

    fp.write("\tlogic [1:0] counter_r, counter_w;\n")

    fp.write("\n")

    # define assigns

    for i in range(o_weights["size"][0]):
        fp.write(
            f"\tassign o_weights[{i}] = weighted_sum{i}_r[{i_kernel['bits'] + i_data['bits'] - 1}:{i_kernel['bits'] + i_data['bits'] - o_weights['bits']}];\n"
        )

    fp.write("\n")

    # always_comb

    fp.write("\talways_comb begin\n")

    for i in range(o_weights["size"][0]):
        fp.write(f"\t\tweighted_sum{i}_w = weighted_sum{i}_r;\n")

    fp.write("\t\tcounter_w = counter_r;\n")

    ## case
    fp.write("\t\tcase (counter_r)\n")

    for i in range(o_weights["size"][0]):
        fp.write(f"\t\t\t2'd{i}: begin\n")

        fp.write(f"\t\t\t\tweighted_sum{i}_w = ")

        kernel_size = i_kernel["size"][0] * i_kernel["size"][1]
        for j in range(kernel_size):
            fp.write(
                f"$signed(i_data[{i + int(j / o_weights['size'][0])*5 + (j % o_weights['size'][0])}])*$signed(i_kernel[{j}])"
            )
            if j < kernel_size - 1:
                fp.write(" + ")
            else:
                fp.write(" + $signed({i_bias, 8'b0});\n")

        if i < 2:
            fp.write("\t\t\t\tcounter_w = counter_r + 1;\n")
        else:
            fp.write("\t\t\t\tcounter_w = 0;\n")

        fp.write("\t\t\tend\n")

    fp.write("\t\tendcase\n")
    ### endcase

    fp.write("\tend\n")
    fp.write("\n")
    # end_comb

    # always_ff

    fp.write("\talways_ff @ (posedge i_clk or negedge i_rst_n) begin\n")

    ## rst
    fp.write("\t\tif (!i_rst_n) begin\n")
    for i in range(o_weights["size"][0]):
        fp.write(f"\t\t\tweighted_sum{i}_r <= 0;\n")
    fp.write("\t\t\tcounter_r <= 0;\n")
    fp.write("\t\tend\n")

    fp.write("\t\telse begin\n")
    for i in range(o_weights["size"][0]):
        fp.write(f"\t\t\tweighted_sum{i}_r <= weighted_sum{i}_w;\n")
    fp.write("\t\t\tcounter_r <= counter_w;\n")
    fp.write("\t\tend\n")

    fp.write("\tend\n")

    fp.write("endmodule\n")
