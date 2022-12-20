module VGA_color(
    input i_clk,
    input i_rst,
    input [9:0] i_x_pos,
    input [9:0] i_y_pos,
    input [4:0] i_word_cnt,
    input [7:0] i_pattern_num [31:0],
    output [7:0] o_Blue,
    output [7:0] o_Green,
    output [7:0] o_Red
);

logic [23:0] color_r, color_w; // color will be displayed in {blue, green, red}
logic is_color;
logic in_word_x, in_word_y;
logic [4:0] cur_number_w, cur_number_r;
logic [9:0] cali_x_pos, cali_y_pos; // calibrate position by subtracting the offset from input position
logic [9:0] cur_offset_x_w, cur_offset_x_r, cur_offset_y_w, cur_offset_y_r;

assign o_Blue = color_r[23-:8];
assign o_Green = color_r[15-:8];
assign o_Red = color_r[7-:8];

// some const
localparam PIXEL_DIST = 10;
localparam PIXEL_LEN = 8;
localparam WORD_SIZE_X = PIXEL_DIST * 5;
localparam WORD_SIZE_Y = PIXEL_DIST * 7;
localparam WORD_DIST_X = 60;
localparam WORD_DIST_Y = 80;
localparam INIT_OFFSET_X = 40;
localparam INIT_OFFSET_Y = 30;

// pattern number declare here
localparam PAT_square = 8'd1;
localparam PAT_a = 8'd2;
localparam PAT_b = 8'd3;

// pattern form declare here
/***********
We will use a 5x7 matrix to display the pattern. For example, the pattern a will be like:
_ _ _ _ _
_ _ _ _ _
_ o o o _
_ _ _ _ o
_ o o o o
o _ _ _ o
_ o o o o
************/

localparam [34:0] pattern_a = {35'b00000000000111000001011111000101111};
localparam [34:0] pattern_b = {35'b10000100001011011001100011000111110};

task calibrate_position;
    input [9:0] raw_pos_x;
    input [9:0] raw_pos_y;
    input [9:0] offset_x;
    input [9:0] offset_y;
    input [9:0] cali_x;
    input [9:0] cali_y;
    output in_region_x;
    output in_region_y;
    if (offset_x > raw_pos_x || offset_x+WORD_SIZE_X < raw_pos_x) in_region_x = 0;
    else in_region_x = 1;
    if (offset_y > raw_pos_y || offset_y+WORD_SIZE_Y < raw_pos_y) in_region_y = 0;
    else in_region_y = 1;
    cali_x = raw_pos_x - offset_x;
    cali_y = raw_pos_y - offset_y;
endtask

task check_display;
    input [34:0] pattern;
    input [9:0] pos_x;
    input [9:0] pos_y;
    input [4:0] pixel_len;
    input [6:0] pixel_dist;
    output display;
	 integer i, j;
    for (i = 0; i < 7; i = i+1) begin
        for (j = 0; j < 5; j = j+1) begin
            if (i*pixel_dist <= pos_x && pos_x < (i+1)*pixel_dist && j*pixel_dist <= pos_y && pos_y <= (j+1)*pixel_dist) begin
                if (pattern[i*5 + j] == 0 || pos_x >= pixel_dist*i+pixel_len || pos_y >= pixel_dist*j+pixel_len) begin
                    display = 0;
                end else begin
                    display = 1;
                end
            end
        end
    end
endtask

// color declare here
localparam BLUE = {8'hFF, 8'h0, 8'h0};
localparam GREEN = {8'h0, 8'hFF, 8'h0};
localparam RED = {8'h0, 8'h0, 8'hFF};
localparam BLACK = {8'h0, 8'h0, 8'h0};
localparam WHITE = {8'hFF, 8'hFF, 8'hFF};
localparam YELLOW = {8'h0, 8'hFF, 8'hFF};
localparam CYAN = {8'hFF, 8'hFF, 8'h0};
localparam PINK = {8'hFF, 8'h0, 8'hFF};

always_comb begin
    cur_number_w = cur_number_r;
    color_w = color_r;
    is_color = 0;
    cur_offset_x_w = cur_offset_x_r;
	cur_offset_y_w = cur_offset_y_r;
    calibrate_position(i_x_pos, i_y_pos, cur_offset_x_r, cur_offset_y_r, cali_x_pos, cali_y_pos, in_word_x, in_word_y);
    if (!in_word_x || !in_word_y) begin
        color_w = YELLOW;
        if (!in_word_x && cur_number_r < i_word_cnt) begin
            cur_offset_x_w = cur_offset_x_r + WORD_DIST_X;
            cur_number_w = cur_number_r + 1;
        end
    end else begin
        case(i_pattern_num[cur_number_r])
            PAT_square: begin
                if (i_x_pos >= 300 && i_x_pos <= 600 && i_y_pos >= 100 && i_y_pos <= 400) begin
                    color_w = PINK;
                end else begin
                    color_w = CYAN;
                end
            end
            PAT_a: begin
                check_display(pattern_a, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLUE;
            end
            PAT_b: begin
                check_display(pattern_b, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLUE;
            end
            default: begin
                color_w = BLUE;
            end
        endcase
    end
end

always_ff @( posedge i_clk or posedge i_rst ) begin
    if (i_rst) begin
        color_r <= 23'b0;
        cur_offset_x_r <= INIT_OFFSET_X;
        cur_offset_y_r <= INIT_OFFSET_Y;
        cur_number_r <= 0;
    // end else if (i_next) begin
    //     cur_offset_x_r <= INIT_OFFSET_X;
    //     cur_offset_y_r <= INIT_OFFSET_Y;
    //     cur_number_r <= 0;
    end else begin
        color_r <= color_w;
        cur_offset_x_r <= cur_offset_x_w;
        cur_offset_y_r <= cur_offset_y_w;
        cur_number_r <= cur_number_w;
    end
end

endmodule