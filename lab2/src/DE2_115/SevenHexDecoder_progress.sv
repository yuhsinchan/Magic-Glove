module SevenHexDecoder_progress (
	input              i_clk,
	input              i_rst_n,
	input              i_start,
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
// parameter C0 = 7'b0001001;
// parameter C1 = 7'b0111001;
// parameter C2 = 7'b0111111;


// ===== Output Buffers =====
logic o_mode_r, o_mode_w;
assign o_mode = o_mode_r;


// ===== Combinational Circuits =====
always_comb begin
	o_mode_w = o_mode_r;
	if (i_start) begin
        o_mode_w = 1'h1 - o_mode_r;
    end

	case(o_mode_r)
		1'h0: begin o_seven_a = DD; o_seven_b = D2;	o_seven_c = D5; o_seven_d = D6; end
		1'h1: begin o_seven_a = D1; o_seven_b = D0;	o_seven_c = D2; o_seven_d = D4; end	
		default begin o_seven_a = Dbar; o_seven_b = Dbar; o_seven_c = Dbar; o_seven_d = Dbar; end	
	endcase

end


// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
// reset
if (!i_rst_n) begin
	o_mode_r <= 1'h0;

end else begin
	o_mode_r <= o_mode_w;
end
end

endmodule
