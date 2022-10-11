module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output [ 4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest,
    output [ 2:0] state,
    output [ 6:0] total_len
);

    localparam RX_BASE = 0 * 4;
    localparam TX_BASE = 1 * 4;
    localparam STATUS_BASE = 2 * 4;
    localparam TX_OK_BIT = 6;
    localparam RX_OK_BIT = 7;

    // Follow the finite state machine on pages 25.
    localparam S_QUERY_RX = 0;
    localparam S_READ = 1;
    localparam S_CALC = 2;
    localparam S_QUERY_TX = 3;
    localparam S_WRITE = 4;

    // mode for reading and writing
    localparam MODE_256 = 0;
    localparam MODE_1024 = 1;
    localparam MODE_PENDING = 2;


    logic [1023:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
    logic [2:0] state_r, state_w;
    logic [2:0] mode_r, mode_w;
    logic [16:0] len_r, len_w;
    logic [6:0] bytes_counter_r, bytes_counter_w;
    logic [4:0] avm_address_r, avm_address_w;
    logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

    logic rsa_start_r, rsa_start_w;
    logic rsa_finished;
    logic [1023:0] rsa_dec;
    logic [128:0] counter_r, counter_w;
    logic [6:0] total_len_r, total_len_w;

    assign avm_address = avm_address_r;
    assign avm_read = avm_read_r;
    assign avm_write = avm_write_r;
    assign avm_writedata = dec_r[247-:8];
    assign state = state_r;
    assign total_len = total_len_r;

    Rsa256Core rsa256_core (
        .i_clk(avm_clk),
        .i_rst(avm_rst),
        .i_start(rsa_start_r),
        .i_a(enc_r),
        .i_d(d_r),
        .i_n(n_r),
        .o_a_pow_d(rsa_dec),
        .o_finished(rsa_finished)
    );

    task StartRead(input [4:0] addr);
        begin
            avm_read_w = 1;
            avm_write_w = 0;
            avm_address_w = addr;
        end
    endtask
    task StartWrite(input [4:0] addr);
        begin
            avm_read_w = 0;
            avm_write_w = 1;
            avm_address_w = addr;
        end
    endtask

    always_comb begin
        // default values
        state_w = state_r;
        bytes_counter_w = bytes_counter_r;

        n_w = n_r;
        d_w = d_r;
        enc_w = enc_r;
        dec_w = dec_r;

        rsa_start_w = rsa_start_r;

        avm_address_w = avm_address_r;
        avm_read_w = avm_read_r;
        avm_write_w = avm_write_r;

        total_len_w = total_len_r;
        counter_w = counter_r + 1;

        mode_w <= mode_r;
        len_w  <= len_r;

        // TODO
        case (state_r)
            S_QUERY_RX: begin
                // if readdata[7] in Base+8 is 1, go to S_READ
                // else, repeat reading status
                if (~avm_waitrequest && avm_readdata[RX_OK_BIT] == 1) begin
                    StartRead(RX_BASE);
                    state_w = S_READ;
                    bytes_counter_w = bytes_counter_r + 1;
                end else begin
                    StartRead(STATUS_BASE);
                end
            end
            S_READ: begin
                // read 32-byte divisor N -> 32-byte exponent D -> 32-byte enc
                if (~avm_waitrequest) begin
                    StartRead(STATUS_BASE);
                    case (mode_r)
                        MODE_256: begin
                            if (bytes_counter_r < 33) begin
                                state_w = S_QUERY_RX;
                                n_w = {n_r[1015:0], avm_readdata[7:0]};
                            end else if (bytes_counter_r < 65) begin
                                state_w = S_QUERY_RX;
                                d_w = {d_r[1015:0], avm_readdata[7:0]};
                            end else if (bytes_counter_r < 96) begin
                                state_w = S_QUERY_RX;
                                enc_w   = {enc_r[1015:0], avm_readdata[7:0]};
                            end else begin
                                state_w = S_CALC;
                                enc_w = {enc_r[1015:0], avm_readdata[7:0]};
                                bytes_counter_w = 0;
                                rsa_start_w = 1;
                                avm_read_w = 0;
                            end
                        end

                        MODE_1024: begin
                            if (bytes_counter_r < 127) begin
                                state_w = S_QUERY_RX;
                                n_w = {n_r[1015:0], avm_readdata[7:0]};
                            end else if (bytes_counter_r < 255) begin
                                state_w = S_QUERY_RX;
                                d_w = {d_r[1015:0], avm_readdata[7:0]};
                            end else if (bytes_counter_r < 384) begin
                                state_w = S_QUERY_RX;
                                enc_w   = {enc_r[1015:0], avm_readdata[7:0]};
                            end else begin
                                state_w = S_CALC;
                                enc_w = {enc_r[1015:0], avm_readdata[7:0]};
                                bytes_counter_w = 0;
                                rsa_start_w = 1;
                                avm_read_w = 0;
                            end
                        end

                        MODE_PENDING: begin
                            if (bytes_counter_r < 2) begin
                                state_w = S_QUERY_RX;
                                len_w   = {len_r[7:0], avm_readdata[7:0]};
                            end else begin
                                state_w = S_QUERY_RX;
                                if (len_w == 256) begin
                                    mode_w = MODE_256;
                                end else if (len_w == 1024) begin
                                    mode_w = MODE_1024;
                                end
                                bytes_counter_w = 0;
                            end
                        end

                    endcase
                end
            end
            S_CALC: begin
                if (rsa_finished) begin
                    // $display("rsa finished");
                    // $display("dec: %64x", rsa_dec);
                    state_w = S_QUERY_TX;
                    dec_w   = rsa_dec;
                end
                rsa_start_w = 0;
            end
            S_QUERY_TX: begin
                if (~avm_waitrequest && avm_readdata[TX_OK_BIT] == 1) begin
                    StartWrite(TX_BASE);
                    state_w = S_WRITE;
                    bytes_counter_w = bytes_counter_r + 1;
                    total_len_w = total_len_r + 1;
                end else begin
                    StartRead(STATUS_BASE);
                    state_w = state_r;
                end
            end
            S_WRITE: begin
                if (~avm_waitrequest) begin
                    StartRead(STATUS_BASE);
                    case (mode_r)
                        MODE_256: begin
                            if (bytes_counter_r == 31) begin
                                state_w = S_QUERY_RX;
                                bytes_counter_w = 64;
                            end else begin
                                state_w = S_QUERY_TX;
                                dec_w   = {dec_r[1015:0], dec_r[1023:1016]};
                            end
                        end

                        MODE_1024: begin
                            if (bytes_counter__r == 127) begin
                                state_w = S_QUERY_RX;
                                bytes_counter_w = 254;
                            end else begin
                                state_w = S_QUERY_TX;
                                dec_w   = {dec_r[1015:0], dec_r[1023:1016]};
                            end
                        end

                    endcase
                end
            end
            default: begin

            end
        endcase
    end

    always_ff @(posedge avm_clk or posedge avm_rst) begin
        if (avm_rst) begin
            n_r <= 0;
            d_r <= 0;
            enc_r <= 0;
            dec_r <= 0;
            avm_address_r <= STATUS_BASE;
            mode_r <= MODE_PENDING;
            avm_read_r <= 1;
            avm_write_r <= 0;
            state_r <= S_QUERY_RX;
            bytes_counter_r <= 0;
            rsa_start_r <= 0;
            counter_r <= 0;
            total_len_r <= 0;
        end else if (counter_r == 200000000) begin  // use for auto reset
            n_r <= 0;
            d_r <= 0;
            enc_r <= 0;
            dec_r <= 0;
            avm_address_r <= STATUS_BASE;
            mode_r <= MODE_PENDING;
            len_r <= 0;
            avm_read_r <= 1;
            avm_write_r <= 0;
            state_r <= S_QUERY_RX;
            bytes_counter_r <= 0;
            rsa_start_r <= 0;
            counter_r <= 0;
            total_len_r <= 0;
        end else begin
            n_r <= n_w;
            d_r <= d_w;
            enc_r <= enc_w;
            dec_r <= dec_w;
            avm_address_r <= avm_address_w;
            avm_read_r <= avm_read_w;
            avm_write_r <= avm_write_w;
            state_r <= state_w;
            bytes_counter_r <= bytes_counter_w;
            rsa_start_r <= rsa_start_w;
            counter_r <= counter_w;
            total_len_r <= total_len_w;
        end
    end

endmodule
