module VGA_color(
    input i_clk,
    input i_rst,
    input [9:0] i_x_pos,
    input [9:0] i_y_pos,
    input [4:0] i_word_cnt,
    input [7:0] i_pattern_num [0:31],
    output [7:0] o_Blue,
    output [7:0] o_Green,
    output [7:0] o_Red
);

logic [23:0] color_r, color_w; // color will be displayed in {blue, green, red}
logic is_color;
logic [4:0] index;
logic in_word_x, in_word_y;
// logic [4:0] cur_number_w, cur_number_r;
logic [9:0] cali_x_pos, cali_y_pos; // calibrate position by subtracting the offset from input position
logic [9:0] cur_offset_x_w, cur_offset_x_r, cur_offset_y_w, cur_offset_y_r;

assign o_Blue = color_r[23-:8];
assign o_Green = color_r[15-:8];
assign o_Red = color_r[7-:8];

// some const
parameter PIXEL_DIST = 10;
parameter PIXEL_LEN = 8;
parameter WORD_SIZE_X = PIXEL_DIST * 5;
parameter WORD_SIZE_Y = PIXEL_DIST * 7;
parameter WORD_DIST_X = WORD_SIZE_X + 10;
parameter WORD_DIST_Y = WORD_SIZE_Y + 10;
parameter INIT_OFFSET_X = 40; // 300
parameter INIT_OFFSET_Y = 30; // 200


// pattern number declare here
parameter PAT_square = 8'd1;
parameter PAT_a = 8'd2;
parameter PAT_b = 8'd3;

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

parameter [34:0] pattern_a = {35'b00000000000111000001011111000101111};
parameter [34:0] pattern_b = {35'b10000100001011011001100011000111110};

task calibrate_position;
    input [9:0] raw_pos_x;
    input [9:0] raw_pos_y;
    input [4:0] word_cnt;
    input [9:0] offset_x;
    input [9:0] offset_y;
    output [9:0] cali_x;
    output [9:0] cali_y;
    output in_region_x;
    output in_region_y;
    output [4:0] idx;
    // calculate x position
    integer i;
    // if (40 <= raw_pos_x) begin
    //     in_region_x = 1;
    //     cali_x = 0;
    //     idx = 0;
    if (offset_x <= raw_pos_x && raw_pos_x < offset_x + word_cnt*WORD_DIST_X) begin
        i = 0;
        idx = 0;
        in_region_x = 1;
        while (i < word_cnt) begin
            if (offset_x + (i+1)*WORD_DIST_X > raw_pos_x) begin
                idx = i;
            end
            i = i + 1;
        end
        cali_x = raw_pos_x - idx*WORD_DIST_X - offset_x;
    end else begin
        idx = 0;
        in_region_x = 0;
        cali_x = 0;
    end
    
    // calculate y position
    if (30 <= raw_pos_y && 30 + WORD_DIST_Y > raw_pos_y) begin
        in_region_y = 1;
        cali_y = raw_pos_y - offset_y;
    end else begin
        in_region_y = 0;
        cali_y = 0;
    end
    
    
endtask

task check_display;
    input [34:0] pattern;
    input [9:0] pos_x;
    input [9:0] pos_y;
    input [4:0] pixel_len;
    input [6:0] pixel_dist;
    output display;
	integer i, j;
    display = 0;
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
parameter BLUE = {8'hFF, 8'h0, 8'h0};
parameter GREEN = {8'h0, 8'hFF, 8'h0};
parameter RED = {8'h0, 8'h0, 8'hFF};
parameter BLACK = {8'h0, 8'h0, 8'h0};
parameter WHITE = {8'hFF, 8'hFF, 8'hFF};
parameter YELLOW = {8'h0, 8'hFF, 8'hFF};
parameter CYAN = {8'hFF, 8'hFF, 8'h0};
parameter PINK = {8'hFF, 8'h0, 8'hFF};

always_comb begin
    color_w = color_r;
    is_color = 0;
    index = 0;
    in_word_x = 0;
    in_word_y = 0;
    cali_x_pos = INIT_OFFSET_X;
    cali_y_pos = INIT_OFFSET_Y;
    calibrate_position(i_x_pos, i_y_pos, i_word_cnt ,INIT_OFFSET_X, INIT_OFFSET_Y, cali_x_pos, cali_y_pos, in_word_x, in_word_y, index);
    if (!in_word_x || !in_word_y) begin
    // if (i_x_pos <= INIT_OFFSET_X || i_y_pos <= INIT_OFFSET_Y) begin
    //     color_w = YELLOW;
    end else begin
        case(i_pattern_num[index])
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
    // end else if (i_next) begin
    //     cur_offset_x_r <= INIT_OFFSET_X;
    //     cur_offset_y_r <= INIT_OFFSET_Y;
    //     cur_number_r <= 0;
    end else begin
        color_r <= color_w;
    end
end

endmodule