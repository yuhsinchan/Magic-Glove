module SevenHexDecoder_progress (
	input              i_clk,
	input              i_rst_n,
	input              i_start,
	input        [3:0] i_progress,
	output logic [6:0] o_seven_a,
	output logic [6:0] o_seven_b,
	output logic [6:0] o_seven_c,
	output logic [6:0] o_seven_d,
	output             o_mode
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */

// numbers
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
parameter DD = 7'b1111111;
parameter Dbar = 7'b0111111;

// letters
parameter C0  = 7'b1110110;
parameter CU  = 7'b1110111;
parameter CD  = 7'b1111110;
parameter CL  = 7'b1000110;
parameter CLU = 7'b1000111;
parameter CLD = 7'b1001110;
parameter CR  = 7'b1110000;
parameter CRU = 7'b1110001;
parameter CRD = 7'b1111000;

// ===== Combinational Circuits =====
always_comb begin
	case(i_progress)
		4'h0: begin o_seven_a = CL;  o_seven_b = C0;	o_seven_c = C0; o_seven_d = CR; end
		4'h1: begin o_seven_a = CLU; o_seven_b = C0;	o_seven_c = C0; o_seven_d = CR; end
		4'h2: begin o_seven_a = CL;  o_seven_b = CU;	o_seven_c = C0; o_seven_d = CR; end
		4'h3: begin o_seven_a = CL;  o_seven_b = C0;	o_seven_c = CU; o_seven_d = CR; end
		4'h4: begin o_seven_a = CL;  o_seven_b = C0;	o_seven_c = C0; o_seven_d = CRU; end
		4'h5: begin o_seven_a = CL;  o_seven_b = C0;	o_seven_c = C0; o_seven_d = CRD; end
		4'h6: begin o_seven_a = CL;  o_seven_b = C0;	o_seven_c = CD; o_seven_d = CR; end
		4'h7: begin o_seven_a = CL;  o_seven_b = CD;	o_seven_c = C0; o_seven_d = CR; end
		4'h8: begin o_seven_a = CLD; o_seven_b = C0;	o_seven_c = C0; o_seven_d = CR; end
		default begin o_seven_a = Dbar; o_seven_b = Dbar; o_seven_c = Dbar; o_seven_d = Dbar; end	
	endcase
end

endmodule
