module VGA_clock(
    input i_clk,
    input i_rst_n,
    output o_vga_clk
);

logic [1:0] tmp_r;

assign o_vga_clk = tmp_r[1];

always_ff @( posedge i_clk ) begin
    if (i_rst_n) begin
        tmp_r <= 0;
    end
    else begin
        tmp_r <= (tmp_r + 1) & 2'b11;
    end
end

endmodule