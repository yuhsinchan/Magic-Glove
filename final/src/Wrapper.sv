module Wrapper (
    input         avm_rst,
    input         avm_clk,
	 input         i_start,
    // output  [4:0] avm_address,
    // output        avm_read,
    // input  [31:0] avm_readdata,
    // output        avm_write,
    // output [31:0] avm_writedata,
    // input         avm_waitrequest,

    // VGA
    output [7:0] o_VGA_B,
    output [7:0] o_VGA_G,
    output [7:0] o_VGA_R,
    output o_VGA_blank,
    output o_VGA_HS,
    output o_VGA_VS,
    output o_VGA_sync,
	 output o_VGA_clk
);

// localparam RX_BASE     = 0*4;
// localparam TX_BASE     = 1*4;
// localparam STATUS_BASE = 2*4;
// localparam TX_OK_BIT   = 6;
// localparam RX_OK_BIT   = 7;

// // Feel free to design your own FSM!
// localparam S_GET_KEY = 0;
// localparam S_GET_DATA = 1;
// localparam S_WAIT_CALCULATE = 2;
// localparam S_SEND_DATA = 3;

// logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
// // logic [1:0] state_r, state_w;
// logic [6:0] bytes_counter_r, bytes_counter_w;
// logic [4:0] avm_address_r, avm_address_w;
// logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

// logic rsa_start_r, rsa_start_w;
// logic rsa_finished;
// logic [255:0] rsa_dec;

// assign avm_address = avm_address_r;
// assign avm_read = avm_read_r;
// assign avm_write = avm_write_r;
// assign avm_writedata = dec_r[247-:8];

// task StartRead;
//     input [4:0] addr;
//     begin
//         avm_read_w = 1;
//         avm_write_w = 0;
//         avm_address_w = addr;
//     end
// endtask
// task StartWrite;
//     input [4:0] addr;
//     begin
//         avm_read_w = 0;
//         avm_write_w = 1;
//         avm_address_w = addr;
//     end
// endtask

parameter S_IDLE = 1'b0;
parameter S_DISPLAY = 1'b1;
parameter display_start = 1'b1;

logic state_r, state_w;

always_comb begin
    case(state_r)
        S_IDLE: begin
            if (display_start) begin
                state_w = S_DISPLAY;
            end else begin
                state_w = state_r;
            end
        end
        S_DISPLAY: begin
            state_w = state_r;
        end
        default: begin
            state_w = state_r;
        end
    endcase
    
end

always_ff @( posedge avm_clk or posedge avm_rst ) begin
    if (avm_rst) begin
        state_r <= S_IDLE;
    end else begin
        state_r <= state_w;
    end
end

VGA_display vga(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(i_start),
    .o_VGA_B(o_VGA_B),
    .o_VGA_R(o_VGA_R),
    .o_VGA_G(o_VGA_G),
    .o_VGA_blank(o_VGA_blank),
    .o_VGA_HS(o_VGA_HS),
    .o_VGA_VS(o_VGA_VS),
    .o_VGA_sync(o_VGA_sync),
	.o_VGA_clk(o_VGA_clk)
);
endmodule