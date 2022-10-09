module SevenHexDecoder (
	input        [6:0] i_hex,
	output logic [6:0] o_seven_ten,
	output logic [6:0] o_seven_one
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
parameter D0 = 7'b1000000;
parameter D1 = 7'b1111001;
parameter D2 = 7'b0100100;
parameter D3 = 7'b0110000;
parameter D4 = 7'b0011001;
parameter D5 = 7'b0010010;
parameter D6 = 7'b0000010;
parameter D7 = 7'b1011000;
parameter D8 = 7'b0000000;
parameter D9 = 7'b0010000;
always_comb begin
	case(i_hex)
		7'h0: begin o_seven_ten = D0; o_seven_one = D0; end
		7'h1: begin o_seven_ten = D0; o_seven_one = D1; end
		7'h2: begin o_seven_ten = D0; o_seven_one = D2; end
		7'h3: begin o_seven_ten = D0; o_seven_one = D3; end
		7'h4: begin o_seven_ten = D0; o_seven_one = D4; end
		7'h5: begin o_seven_ten = D0; o_seven_one = D5; end
		7'h6: begin o_seven_ten = D0; o_seven_one = D6; end
		7'h7: begin o_seven_ten = D0; o_seven_one = D7; end
		7'h8: begin o_seven_ten = D0; o_seven_one = D8; end
		7'h9: begin o_seven_ten = D0; o_seven_one = D9; end
		7'ha: begin o_seven_ten = D1; o_seven_one = D0; end
		7'hb: begin o_seven_ten = D1; o_seven_one = D1; end
		7'hc: begin o_seven_ten = D1; o_seven_one = D2; end
		7'hd: begin o_seven_ten = D1; o_seven_one = D3; end
		7'he: begin o_seven_ten = D1; o_seven_one = D4; end
		7'hf: begin o_seven_ten = D1; o_seven_one = D5; end
		7'd16: begin o_seven_ten = D1; o_seven_one = D6; end
		7'd17: begin o_seven_ten = D1; o_seven_one = D7; end
		7'd18: begin o_seven_ten = D1; o_seven_one = D8; end
		7'd19: begin o_seven_ten = D1; o_seven_one = D9; end
		7'd20: begin o_seven_ten = D2; o_seven_one = D0; end
		7'd21: begin o_seven_ten = D2; o_seven_one = D1; end
		7'd22: begin o_seven_ten = D2; o_seven_one = D2; end
		7'd23: begin o_seven_ten = D2; o_seven_one = D3; end
		7'd24: begin o_seven_ten = D2; o_seven_one = D4; end
		7'd25: begin o_seven_ten = D2; o_seven_one = D5; end
		7'd26: begin o_seven_ten = D2; o_seven_one = D6; end
		7'd27: begin o_seven_ten = D2; o_seven_one = D7; end
		7'd28: begin o_seven_ten = D2; o_seven_one = D8; end
		7'd29: begin o_seven_ten = D2; o_seven_one = D9; end
		7'd30: begin o_seven_ten = D3; o_seven_one = D0; end
		7'd31: begin o_seven_ten = D3; o_seven_one = D1; end
		7'd32: begin o_seven_ten = D3; o_seven_one = D2; end
		7'd33: begin o_seven_ten = D3; o_seven_one = D3; end
		7'd34: begin o_seven_ten = D3; o_seven_one = D4; end
		7'd35: begin o_seven_ten = D3; o_seven_one = D5; end
		7'd36: begin o_seven_ten = D3; o_seven_one = D6; end
		7'd37: begin o_seven_ten = D3; o_seven_one = D7; end
		7'd38: begin o_seven_ten = D3; o_seven_one = D8; end
		7'd39: begin o_seven_ten = D3; o_seven_one = D9; end
		7'd40: begin o_seven_ten = D4; o_seven_one = D0; end
		7'd41: begin o_seven_ten = D4; o_seven_one = D1; end
		7'd42: begin o_seven_ten = D4; o_seven_one = D2; end
		7'd43: begin o_seven_ten = D4; o_seven_one = D3; end
		7'd44: begin o_seven_ten = D4; o_seven_one = D4; end
		7'd45: begin o_seven_ten = D4; o_seven_one = D5; end
		7'd46: begin o_seven_ten = D4; o_seven_one = D6; end
		7'd47: begin o_seven_ten = D4; o_seven_one = D7; end
		7'd48: begin o_seven_ten = D4; o_seven_one = D8; end
		7'd49: begin o_seven_ten = D4; o_seven_one = D9; end
		7'd50: begin o_seven_ten = D5; o_seven_one = D0; end
		7'd51: begin o_seven_ten = D5; o_seven_one = D1; end
		7'd52: begin o_seven_ten = D5; o_seven_one = D2; end
		7'd53: begin o_seven_ten = D5; o_seven_one = D3; end
		7'd54: begin o_seven_ten = D5; o_seven_one = D4; end
		7'd55: begin o_seven_ten = D5; o_seven_one = D5; end
		7'd56: begin o_seven_ten = D5; o_seven_one = D6; end
		7'd57: begin o_seven_ten = D5; o_seven_one = D7; end
		7'd58: begin o_seven_ten = D5; o_seven_one = D8; end
		7'd59: begin o_seven_ten = D5; o_seven_one = D9; end
		7'd60: begin o_seven_ten = D6; o_seven_one = D0; end
		7'd61: begin o_seven_ten = D6; o_seven_one = D1; end
		7'd62: begin o_seven_ten = D6; o_seven_one = D2; end
		7'd63: begin o_seven_ten = D6; o_seven_one = D3; end
		7'd64: begin o_seven_ten = D6; o_seven_one = D4; end
		7'd65: begin o_seven_ten = D6; o_seven_one = D5; end
		7'd66: begin o_seven_ten = D6; o_seven_one = D6; end
		7'd67: begin o_seven_ten = D6; o_seven_one = D7; end
		7'd68: begin o_seven_ten = D6; o_seven_one = D8; end
		7'd69: begin o_seven_ten = D6; o_seven_one = D9; end
		
		
		default begin
			o_seven_ten = D9; o_seven_one = D9;
		end
		
	endcase
end

endmodule
