module Rsa256Core (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [1023:0] i_a, // cipher text y
    input  [1023:0] i_d, // private key
    input  [1023:0] i_n,
    output [1023:0] o_a_pow_d, // plain text x
    output         o_finished
);
parameter BITS = {1'b1, 256'b0}; // 1024
parameter S_IDLE = 2'b00;
parameter S_PREP = 2'b01;
parameter S_MONT = 2'b10;
parameter S_CALC = 2'b11;

logic [1023:0] n_r, n_w;
logic [1023:0] t_r, t_w;
logic [1023:0] m_r, m_w;
logic [1:0] state_r, state_w;
logic [31:0] counter_r, counter_w;
logic prep_start_w, prep_start_r, prep_finish_r;
logic [1023:0] prep_result_r;
logic [1023:0] mont_m_result_r;
logic [1023:0] mont_t_result_r;
logic mont_t_start_w, mont_t_start_r;
logic mont_m_start_w, mont_m_start_r;
logic mont_t_finish_r;
logic mont_m_finish_r;
logic mont_m_out_w;
logic mont_t_out_w;
logic o_finished_w, o_finished_r;
logic [1023:0] enc_r, enc_w;
logic [15:0] bits_r;

assign o_finished = o_finished_r;
assign o_a_pow_d = m_r;

// operations for RSA256 decryption
// namely, the Montgomery algorithm
RsaPrep prep(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_n(n_w),
    .i_y(enc_w),
    .i_bits(bits_r),
    .i_start(prep_start_r),
    .o_prep(prep_result_r),
    .o_finished(prep_finish_r)
);

RsaMont mont1(
    // compute m = m * t * (2 ^ (-256)) mod N
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_n(n_w),
    .i_a(m_w),
    .i_b(t_w),
    .i_bits(bits_r),
    .i_start(mont_m_start_r),
    .o_mont(mont_m_result_r),
    .o_finished(mont_m_finish_r)
);

RsaMont mont2(
    // compute t = (t ^ 2) * (2 ^ (-256)) mod N
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_n(n_w),
    .i_a(t_w),
    .i_b(t_w),
    .i_bits(bits_r),
    .i_start(mont_t_start_r),
    .o_mont(mont_t_result_r),
    .o_finished(mont_t_finish_r)
);

always_comb begin
    n_w = n_r;
    m_w = m_r;
    t_w = t_r;
    counter_w = counter_r;
    o_finished_w = o_finished_r;
    enc_w = enc_r;
    state_w = state_r;
    prep_start_w = prep_start_r;
    mont_t_start_w = mont_t_start_r;
    mont_m_start_w = mont_m_start_r;
    case (state_r)
        S_IDLE: begin
            if (i_start) begin
                state_w = S_PREP;
                prep_start_w = 1;
            end
            else begin
                o_finished_w = 0;
                mont_t_start_w = 0;
                mont_m_start_w = 0;
            end
        end
        S_PREP: begin
            prep_start_w = 0;
            if (prep_finish_r) begin
                state_w = S_MONT;
                t_w = prep_result_r;
                mont_t_start_w = 1;
                mont_m_start_w = 1;
            end
        end
        S_MONT: begin
            // t finishes, m finishes if it starts
            mont_t_start_w = 0;
            mont_m_start_w = 0;
            if (mont_m_finish_r && mont_t_finish_r) begin
                if (i_d[counter_r]) begin
                    m_w = mont_m_result_r;
                end
                t_w = mont_t_result_r;
                state_w = S_CALC;
            end
        end
        S_CALC: begin
            if (counter_r == bits_r - 1) begin
                state_w = S_IDLE;
                o_finished_w = 1;
            end
            else begin
                counter_w = counter_r + 1;
                state_w = S_MONT;
                mont_t_start_w = 1;
                mont_m_start_w = 1;
            end
        end
    endcase
end

always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_finished_r <= 0;
        enc_r <= 0;
        state_r <= S_IDLE;
        prep_start_r <= 0;
        mont_m_start_r <= 0;
        mont_t_start_r <= 0;
        bits_r <= 1024;
    end
    else begin
        if (i_start) begin
            enc_r <= i_a;
            state_r <= S_PREP;
            m_r <= 1;
            n_r <= i_n;
            counter_r <= 0;
            o_finished_r <= 0;
            if (i_n < BITS) begin
                bits_r <= 256;
            end
            else begin
                bits_r <= 1024;
            end
        end
        else begin
            state_r <= state_w;
            m_r <= m_w;
            t_r <= t_w;
            n_r <= n_w;
            counter_r <= counter_w;
            o_finished_r <= o_finished_w;
            if (o_finished_w) begin
                state_r <= S_IDLE;
            end
        end
        prep_start_r <= prep_start_w;
        mont_m_start_r <= mont_m_start_w;
        mont_t_start_r <= mont_t_start_w;
    end
end
endmodule

module RsaPrep (
    // return y * pow(2, bits, N) mod N
    input i_clk,
    input i_rst,
    input [1023:0] i_n,
    input [1023:0] i_y,
    input [15:0] i_bits,
    input i_start,
    output [1023:0] o_prep,
    output o_finished
);

parameter S_IDLE = 1'b0;
parameter S_CALC = 1'b1;

logic [15:0] counter_r, counter_w;
logic o_finished_r, o_finished_w;
logic [1027:0] output_r, output_w;
logic state_r;

assign o_finished = o_finished_r;
assign o_prep = output_r[1023:0];

always_comb begin
    o_finished_w = o_finished_r;
    case (state_r)
        S_IDLE: begin
            output_w = output_r;
            o_finished_w = 0;
            counter_w = counter_r;
        end
        S_CALC: begin
            if (output_r >= i_n) begin
                output_w = output_r - i_n;
            end
            else begin
                output_w = output_r;
            end
            if (counter_r >= i_bits) begin
                o_finished_w = 1;
            end
            counter_w = counter_r + 1;
        end
    endcase
end
always_ff @(posedge i_clk) begin
    if (i_rst) begin
        counter_r <= 0;
        state_r <= S_IDLE;
        o_finished_r <= 0;
        output_r <= 0;
    end
    else if (i_start) begin
        counter_r <= 0;
        o_finished_r <= 0;
        output_r <= i_y;
        state_r <= S_CALC;
    end
    else begin
        counter_r <= counter_w;
        output_r <= output_w << 1;
        o_finished_r <= o_finished_w;
        if (o_finished_w) begin
            state_r <= S_IDLE;
            output_r <= output_w;
        end
    end
end
endmodule

module RsaMont (
    // return a * b * (2 ^ (-256)) mod N
    input i_clk,
    input i_rst,
    input [1023:0] i_n,
    input [1023:0] i_a,
    input [1023:0] i_b,
    input [15:0] i_bits,
    input i_start,
    output [1023:0] o_mont,
    output o_finished
);

parameter S_IDLE = 1'b0;
parameter S_CALC = 1'b1;
parameter BITS = 16'd1024;

logic [15:0] counter_r, counter_w;
logic [1027:0] output_r, output_w;
logic o_finished_r, o_finished_w;
logic state_r;

assign o_finished = o_finished_r;
assign o_mont = output_r[1023:0];

always_comb begin
    o_finished_w = o_finished_r;
    case (state_r)
        S_IDLE: begin
            output_w = output_r;
            o_finished_w = 0;
            counter_w = counter_r;
        end
        S_CALC: begin
            // $display("counter: %d", counter_r);
            output_w = output_r;
            if (i_a[counter_r]) begin
                output_w = output_w + i_b;
            end
            if (output_w[0]) begin
                output_w = output_w + i_n;
            end
            output_w = output_w >> 1;
            // $display("outpute: %64x", output_w);
            if (counter_r >= i_bits - 1) begin
                if (output_w >= i_n) begin
                    output_w = output_w - i_n;
                end
                o_finished_w = 1;
            end
            counter_w = counter_r + 1;
        end
    endcase
end

always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_finished_r <= 0;
        output_r <= 0;
    end
    else if (i_start) begin
        counter_r <= 0;
        o_finished_r <= 0;
        output_r <= 0;
        state_r <= S_CALC;
    end
    else begin
        counter_r <= counter_w;
        output_r <= output_w;
        o_finished_r <= o_finished_w;
        if (o_finished_w) begin
            state_r <= S_IDLE;
            output_r <= output_w;
        end
    end
end

endmodule