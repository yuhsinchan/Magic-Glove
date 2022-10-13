module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);
parameter S_IDLE = 2'b00;
parameter S_PREP = 2'b01;
parameter S_MONT = 2'b10;
parameter S_CALC = 2'b11;

// states
logic [1:0] state, state_nxt;

// finish signal
logic finish, finish_nxt;
assign o_finished = finish;

// counter for module of products (needs 257 cycles)
logic [8:0] counter_prep, counter_prep_nxt;

// counter for one iteration of Montgomery
logic [7:0] counter_mont, counter_mont_nxt;

// counter for full Montgomery
logic [7:0] counter_calc, counter_calc_nxt;

// register for encrypted data y
logic [256:0] t, t_nxt;

// register for answer m
logic [255:0] m, m_nxt;
assign o_a_pow_d = m;

// register for m in two Montgomery
logic [256:0] m_mont_1, m_mont_1_nxt;
logic [256:0] m_mont_2, m_mont_2_nxt;
logic [257:0] sum1_1;
logic [257:0] sum1_2;
logic [257:0] sum1_3;
logic [257:0] sum2_1;
logic [257:0] sum2_2;
logic [257:0] sum2_3;
assign sum1_1 = m_mont_1 + t;
assign sum1_2 = m_mont_1 + t + i_n;
assign sum1_3 = m_mont_1 + i_n;
assign sum2_1 = m_mont_2 + t;
assign sum2_2 = m_mont_2 + t + i_n;
assign sum2_3 = m_mont_2 + i_n;

// select specific bits
logic d_selected;
logic m_selected;
logic t_selected;
MUX256 mux_d(.s(counter_calc), .data(i_d),      .selected(d_selected));
MUX256 mux_m(.s(counter_mont), .data(m[255:0]), .selected(m_selected));
MUX256 mux_t(.s(counter_mont), .data(t[255:0]), .selected(t_selected));

always_comb begin
	// combinational for state & counter
	case(state)
		S_IDLE:begin
			// unchanged register
			counter_prep_nxt = counter_prep;
			counter_mont_nxt = counter_mont;
			counter_calc_nxt = counter_calc;
			finish_nxt = 1'b0;
			//
			if (i_start) begin
				state_nxt = S_PREP;
			end
			else begin
				state_nxt = state;
			end
		end
		S_PREP:begin
			// unchanged register 
			counter_mont_nxt = counter_mont;
			counter_calc_nxt = counter_calc;
			finish_nxt = 1'b0;
			//
			if (counter_prep == 9'b100000000) begin
				state_nxt = S_MONT;
				counter_prep_nxt = 9'b0;
			end
			else begin
				state_nxt = state;
				counter_prep_nxt = counter_prep + 1;
			end
		end
		S_MONT:begin
			// unchanged register 
			counter_prep_nxt = counter_prep;
			counter_calc_nxt = counter_calc;
			finish_nxt = 1'b0;
			//
			if (counter_mont == 8'b11111111) begin
				state_nxt = S_CALC;
				counter_mont_nxt = 8'b0;
			end
			else begin
				state_nxt = state;
				counter_mont_nxt = counter_mont + 1;
			end
		end
		S_CALC:begin
			// unchanged register
			counter_prep_nxt = counter_prep;
			counter_mont_nxt = counter_mont;
			//
			if (counter_calc == 8'b11111111) begin
				state_nxt = S_IDLE;
				counter_calc_nxt = 8'b0;
				finish_nxt = 1'b1;
			end
			else begin
				state_nxt = S_MONT;
				counter_calc_nxt = counter_calc + 1;
				finish_nxt = 1'b0;
			end
		end
	endcase
	// combinational for calculation
	case(state)
		S_IDLE:begin
			m_mont_1_nxt = 257'b0;
			m_mont_2_nxt = 257'b0;
			m_nxt = m;
			if (i_start) begin
				t_nxt = {1'b0, i_a};
			end
			else begin
				t_nxt = t;
			end
		end
		// compute t * 2^256 mod N 
		S_PREP:begin
			m_mont_1_nxt = 257'b0;
			m_mont_2_nxt = 257'b0;
			// set m to 1
			m_nxt = 1;
			// compute 2*t mod N
			if (counter_prep == 9'b100000000) begin
				if (t >= i_n) begin
					t_nxt = (t - i_n);
				end
				else begin
					t_nxt = t;
				end
			end
			else begin
				if (t >= i_n) begin
					t_nxt = {(t - i_n), 1'b0};
				end
				else if ({t[256:0], 1'b0} >= {2'b00, i_n}) begin
					t_nxt = {t[256:0], 1'b0} - {2'b00, i_n};
				end
				else begin
					t_nxt = {t[255:0], 1'b0};
				end
			end
		end
		S_MONT:begin
			// unchanged register
			m_nxt = m;
			t_nxt = t;
			// update m in Montgomery 1
			if (m_selected == 1'b1) begin
				// if m+b is odd
				if (sum1_1[0] == 1) begin
					m_mont_1_nxt = sum1_2[257:1];
				end
				else begin
					m_mont_1_nxt = sum1_1[257:1];
				end
			end
			else begin
				// if m is odd
				if (m_mont_1[0] == 1) begin
					m_mont_1_nxt = sum1_3[257:1];
				end
				else begin
					m_mont_1_nxt = {1'b0, m_mont_1[256:1]};
				end
			end
			// update m in Montgomery 2
			if (t_selected == 1'b1) begin
				// if m+b is odd
				if (sum2_1[0] == 1) begin
					m_mont_2_nxt = sum2_2[257:1];
				end
				else begin
					m_mont_2_nxt = sum2_1[257:1];
				end
			end
			else begin
				// if m is odd
				if (m_mont_2[0] == 1) begin
					m_mont_2_nxt = sum2_3[257:1];
				end
				else begin
					m_mont_2_nxt = {1'b0, m_mont_2[256:1]};
				end
			end
		end
		S_CALC:begin
			// update m & t
			if (d_selected == 1'b1) begin
				m_nxt = (m_mont_1 >= i_n) ? (m_mont_1 - i_n) : m_mont_1[255:0];
			end
			else begin
				m_nxt = m;
			end
			t_nxt = (m_mont_2 >= i_n) ? (m_mont_2 - i_n) : m_mont_2;
			// set m in two Montgomery to 0
			m_mont_1_nxt = 257'b0;
			m_mont_2_nxt = 257'b0;
		end
	endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
	// reset
	if (i_rst) begin
		state <= S_IDLE;
		counter_prep <= 9'b0;
		counter_mont <= 8'b0;
		counter_calc <= 8'b0;
		m <= 256'b0;
		t <= 257'b0;
		m_mont_1 <= 257'b0;
		m_mont_2 <= 257'b0;
		finish <= 1'b0;
	end
	// clock edge
	else begin
		state <= state_nxt;
		counter_prep <= counter_prep_nxt;
		counter_mont <= counter_mont_nxt;
		counter_calc <= counter_calc_nxt;
		// main m & t
		m <= m_nxt;
		t <= t_nxt;
		// m in two Montgomery
		m_mont_1 <= m_mont_1_nxt;
		m_mont_2 <= m_mont_2_nxt;
		// finish signal
		finish <= finish_nxt;
	end
end
endmodule

module MUX256(input [7:0] s, input [255:0] data, output selected);
	assign selected = 
	(s == 8'b00000000) ? data[0] :
	(s == 8'b00000001) ? data[1] :
	(s == 8'b00000010) ? data[2] :
	(s == 8'b00000011) ? data[3] :
	(s == 8'b00000100) ? data[4] :
	(s == 8'b00000101) ? data[5] :
	(s == 8'b00000110) ? data[6] :
	(s == 8'b00000111) ? data[7] :
	(s == 8'b00001000) ? data[8] :
	(s == 8'b00001001) ? data[9] :
	(s == 8'b00001010) ? data[10] :
	(s == 8'b00001011) ? data[11] :
	(s == 8'b00001100) ? data[12] :
	(s == 8'b00001101) ? data[13] :
	(s == 8'b00001110) ? data[14] :
	(s == 8'b00001111) ? data[15] :
	(s == 8'b00010000) ? data[16] :
	(s == 8'b00010001) ? data[17] :
	(s == 8'b00010010) ? data[18] :
	(s == 8'b00010011) ? data[19] :
	(s == 8'b00010100) ? data[20] :
	(s == 8'b00010101) ? data[21] :
	(s == 8'b00010110) ? data[22] :
	(s == 8'b00010111) ? data[23] :
	(s == 8'b00011000) ? data[24] :
	(s == 8'b00011001) ? data[25] :
	(s == 8'b00011010) ? data[26] :
	(s == 8'b00011011) ? data[27] :
	(s == 8'b00011100) ? data[28] :
	(s == 8'b00011101) ? data[29] :
	(s == 8'b00011110) ? data[30] :
	(s == 8'b00011111) ? data[31] :
	(s == 8'b00100000) ? data[32] :
	(s == 8'b00100001) ? data[33] :
	(s == 8'b00100010) ? data[34] :
	(s == 8'b00100011) ? data[35] :
	(s == 8'b00100100) ? data[36] :
	(s == 8'b00100101) ? data[37] :
	(s == 8'b00100110) ? data[38] :
	(s == 8'b00100111) ? data[39] :
	(s == 8'b00101000) ? data[40] :
	(s == 8'b00101001) ? data[41] :
	(s == 8'b00101010) ? data[42] :
	(s == 8'b00101011) ? data[43] :
	(s == 8'b00101100) ? data[44] :
	(s == 8'b00101101) ? data[45] :
	(s == 8'b00101110) ? data[46] :
	(s == 8'b00101111) ? data[47] :
	(s == 8'b00110000) ? data[48] :
	(s == 8'b00110001) ? data[49] :
	(s == 8'b00110010) ? data[50] :
	(s == 8'b00110011) ? data[51] :
	(s == 8'b00110100) ? data[52] :
	(s == 8'b00110101) ? data[53] :
	(s == 8'b00110110) ? data[54] :
	(s == 8'b00110111) ? data[55] :
	(s == 8'b00111000) ? data[56] :
	(s == 8'b00111001) ? data[57] :
	(s == 8'b00111010) ? data[58] :
	(s == 8'b00111011) ? data[59] :
	(s == 8'b00111100) ? data[60] :
	(s == 8'b00111101) ? data[61] :
	(s == 8'b00111110) ? data[62] :
	(s == 8'b00111111) ? data[63] :
	(s == 8'b01000000) ? data[64] :
	(s == 8'b01000001) ? data[65] :
	(s == 8'b01000010) ? data[66] :
	(s == 8'b01000011) ? data[67] :
	(s == 8'b01000100) ? data[68] :
	(s == 8'b01000101) ? data[69] :
	(s == 8'b01000110) ? data[70] :
	(s == 8'b01000111) ? data[71] :
	(s == 8'b01001000) ? data[72] :
	(s == 8'b01001001) ? data[73] :
	(s == 8'b01001010) ? data[74] :
	(s == 8'b01001011) ? data[75] :
	(s == 8'b01001100) ? data[76] :
	(s == 8'b01001101) ? data[77] :
	(s == 8'b01001110) ? data[78] :
	(s == 8'b01001111) ? data[79] :
	(s == 8'b01010000) ? data[80] :
	(s == 8'b01010001) ? data[81] :
	(s == 8'b01010010) ? data[82] :
	(s == 8'b01010011) ? data[83] :
	(s == 8'b01010100) ? data[84] :
	(s == 8'b01010101) ? data[85] :
	(s == 8'b01010110) ? data[86] :
	(s == 8'b01010111) ? data[87] :
	(s == 8'b01011000) ? data[88] :
	(s == 8'b01011001) ? data[89] :
	(s == 8'b01011010) ? data[90] :
	(s == 8'b01011011) ? data[91] :
	(s == 8'b01011100) ? data[92] :
	(s == 8'b01011101) ? data[93] :
	(s == 8'b01011110) ? data[94] :
	(s == 8'b01011111) ? data[95] :
	(s == 8'b01100000) ? data[96] :
	(s == 8'b01100001) ? data[97] :
	(s == 8'b01100010) ? data[98] :
	(s == 8'b01100011) ? data[99] :
	(s == 8'b01100100) ? data[100] :
	(s == 8'b01100101) ? data[101] :
	(s == 8'b01100110) ? data[102] :
	(s == 8'b01100111) ? data[103] :
	(s == 8'b01101000) ? data[104] :
	(s == 8'b01101001) ? data[105] :
	(s == 8'b01101010) ? data[106] :
	(s == 8'b01101011) ? data[107] :
	(s == 8'b01101100) ? data[108] :
	(s == 8'b01101101) ? data[109] :
	(s == 8'b01101110) ? data[110] :
	(s == 8'b01101111) ? data[111] :
	(s == 8'b01110000) ? data[112] :
	(s == 8'b01110001) ? data[113] :
	(s == 8'b01110010) ? data[114] :
	(s == 8'b01110011) ? data[115] :
	(s == 8'b01110100) ? data[116] :
	(s == 8'b01110101) ? data[117] :
	(s == 8'b01110110) ? data[118] :
	(s == 8'b01110111) ? data[119] :
	(s == 8'b01111000) ? data[120] :
	(s == 8'b01111001) ? data[121] :
	(s == 8'b01111010) ? data[122] :
	(s == 8'b01111011) ? data[123] :
	(s == 8'b01111100) ? data[124] :
	(s == 8'b01111101) ? data[125] :
	(s == 8'b01111110) ? data[126] :
	(s == 8'b01111111) ? data[127] :
	(s == 8'b10000000) ? data[128] :
	(s == 8'b10000001) ? data[129] :
	(s == 8'b10000010) ? data[130] :
	(s == 8'b10000011) ? data[131] :
	(s == 8'b10000100) ? data[132] :
	(s == 8'b10000101) ? data[133] :
	(s == 8'b10000110) ? data[134] :
	(s == 8'b10000111) ? data[135] :
	(s == 8'b10001000) ? data[136] :
	(s == 8'b10001001) ? data[137] :
	(s == 8'b10001010) ? data[138] :
	(s == 8'b10001011) ? data[139] :
	(s == 8'b10001100) ? data[140] :
	(s == 8'b10001101) ? data[141] :
	(s == 8'b10001110) ? data[142] :
	(s == 8'b10001111) ? data[143] :
	(s == 8'b10010000) ? data[144] :
	(s == 8'b10010001) ? data[145] :
	(s == 8'b10010010) ? data[146] :
	(s == 8'b10010011) ? data[147] :
	(s == 8'b10010100) ? data[148] :
	(s == 8'b10010101) ? data[149] :
	(s == 8'b10010110) ? data[150] :
	(s == 8'b10010111) ? data[151] :
	(s == 8'b10011000) ? data[152] :
	(s == 8'b10011001) ? data[153] :
	(s == 8'b10011010) ? data[154] :
	(s == 8'b10011011) ? data[155] :
	(s == 8'b10011100) ? data[156] :
	(s == 8'b10011101) ? data[157] :
	(s == 8'b10011110) ? data[158] :
	(s == 8'b10011111) ? data[159] :
	(s == 8'b10100000) ? data[160] :
	(s == 8'b10100001) ? data[161] :
	(s == 8'b10100010) ? data[162] :
	(s == 8'b10100011) ? data[163] :
	(s == 8'b10100100) ? data[164] :
	(s == 8'b10100101) ? data[165] :
	(s == 8'b10100110) ? data[166] :
	(s == 8'b10100111) ? data[167] :
	(s == 8'b10101000) ? data[168] :
	(s == 8'b10101001) ? data[169] :
	(s == 8'b10101010) ? data[170] :
	(s == 8'b10101011) ? data[171] :
	(s == 8'b10101100) ? data[172] :
	(s == 8'b10101101) ? data[173] :
	(s == 8'b10101110) ? data[174] :
	(s == 8'b10101111) ? data[175] :
	(s == 8'b10110000) ? data[176] :
	(s == 8'b10110001) ? data[177] :
	(s == 8'b10110010) ? data[178] :
	(s == 8'b10110011) ? data[179] :
	(s == 8'b10110100) ? data[180] :
	(s == 8'b10110101) ? data[181] :
	(s == 8'b10110110) ? data[182] :
	(s == 8'b10110111) ? data[183] :
	(s == 8'b10111000) ? data[184] :
	(s == 8'b10111001) ? data[185] :
	(s == 8'b10111010) ? data[186] :
	(s == 8'b10111011) ? data[187] :
	(s == 8'b10111100) ? data[188] :
	(s == 8'b10111101) ? data[189] :
	(s == 8'b10111110) ? data[190] :
	(s == 8'b10111111) ? data[191] :
	(s == 8'b11000000) ? data[192] :
	(s == 8'b11000001) ? data[193] :
	(s == 8'b11000010) ? data[194] :
	(s == 8'b11000011) ? data[195] :
	(s == 8'b11000100) ? data[196] :
	(s == 8'b11000101) ? data[197] :
	(s == 8'b11000110) ? data[198] :
	(s == 8'b11000111) ? data[199] :
	(s == 8'b11001000) ? data[200] :
	(s == 8'b11001001) ? data[201] :
	(s == 8'b11001010) ? data[202] :
	(s == 8'b11001011) ? data[203] :
	(s == 8'b11001100) ? data[204] :
	(s == 8'b11001101) ? data[205] :
	(s == 8'b11001110) ? data[206] :
	(s == 8'b11001111) ? data[207] :
	(s == 8'b11010000) ? data[208] :
	(s == 8'b11010001) ? data[209] :
	(s == 8'b11010010) ? data[210] :
	(s == 8'b11010011) ? data[211] :
	(s == 8'b11010100) ? data[212] :
	(s == 8'b11010101) ? data[213] :
	(s == 8'b11010110) ? data[214] :
	(s == 8'b11010111) ? data[215] :
	(s == 8'b11011000) ? data[216] :
	(s == 8'b11011001) ? data[217] :
	(s == 8'b11011010) ? data[218] :
	(s == 8'b11011011) ? data[219] :
	(s == 8'b11011100) ? data[220] :
	(s == 8'b11011101) ? data[221] :
	(s == 8'b11011110) ? data[222] :
	(s == 8'b11011111) ? data[223] :
	(s == 8'b11100000) ? data[224] :
	(s == 8'b11100001) ? data[225] :
	(s == 8'b11100010) ? data[226] :
	(s == 8'b11100011) ? data[227] :
	(s == 8'b11100100) ? data[228] :
	(s == 8'b11100101) ? data[229] :
	(s == 8'b11100110) ? data[230] :
	(s == 8'b11100111) ? data[231] :
	(s == 8'b11101000) ? data[232] :
	(s == 8'b11101001) ? data[233] :
	(s == 8'b11101010) ? data[234] :
	(s == 8'b11101011) ? data[235] :
	(s == 8'b11101100) ? data[236] :
	(s == 8'b11101101) ? data[237] :
	(s == 8'b11101110) ? data[238] :
	(s == 8'b11101111) ? data[239] :
	(s == 8'b11110000) ? data[240] :
	(s == 8'b11110001) ? data[241] :
	(s == 8'b11110010) ? data[242] :
	(s == 8'b11110011) ? data[243] :
	(s == 8'b11110100) ? data[244] :
	(s == 8'b11110101) ? data[245] :
	(s == 8'b11110110) ? data[246] :
	(s == 8'b11110111) ? data[247] :
	(s == 8'b11111000) ? data[248] :
	(s == 8'b11111001) ? data[249] :
	(s == 8'b11111010) ? data[250] :
	(s == 8'b11111011) ? data[251] :
	(s == 8'b11111100) ? data[252] :
	(s == 8'b11111101) ? data[253] :
	(s == 8'b11111110) ? data[254] : data[255];
endmodule