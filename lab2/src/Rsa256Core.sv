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
parameter BITS = 16'd256; // 256
parameter S_IDLE = 2'b00;
parameter S_PREP = 2'b01;
parameter S_MONT = 2'b10;
parameter S_CALC = 2'b11;

logic [255:0] n_r, n_w;
logic [255:0] t_r, t_w;
logic [255:0] m_r, m_w;
logic [1:0] state_r, state_w;
logic [31:0] counter_r, counter_w;
logic prep_start_w, prep_start_r, prep_finish_r;
logic [255:0] prep_result_r;
logic [255:0] mont_m_result_r;
logic [255:0] mont_t_result_r;
logic mont_t_start_w, mont_t_start_r;
logic mont_m_start_w, mont_m_start_r;
logic mont_t_finish_r;
logic mont_m_finish_r;
logic mont_m_out_w;
logic mont_t_out_w;
logic o_finished_w, o_finished_r;
logic [255:0] enc_r, enc_w;

assign o_finished = o_finished_r;
assign o_a_pow_d = m_r;

// operations for RSA256 decryption
// namely, the Montgomery algorithm
RsaPrep prep(
    .i_rst(i_rst),
    .i_n(n_w),
    .i_y(enc_w),
    .i_bits(BITS),
    .i_start(prep_start_w),
    .o_prep(prep_result_r),
    .o_finished(prep_finish_r)
);

RsaMont mont1(
    // compute m = m * t * (2 ^ (-256)) mod N
    .i_rst(i_rst),
    .i_n(n_w),
    .i_a(m_w),
    .i_b(t_w),
    .i_bits(BITS),
    .i_start(mont_m_start_w),
    .o_mont(mont_m_result_r),
    .o_finished(mont_m_finish_r)
);

RsaMont mont2(
    // compute t = (t ^ 2) * (2 ^ (-256)) mod N
    .i_rst(i_rst),
    .i_n(n_w),
    .i_a(t_w),
    .i_b(t_w),
    .i_bits(BITS),
    .i_start(mont_t_start_w),
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
            end
        end
        S_PREP: begin
            if (prep_finish_r && prep_start_r) begin
                state_w = S_MONT;
                t_w = prep_result_r;
                prep_start_w = 0;
                $display("t: %64x", t_w);
            end
            else begin
                prep_start_w = 1;  
            end 
        end
        S_MONT: begin
            // t finishes, m finishes if it starts
            if ((mont_t_finish_r && mont_t_start_r) && (!i_d[counter_r] || (mont_m_finish_r && mont_m_start_r))) begin
                state_w = S_CALC;
                mont_m_start_w = 0;
                mont_t_start_w = 0;
                t_w = mont_t_result_r;
                m_w = mont_m_result_r;
            end
            else begin
                if (i_d[counter_r] == 1) begin
                    mont_m_start_w = 1;
                end
                mont_t_start_w = 1;
            end
        end
        S_CALC: begin
            if (counter_r == 255) begin
                m_w = m_r;
                state_w = S_IDLE;
                o_finished_w = 1;
            end
            else begin
                counter_w = counter_r + 1;
                state_w = S_MONT;
                m_w = mont_m_result_r;
            end
        end
    endcase
end

always_ff @(posedge i_start or posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        o_finished_r <= 0;
        enc_r <= 0;
        prep_start_r <= 0;
    end
    else begin
        if (i_start) begin
            enc_r <= i_a;
            state_r <= S_PREP;
            m_r <= 1;
            n_r <= i_n;
            counter_r <= 0;
            o_finished_r <= 0;
        end
        else begin
            state_r <= state_w;
            m_r <= m_w;
            t_r <= t_w;
            n_r <= n_w;
            counter_r <= counter_w;
            o_finished_r <= o_finished_w;
        end
        prep_start_r <= prep_start_w;
        mont_m_start_r <= mont_m_start_w;
        mont_t_start_r <= mont_t_start_w;
    end
end
endmodule

module RsaPrep (
    // return y * pow(2, bits, N) mod N
    input i_rst,
    input [255:0] i_n,
    input [255:0] i_y,
    input [15:0] i_bits,
    input i_start,
    output [255:0] o_prep,
    output o_finished
);

logic [255:0] counter_r, counter_w;
logic [258:0] tmp_r, tmp_w;
logic o_finished_r, o_finished_w;
logic [255:0] output_r, output_w;
reg started_r;
logic started_w;
logic next_counter_w;
assign next_counter_w = counter_r[0] ^ counter_w[0];

assign o_finished = o_finished_r;
assign o_prep = output_r;

always_comb begin
    started_w = started_r;
    o_finished_w = o_finished_r;
    counter_w = counter_r;
    tmp_w = tmp_r;
    output_w = output_r;
    while (tmp_w >= i_n) begin
        tmp_w = tmp_w - i_n;
    end
    if (o_finished_r == 0 && started_r) begin
        counter_w = counter_r - 1;
        if (counter_w == 0) begin
            o_finished_w = 1;
            output_w = tmp_w;
            started_w = 0;
        end
    end
end
always_ff @(posedge i_start or posedge i_rst or posedge next_counter_w) begin
    if (i_rst) begin
        started_r <= 0;
        o_finished_r <= 0;
        tmp_r <= 259'b0;
    end
    else if (i_start) begin
        o_finished_r <= o_finished_w;
        started_r <= started_w;
        if (started_r == 0) begin
            counter_r <= i_bits + 1;
            o_finished_r <= 0;
            tmp_r <= i_y;
            started_r <= 1;
        end
        else begin
            counter_r <= counter_w;
            tmp_r <= tmp_w << 1;
            o_finished_r <= o_finished_w;
        end
        // while (tmp_r >= i_n) begin
        //     tmp_r = tmp_r - i_n;
        // end
        output_r <= output_w;
    end
end
endmodule

module RsaMont (
    // return a * b * (2 ^ (-256)) mod N
    input i_rst,
    input [255:0] i_n,
    input [255:0] i_a,
    input [255:0] i_b,
    input [15:0] i_bits,
    input i_start,
    output [255:0] o_mont,
    output o_finished
);


logic [255:0] counter_r, counter_w;
logic [258:0] m_r, m_w;
logic [255:0] output_r, output_w;
logic o_finished_r, o_finished_w;
logic started_r, started_w;
logic next_counter_w;

assign o_finished = o_finished_r;
assign o_mont = output_r;
assign next_counter_w = counter_r[0] ^ counter_w[0];

always_comb begin
    o_finished_w = o_finished_r;
    started_w = started_r;
    m_w = m_r;
    if (!o_finished_r && started_r) begin
        counter_w = counter_r - 1;
        if (!counter_w) begin
            o_finished_w = 1;
            started_w = 0;
            if (m_r >= i_n) begin
                output_w = m_r - i_n;
            end
            else begin
                output_w = m_r;
            end
        end
    end
end

always_ff @(posedge i_start or posedge i_rst or posedge next_counter_w) begin
    if (i_rst) begin
        started_r <= 0;
        o_finished_r <= 0;
        m_r <= 259'b0;
    end
    else if (i_start) begin
        if (!started_r) begin
            m_r <= 259'b0;
            counter_r <= i_bits + 1;
            started_r <= 1;
            o_finished_r <= 0;
        end
        else begin
            o_finished_r <= o_finished_w;
            counter_r <= counter_w;
            started_r <= started_w;
            m_r = m_w;
            if (i_a[256 - counter_w]) begin
                m_r = m_r + i_b;
            end
            if (m_r[0] == 1) begin
                m_r = m_r + i_n;
            end
            m_r = m_r >> 1;
        end
        output_r <= output_w;
    end
    
end

endmodule


