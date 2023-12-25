config = {
    "fn": "fc.sv",
    "module_name": "FC",
    "inputs": {
        "i_clk": {},
        "i_rst_n": {},
        "i_weight": {"bits": 16, "int_bits": 8, "size": [30, 1]},
        "i_data": {"bits": 24, "int_bits": 16, "size": [30, 1]},
        "i_bias": {
            "bits": 16,
            "int_bits": 8,
        },
    },
    "outputs": {
        "o_output": {"bits": 32, "int_bits": 24},
    },
}

i_weight = config["inputs"]["i_weight"]
i_data = config["inputs"]["i_data"]
o_output = config["outputs"]["o_output"]

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

    fp.write(
        f"\tlogic [{i_weight['bits'] +  i_data['bits'] - 1}:0] weighted_sum_r, weighted_sum_w;\n"
    )
    fp.write("\n")

    # define assign

    fp.write(
        f"\tassign o_output = weighted_sum_r[{i_weight['bits'] + i_data['bits'] - 1}:{i_weight['bits'] + i_data['bits'] - o_output['bits']}];\n"
    )

    fp.write("\n")

    # always_comb

    fp.write("\talways_comb begin\n")

    # fp.write("\t\tweighted_sum_w = weighted_sum_r;\n")

    fp.write("\t\tweight_sum_w = ")
    for i in range(i_weight["size"][0]):
        fp.write(f"$signed(i_data[{i}])*$signed(i_weight[{i}])")

        if i < i_weight["size"][0] - 1:
            fp.write(" + ")
        else:
            fp.write(" + $signed({i_bias, 8'b0});\n")

    fp.write("\tend\n")

    fp.write("\n")

    # end_comb

    # always_ff
    fp.write("\talways_ff @ (posedge i_clk or negedge i_rst_n) begin\n")

    ## rst
    fp.write("\t\tif (!i_rst_n) begin\n")
    fp.write(f"\t\t\tweighted_sum_r <= 0;\n")
    fp.write("\t\tend\n")

    fp.write("\t\telse begin\n")
    fp.write(f"\t\t\tweighted_sum_r <= weighted_sum_w;\n")
    fp.write("\t\tend\n")

    fp.write("\tend\n")

    fp.write("endmodule\n")
