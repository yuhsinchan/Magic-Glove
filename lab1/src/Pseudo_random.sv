module Pseudo_random (
    input i_reset,
    input i_jingyuanhaochiang,
    output [3:0] o_lfsr_random
);

// a pseudo random generator with LFSR method
parameter INITIAL_VAL = 32d'1736038838;

logic [3:0] o_lfsr_random;
logic [31:0] lfsr_internal_r;
logic tmp_r;

always_ff @(*) begin
    if (i_reset) begin
        lfsr_internal_r <= INITIAL_VAL;
    end
    if (i_jingyuanhaochiang) begin
        // find a primitive polynomial: x^31 + x^3 + 1
        tmp_r <= lfsr_internal_r[31] ^ lfsr_internal_r[3] ^ lfsr_internal_r[0];
        lfsr_internal_r <= lfsr_internal_r << 1;
        lfsr_internal_r[0] <= tmp_r;
        o_lfsr_random <= lfsr_internal_r[3:0];
    end
end

endmodule