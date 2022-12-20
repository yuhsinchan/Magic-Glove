module VGA_display(
    input i_clk, // 25MHz
    input i_rst,
	input i_start,
    output [7:0] o_VGA_G,
    output [7:0] o_VGA_B,
    output [7:0] o_VGA_R,
    output o_VGA_blank,
    output o_VGA_HS,
    output o_VGA_VS,
    output o_VGA_sync,
    output o_VGA_clk
);

logic [9:0] counter_x_r, counter_x_w;
logic [9:0] counter_y_r, counter_y_w;
logic hsync_r, hsync_w;
logic vsync_r, vsync_w;
logic [7:0] vga_R_r, vga_R_w, vga_B_r, vga_B_w, vga_G_r, vga_G_w; 
logic state_r, state_w;
integer i;

// horizontal timings
parameter H_FRONT = 16;
parameter H_SYNC = 96;
parameter H_BACK = 48;
parameter H_ACT = 640;
parameter H_BLANK = H_FRONT + H_SYNC + H_BACK;
parameter H_TOTAL = H_FRONT + H_SYNC + H_BACK + H_ACT;

// vertical timings
parameter V_FRONT = 10;
parameter V_SYNC = 2;
parameter V_BACK = 33;
parameter V_ACT = 480;
parameter V_BLANK = V_FRONT + V_SYNC + V_BACK;
parameter V_TOTAL = V_FRONT + V_SYNC + V_BACK + V_ACT;

// FSM
parameter S_IDLE = 1'b0;
parameter S_DISPLAY = 1'b1;

// output
// assign o_VGA_B = vga_B_r;
// assign o_VGA_R = vga_R_r;
// assign o_VGA_G = vga_G_r;
assign o_VGA_clk = i_clk;
assign o_VGA_HS = hsync_r;
assign o_VGA_VS = vsync_r;
assign o_VGA_blank = ~((counter_x_r < H_BLANK) || (counter_y_r < V_BLANK));

// pattern test const
localparam PATTERN = 8'd0;
localparam COUNT = 5'd1;
localparam NEXT = 0;

// patterns
logic [4:0] word_count_r, word_count_w; // max 32 words
logic [7:0] pattern_number_r [31:0];
logic [7:0] pattern_number_w [31:0];

// test combinational circuit
always_comb begin
    case(state_r)
        S_IDLE: begin
            word_count_w = 0;
        end
        S_DISPLAY: begin
            word_count_w = 5'd2;
            pattern_number_w[0] = 8'd2;
            pattern_number_w[1] = 8'd3;
        end
    endcase
end

// state transition
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
    endcase
end

// pixel position
always_comb begin
    S_IDLE: begin
        counter_x_w = 0;
        counter_y_w = 0;
    end
    S_DISPLAY: begin
        if (counter_x_r == H_TOTAL) begin
            if (counter_y_r == V_TOTAL) begin
                counter_y_w = 0;
            end else begin
                counter_y_w = counter_y_r + 1;
            end
            counter_x_w = 0;
        end else begin
            counter_x_w = counter_x_r + 1;
            counter_y_w = counter_y_r;
        end
    end
end

// sync logic
always_comb begin
    case(state_r)
        S_IDLE: begin
            // the value holds the opposite, 1 stands for not sync
            hsync_w = 1;
            vsync_w = 1;
        end
        S_DISPLAY: begin
            if (counter_x_r == 0) begin
                hsync_w = 1'b0;
            end else if (counter_x_r == H_SYNC) begin
                hsync_w = 1'b1;
            end else begin
                hsync_w = hsync_r;
            end
            if (counter_y_r == 0) begin
                vsync_w = 1'b0;
            end else if (counter_y_r == V_SYNC) begin
                vsync_w = 1'b1;
            end else begin
                vsync_w = vsync_r;
            end
        end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        for (i = 0; i < 32; i = i+1) begin
            pattern_number_r[i] <= 8'd0;
        end
        word_count_r <= 0;
        counter_x_r <= 0;
        counter_y_r <= 0;
        hsync_r <= 1;
        vsync_r <= 1;
        state_r <= S_IDLE;
    end else begin
        for (i = 0; i < 32; i = i+1) begin
            pattern_number_r[i] <= pattern_number_w[i];
        end
        word_count_r <= word_count_w;
        counter_x_r <= counter_x_w;
        counter_y_r <= counter_y_w;
        hsync_r <= hsync_w;
        vsync_r <= vsync_w;
        state_r <= state_w;
    end
    
end

// color module
VGA_color color(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_x_pos(counter_x_r),
    .i_y_pos(counter_y_r),
    .i_word_cnt(word_count_r),
    .i_pattern_num(pattern_number_r),
    .o_Blue(o_VGA_B),
    .o_Green(o_VGA_G),
    .o_Red(o_VGA_R)
);

endmodule