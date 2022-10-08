module PreviousValue (
	input        i_clk,
    input        i_rst_n,
    input        i_start,
    input  [3:0] i_random_out,
	output [3:0] o_prev_random_out,
	output [3:0] o_prev_prev_random_out
);

  // ===== Output Buffers =====
  logic [3:0] o_random_out_r, o_random_out_w;
  logic [3:0] o_prev_random_out_r, o_prev_random_out_w;
  logic [3:0] o_prev_prev_random_out_r, o_prev_prev_random_out_w;

  // ===== Output Assignments =====
  assign o_prev_prev_random_out = o_prev_prev_random_out_r;
  assign o_prev_random_out = o_prev_random_out_r;


  // ===== Combinational Circuits =====
  always_comb begin
    if (i_start) begin
        o_prev_prev_random_out_w = o_prev_random_out_r
        o_prev_random_out_w = o_random_out_r
        o_random_out_w = i_random_out
    end
  end

  // ===== Sequential Circuits =====
  always_ff @(posedge i_clk or negedge i_rst_n) begin
    // reset
    if (!i_rst_n) begin
      o_prev_prev_random_out_r <= 4'd0;
      o_prev_random_out_r <= 4'd0;
      o_random_out_r <= 4'd0;
    end else begin
      o_prev_prev_random_out_r <= o_prev_random_out_w;
      o_prev_random_out_r <= o_random_out_w;
      o_random_out_r <= i_random_out_w;
    end
  end

endmodule