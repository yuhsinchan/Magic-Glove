module Pseudo_random (
    input i_reset,
    input i_jingyuanhaochiang,
    output [3:0] o_lfsr_random
);

// a pseudo random generator with LFSR method
parameter INITIAL_VAL = 32'd1736038838;

// output buffers
logic [3:0] o_lfsr_random_out_r, o_lfsr_random_out_w;
// internal LFSR methods
logic [31:0] lfsr_internal_r, lfsr_internal_w;
logic tmp_w;

assign o_lfsr_random = o_lfsr_random_out_r;

always_comb begin
    if (i_jingyuanhaochiang) begin
        // find a primitive polynomial: x^31 + x^3 + 1
        tmp_w = lfsr_internal_r[31] ^ lfsr_internal_r[3] ^ lfsr_internal_r[0];
        lfsr_internal_w = lfsr_internal_r << 1;
        lfsr_internal_w[0] = tmp_w;
    end
    o_lfsr_random_out_w = lfsr_internal_r[3:0];
end

always_ff @(negedge i_jingyuanhaochiang or negedge i_reset) begin
    if (i_reset) begin
        lfsr_internal_r <= INITIAL_VAL;
    end else begin
        lfsr_internal_r <= lfsr_internal_w;
        lfsr_internal_r[0] <= tmp_w;
    end
    o_lfsr_random_out_r <= o_lfsr_random_out_w;
end

endmodule