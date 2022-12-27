module Viterbi (
    input i_clk,
    input i_rst_n,
    input i_start,
    input i_next,
    input signed [31:0] i_prob[0:2],
    input [4:0] i_char[0:2],
    output [4:0] o_char,
    output [119:0] o_seq,
    output o_stepped
);
    localparam S_IDLE = 2'd0;
    localparam S_CALC = 2'd1;
    localparam S_TOP = 2'd2;
    //localparam S_DONE = 2'd3;

    localparam bit [15:0] transition_prob[0:728] = '{
        16'h046b,
        16'h01f4,
        16'h02c9,
        16'h0194,
        16'h0139,
        16'h01f1,
        16'h00e9,
        16'h016d,
        16'h028e,
        16'h0066,
        16'h0048,
        16'h013f,
        16'h01f3,
        16'h012f,
        16'h026c,
        16'h0275,
        16'h0020,
        16'h018f,
        16'h0354,
        16'h04e0,
        16'h00ad,
        16'h007d,
        16'h01cd,
        16'h0012,
        16'h008b,
        16'h000e,
        16'h0000,
        16'h0004,
        16'h0069,
        16'h00df,
        16'h00a8,
        16'h0007,
        16'h0020,
        16'h0083,
        16'h000d,
        16'h0093,
        16'h0004,
        16'h002e,
        16'h01dd,
        16'h009f,
        16'h02fd,
        16'h0003,
        16'h0063,
        16'h0005,
        16'h0200,
        16'h012b,
        16'h0256,
        16'h0040,
        16'h0057,
        16'h0017,
        16'h000d,
        16'h0079,
        16'h000c,
        16'h0164,
        16'h0067,
        16'h0007,
        16'h0004,
        16'h0001,
        16'h00c3,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0042,
        16'h0009,
        16'h0000,
        16'h006a,
        16'h0006,
        16'h0002,
        16'h006c,
        16'h0001,
        16'h0000,
        16'h003a,
        16'h001c,
        16'h0004,
        16'h0056,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0045,
        16'h0000,
        16'h0031,
        16'h010b,
        16'h0001,
        16'h0027,
        16'h0007,
        16'h011c,
        16'h0001,
        16'h0001,
        16'h0104,
        16'h0070,
        16'h0000,
        16'h006b,
        16'h0058,
        16'h0002,
        16'h0002,
        16'h017a,
        16'h0002,
        16'h0001,
        16'h004b,
        16'h0019,
        16'h00d8,
        16'h0048,
        16'h0001,
        16'h0000,
        16'h0000,
        16'h001d,
        16'h0000,
        16'h0073,
        16'h007c,
        16'h0006,
        16'h0005,
        16'h0020,
        16'h0151,
        16'h0003,
        16'h000d,
        16'h0002,
        16'h00d7,
        16'h0002,
        16'h0000,
        16'h000e,
        16'h0009,
        16'h0005,
        16'h0064,
        16'h0002,
        16'h0000,
        16'h002a,
        16'h0042,
        16'h0003,
        16'h0045,
        16'h0016,
        16'h0006,
        16'h0000,
        16'h0013,
        16'h0000,
        16'h0367,
        16'h0135,
        16'h002d,
        16'h00dc,
        16'h018b,
        16'h00a9,
        16'h0035,
        16'h003f,
        16'h000a,
        16'h0032,
        16'h0001,
        16'h000c,
        16'h00ff,
        16'h00aa,
        16'h022d,
        16'h0023,
        16'h004d,
        16'h0016,
        16'h0362,
        16'h0287,
        16'h00cf,
        16'h0011,
        16'h0064,
        16'h0064,
        16'h0062,
        16'h0032,
        16'h0003,
        16'h0763,
        16'h0043,
        16'h0000,
        16'h0001,
        16'h0000,
        16'h005f,
        16'h003d,
        16'h0000,
        16'h0000,
        16'h008c,
        16'h0000,
        16'h0000,
        16'h001d,
        16'h0001,
        16'h0000,
        16'h00e4,
        16'h0000,
        16'h0000,
        16'h0065,
        16'h0003,
        16'h0024,
        16'h002a,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0004,
        16'h0000,
        16'h0135,
        16'h0053,
        16'h0002,
        16'h0001,
        16'h0002,
        16'h00d3,
        16'h0000,
        16'h000b,
        16'h0053,
        16'h004d,
        16'h0000,
        16'h0000,
        16'h001a,
        16'h0004,
        16'h0020,
        16'h0043,
        16'h0001,
        16'h0000,
        16'h0057,
        16'h001e,
        16'h0008,
        16'h002a,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h000f,
        16'h0000,
        16'h016f,
        16'h0116,
        16'h0002,
        16'h0001,
        16'h0002,
        16'h02ea,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h00f1,
        16'h0000,
        16'h0000,
        16'h0007,
        16'h0005,
        16'h0011,
        16'h00f2,
        16'h0003,
        16'h0000,
        16'h001f,
        16'h0007,
        16'h0036,
        16'h001b,
        16'h0000,
        16'h0003,
        16'h0000,
        16'h0012,
        16'h0000,
        16'h0105,
        16'h008e,
        16'h002a,
        16'h0157,
        16'h0082,
        16'h00c0,
        16'h004e,
        16'h0078,
        16'h0001,
        16'h0007,
        16'h0001,
        16'h0014,
        16'h00e3,
        16'h006f,
        16'h03f3,
        16'h0162,
        16'h003e,
        16'h0005,
        16'h007d,
        16'h019d,
        16'h01bc,
        16'h0007,
        16'h0074,
        16'h0001,
        16'h000a,
        16'h0000,
        16'h001b,
        16'h006f,
        16'h001e,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h001c,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0003,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0023,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h001e,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0007,
        16'h0011,
        16'h0003,
        16'h0000,
        16'h0000,
        16'h0069,
        16'h0001,
        16'h0001,
        16'h0001,
        16'h003c,
        16'h0000,
        16'h0001,
        16'h0007,
        16'h0002,
        16'h000f,
        16'h0008,
        16'h0001,
        16'h0000,
        16'h0003,
        16'h002a,
        16'h0002,
        16'h0003,
        16'h0000,
        16'h0001,
        16'h0000,
        16'h0005,
        16'h0000,
        16'h009e,
        16'h00f5,
        16'h0007,
        16'h0009,
        16'h0052,
        16'h018b,
        16'h000f,
        16'h0004,
        16'h0001,
        16'h0149,
        16'h0000,
        16'h0009,
        16'h0108,
        16'h000a,
        16'h0002,
        16'h00ca,
        16'h0013,
        16'h0000,
        16'h0004,
        16'h004e,
        16'h003b,
        16'h003f,
        16'h000b,
        16'h0003,
        16'h0000,
        16'h007b,
        16'h0000,
        16'h01ca,
        16'h0122,
        16'h0034,
        16'h0005,
        16'h0002,
        16'h017e,
        16'h0002,
        16'h0001,
        16'h0000,
        16'h008d,
        16'h0000,
        16'h0000,
        16'h0005,
        16'h0037,
        16'h0003,
        16'h009b,
        16'h0065,
        16'h0000,
        16'h0002,
        16'h0033,
        16'h0003,
        16'h0031,
        16'h0000,
        16'h0001,
        16'h0000,
        16'h001c,
        16'h0000,
        16'h00d1,
        16'h00b7,
        16'h0004,
        16'h009a,
        16'h01db,
        16'h015a,
        16'h002c,
        16'h01a0,
        16'h0005,
        16'h00a2,
        16'h0004,
        16'h0027,
        16'h0026,
        16'h000d,
        16'h002e,
        16'h00b5,
        16'h0003,
        16'h0001,
        16'h0004,
        16'h00d4,
        16'h01c6,
        16'h002f,
        16'h0016,
        16'h0003,
        16'h0000,
        16'h002d,
        16'h0002,
        16'h038f,
        16'h0028,
        16'h002e,
        16'h0054,
        16'h0062,
        16'h0010,
        16'h0126,
        16'h0040,
        16'h000b,
        16'h0023,
        16'h0007,
        16'h002d,
        16'h00ac,
        16'h0104,
        16'h02ee,
        16'h007b,
        16'h0080,
        16'h0000,
        16'h0272,
        16'h0081,
        16'h00c6,
        16'h0178,
        16'h0054,
        16'h008c,
        16'h000c,
        16'h0013,
        16'h0002,
        16'h01ab,
        16'h00b7,
        16'h0001,
        16'h0006,
        16'h0008,
        16'h00be,
        16'h0001,
        16'h0002,
        16'h0038,
        16'h0047,
        16'h0000,
        16'h0000,
        16'h007f,
        16'h0015,
        16'h0001,
        16'h00ae,
        16'h0045,
        16'h0000,
        16'h00e9,
        16'h0021,
        16'h002d,
        16'h0035,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h000e,
        16'h0000,
        16'h007f,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0001,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0040,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0008,
        16'h0141,
        16'h000d,
        16'h0051,
        16'h005e,
        16'h031f,
        16'h000f,
        16'h002b,
        16'h0004,
        16'h015d,
        16'h0000,
        16'h0036,
        16'h0026,
        16'h0051,
        16'h004e,
        16'h014a,
        16'h0013,
        16'h0000,
        16'h0031,
        16'h00c6,
        16'h00bb,
        16'h003c,
        16'h002f,
        16'h0007,
        16'h0000,
        16'h0074,
        16'h0001,
        16'h02cd,
        16'h006b,
        16'h0008,
        16'h0053,
        16'h0008,
        16'h01a3,
        16'h0006,
        16'h0002,
        16'h008b,
        16'h0103,
        16'h0000,
        16'h0019,
        16'h001a,
        16'h0018,
        16'h0007,
        16'h00a5,
        16'h0059,
        16'h0004,
        16'h0005,
        16'h00b9,
        16'h01fc,
        16'h0081,
        16'h0002,
        16'h0010,
        16'h0000,
        16'h001c,
        16'h0000,
        16'h0613,
        16'h010a,
        16'h0004,
        16'h0015,
        16'h0004,
        16'h0259,
        16'h0004,
        16'h0003,
        16'h038b,
        16'h023b,
        16'h0000,
        16'h0001,
        16'h0022,
        16'h0012,
        16'h0007,
        16'h01bd,
        16'h0005,
        16'h0000,
        16'h00bf,
        16'h00b6,
        16'h0047,
        16'h006b,
        16'h0004,
        16'h0020,
        16'h0001,
        16'h0067,
        16'h0002,
        16'h03c2,
        16'h0039,
        16'h0032,
        16'h004b,
        16'h002d,
        16'h0040,
        16'h0009,
        16'h0029,
        16'h0000,
        16'h0034,
        16'h0000,
        16'h0007,
        16'h0074,
        16'h0049,
        16'h00ad,
        16'h0006,
        16'h0044,
        16'h0000,
        16'h010a,
        16'h00e2,
        16'h00a4,
        16'h0000,
        16'h0002,
        16'h0000,
        16'h0004,
        16'h000c,
        16'h0002,
        16'h004c,
        16'h004b,
        16'h0000,
        16'h0001,
        16'h0006,
        16'h013a,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h00b0,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h001b,
        16'h0000,
        16'h0000,
        16'h0001,
        16'h0002,
        16'h0000,
        16'h0001,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0001,
        16'h0000,
        16'h0013,
        16'h0074,
        16'h0001,
        16'h0001,
        16'h0001,
        16'h0089,
        16'h0000,
        16'h0000,
        16'h0056,
        16'h0097,
        16'h0000,
        16'h0000,
        16'h0005,
        16'h0001,
        16'h0020,
        16'h0052,
        16'h0000,
        16'h0000,
        16'h000c,
        16'h002a,
        16'h0003,
        16'h0000,
        16'h0000,
        16'h0004,
        16'h0000,
        16'h0002,
        16'h0000,
        16'h007f,
        16'h000a,
        16'h0001,
        16'h000a,
        16'h0000,
        16'h000a,
        16'h0000,
        16'h0000,
        16'h0001,
        16'h000d,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0001,
        16'h0000,
        16'h0001,
        16'h0017,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0018,
        16'h0002,
        16'h0000,
        16'h0000,
        16'h0003,
        16'h0002,
        16'h0000,
        16'h0039,
        16'h000c,
        16'h0004,
        16'h0006,
        16'h0004,
        16'h002b,
        16'h0000,
        16'h0001,
        16'h0000,
        16'h000a,
        16'h0000,
        16'h0000,
        16'h000a,
        16'h000c,
        16'h0008,
        16'h006e,
        16'h000e,
        16'h0000,
        16'h000c,
        16'h0030,
        16'h0008,
        16'h0001,
        16'h0000,
        16'h0004,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0292,
        16'h000b,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0017,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h000a,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0007,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0002,
        16'h0000,
        16'h0000,
        16'h0000,
        16'h0001,
        16'h0003,
        16'h000c
    };
    
    logic [4:0] prev_char_r[0:2], prev_char_w[0:2];
    logic [1:0] state_r, state_w;
    logic signed [63:0] topN_prob0_r, topN_prob0_w, topN_prob1_r, topN_prob1_w, topN_prob2_r, topN_prob2_w;
    logic signed [63:0] tmp_prob0_r, tmp_prob0_w, tmp_prob1_r, tmp_prob1_w, tmp_prob2_r, tmp_prob2_w;
    logic signed [63:0] this_prob_r[0:2], this_prob_w[0:2];
    logic [119:0] tmp_seq_r[0:2], tmp_seq_w[0:2];
    logic [119:0] topN_seq0_r, topN_seq0_w, topN_seq1_r, topN_seq1_w, topN_seq2_r, topN_seq2_w;
    logic [119:0] top_seq_r, top_seq_w;
    logic [4:0] counter_r, counter_w;
    logic stepped_r, stepped_w, finish_r, finish_w;

    logic [4:0] o_char_r, o_char_w;
    logic signed [63:0] this_prob0, this_prob1, this_prob2;
        
    logic [15:0] this_trans_prob0, this_trans_prob1, this_trans_prob2;
        
    assign this_prob0 = i_prob[0];
    assign this_prob1 = i_prob[1];
    assign this_prob2 = i_prob[2];
        
    assign this_trans_prob0 = transition_prob[(prev_char_r[0] + 1) * 27 + i_char[counter_r]];
    assign this_trans_prob1 = transition_prob[(prev_char_r[1] + 1) * 27 + i_char[counter_r]];
    assign this_trans_prob2 = transition_prob[(prev_char_r[2] + 1) * 27 + i_char[counter_r]];

    assign o_seq = top_seq_r;

    assign o_stepped = stepped_r;
    assign o_char = o_char_r;

    always_comb begin
        state_w = state_r;
		  
        tmp_prob0_w = tmp_prob0_r;
        tmp_prob1_w = tmp_prob1_r;
        tmp_prob2_w = tmp_prob2_r;
        
        this_prob_w = this_prob_r;
        tmp_seq_w = tmp_seq_r;
        
        topN_prob0_w = topN_prob0_r;
        topN_prob1_w = topN_prob1_r;
        topN_prob2_w = topN_prob2_r;
    
        topN_seq0_w = topN_seq0_r;
        topN_seq1_w = topN_seq1_r;
        topN_seq2_w = topN_seq2_r;
    
        top_seq_w = top_seq_r;
        
        counter_w = counter_r;
        stepped_w = stepped_r;

        o_char_w = o_char_r;
        prev_char_w = prev_char_r;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_CALC;
                    topN_prob0_w = 64'b0;
                    topN_prob1_w = 64'b0;
                    topN_prob2_w = 64'b0;
                    topN_seq0_w = 120'b0;
                    topN_seq1_w = 120'b0;
                    topN_seq2_w = 120'b0;
                end
                if (i_next) begin
                    state_w = S_CALC;
                end
                counter_w = 0;
                stepped_w = 1'b0;
            end
            S_CALC: begin
                if (topN_seq0_r == 0) begin
                    topN_prob0_w = (i_prob[0] * transition_prob[i_char[0]]) >> 21;
                    topN_prob1_w = (i_prob[1] * transition_prob[i_char[1]]) >> 21;
                    topN_prob2_w = (i_prob[2] * transition_prob[i_char[2]]) >> 21;
                    topN_seq0_w = i_char[0] + 1;
                    topN_seq1_w = i_char[1] + 1;
                    topN_seq2_w = i_char[2] + 1;
                    state_w = S_TOP;
                    prev_char_w = i_char;
                end else begin
                    if (counter_r < 4) begin
                        if (counter_r < 3) begin
                            tmp_prob0_w = topN_prob0_r * i_prob[counter_r] * transition_prob[(prev_char_r[0] + 1) * 27 + i_char[counter_r]];
                            tmp_prob1_w = topN_prob1_r * i_prob[counter_r] * transition_prob[(prev_char_r[1] + 1) * 27 + i_char[counter_r]];
                            tmp_prob2_w = topN_prob2_r * i_prob[counter_r] * transition_prob[(prev_char_r[2] + 1) * 27 + i_char[counter_r]];
                        end
                        if (counter_r > 0) begin
                            if ((tmp_prob0_r >= tmp_prob1_r) && (tmp_prob0_r >= tmp_prob2_r)) begin
                                tmp_seq_w[counter_r-1]   = (topN_seq0_r << 8) + i_char[counter_r-1] + 1;
                                this_prob_w[counter_r-1] = tmp_prob0_r;
                            end else if ((tmp_prob1_r >= tmp_prob0_r) && (tmp_prob1_r >= tmp_prob2_r)) begin
                                tmp_seq_w[counter_r-1]   = (topN_seq1_r << 8) + i_char[counter_r-1] + 1;
                                this_prob_w[counter_r-1] = tmp_prob1_r;
                            end else begin
                                tmp_seq_w[counter_r-1]   = (topN_seq2_r << 8) + i_char[counter_r-1] + 1;
                                this_prob_w[counter_r-1] = tmp_prob2_r;
                            end
                        end
                        counter_w = counter_r + 1;
                    end else begin
                        topN_prob0_w = this_prob_r[0] >> 21;
                        topN_prob1_w = this_prob_r[1] >> 21;
                        topN_prob2_w = this_prob_r[2] >> 21;
                        topN_seq0_w = tmp_seq_r[0];
                        topN_seq1_w = tmp_seq_r[1];
                        topN_seq2_w = tmp_seq_r[2];
                        state_w = S_TOP;
                        prev_char_w = i_char;
                        counter_w = 0;
                    end
                end
            end
            S_TOP: begin
                if ((topN_prob0_r >= topN_prob1_r) && (topN_prob0_r >= topN_prob2_r)) begin
                    top_seq_w = topN_seq0_r;
                    o_char_w = i_char[0] + 1;
                end else if ((topN_prob1_r >= topN_prob0_r) && (topN_prob1_r >= topN_prob2_r)) begin
                    top_seq_w = topN_seq1_r;
                    o_char_w = i_char[1] + 1;
                end else begin
                    top_seq_w = topN_seq2_r;
                    o_char_w = i_char[2] + 1;
                end
                state_w = S_IDLE;
                stepped_w = 1'b1;
            end
        endcase
    end

    always_ff @ (posedge i_clk or posedge i_rst_n) begin
        if (i_rst_n) begin
            prev_char_r <= '{3{5'b0}};
            state_r <= S_IDLE;
            topN_prob0_r <= 32'b0;
            topN_prob1_r <= 32'b0;
            topN_prob2_r <= 32'b0;
            tmp_prob0_r <= 32'b0;
            tmp_prob1_r <= 32'b0;
            tmp_prob2_r <= 32'b0;
            this_prob_r <= '{3{32'b0}};
            tmp_seq_r <= '{3{32'b0}};
            topN_seq0_r <= 120'b0;
            topN_seq1_r <= 120'b0;
            topN_seq2_r <= 120'b0;
            top_seq_r <= 120'b0;
            counter_r <= 5'b0;
            stepped_r <= 1'b0;
            o_char_r <= 5'b0;
        end 
        else begin
            prev_char_r <= prev_char_w;
            state_r <= state_w;
            topN_prob0_r <= topN_prob0_w;
            topN_prob1_r <= topN_prob1_w;
            topN_prob2_r <= topN_prob2_w;
            tmp_prob0_r <= tmp_prob0_w;
            tmp_prob1_r <= tmp_prob1_w;
            tmp_prob2_r <= tmp_prob2_w;
            this_prob_r <= this_prob_w;
            tmp_seq_r <= tmp_seq_w;
            topN_seq0_r <= topN_seq0_w;
            topN_seq1_r <= topN_seq1_w;
            topN_seq2_r <= topN_seq2_w;
            top_seq_r <= top_seq_w;
            counter_r <= counter_w;
            stepped_r <= stepped_w;
            o_char_r <= o_char_w;
        end       
    end

endmodule
