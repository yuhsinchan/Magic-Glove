module VGA_display(
    input i_clk,
    input i_rst_n,
    output [7:0] o_VGA_G,
    output [7:0] o_VGA_B,
    output [7:0] o_VGA_R,
    output o_VGA_blank,
    output o_VGA_HS,
    output o_VGA_VS,
    output o_VGA_sync,
    output o_VGA_clk
);

VGA_clock VGA_clk(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.o_vga_clk(pix_clk)
);

logic pix_clk;
logic [9:0] counter_x;
logic [9:0] counter_y;
logic [7:0] vga_R;
logic [7:0] vga_B;
logic [7:0] vga_G;

// horizontal timings
parameter HA_END = 639;
parameter HS_STA = HA_END + 16;
parameter HS_END = HS_STA + 96;
parameter LINE = 799;

// vertical timings
parameter VA_END = 479;
parameter VS_STA = VA_END + 10;
parameter VS_END = VS_STA + 2;
parameter SCREEN = 524;

assign o_VGA_clk = pix_clk;
assign o_VGA_G = vga_G;
assign o_VGA_B = vga_B;
assign o_VGA_R = vga_R;

// test color
parameter test_R = 255;
parameter test_G = 0;
parameter test_B = 0;
always_comb begin
    vga_B = test_B;
    vga_R = test_R;
    vga_G = test_G;
end

always_comb begin
    o_VGA_HS = ~(counter_x >= HS_STA && counter_x < HS_END);
    o_VGA_VS = ~(counter_y >= VS_STA && counter_y < VS_END); 
    o_VGA_blank = 0;
    o_VGA_sync = 0;
end

always_ff @(posedge pix_clk ) begin
    if (counter_x == LINE) begin
        counter_x <= 0;
        counter_y <= (counter_y == SCREEN) ? 0 : counter_y + 1;
    end else begin
        counter_x <= counter_x + 1;
    end
    if (i_rst_n) begin
        counter_x <= 0;
        counter_y <= 0;
    end
    
end

endmodule