module Wrapper(
    // RS232
    input avm_clk, 
    input avm_rst,
    output [4:0] avm_address,
    output avm_read,
    input [31:0] avm_readdata,
    input avm_waitrequest

    // VGA
    output [7:0] o_VGA_B,
    output [7:0] o_VGA_G,
    output [7:0] o_VGA_R,
    output o_VGA_blank,
    output o_VGA_HS,
    output o_VGA_VS,
    output o_VGA_sync,

);

parameter S_IDLE = 1'b0;
parameter S_DISPLAY = 1'b1;
parameter display_start = 1'b1;

logic state_r, state_w;

always_comb begin
    case(state_r)
        S_IDLE: begin
            if (i_start) begin
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

always_ff @( posedge avm_clk or negedge avm_rst ) begin
    if (!avm_rst) begin
        state_r <= S_IDLE;
    end else begin
        state_r <= state_w;
    end
end

VGA_display vga(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(display_start),
    .o_VGA_B(o_VGA_B),
    .o_VGA_R(o_VGA_R),
    .o_VGA_G(o_VGA_G),
    .o_VGA_blank(o_VGA_blank),
    .o_VGA_HS(o_VGA_HS),
    .o_VGA_VS(o_VGA_VS),
    .o_VGA_sybc(o_VGA_sync)
);

endmodule