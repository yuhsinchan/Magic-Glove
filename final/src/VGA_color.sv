// display constant
`define ROW_CNT 3
`define ROW_SIZE 10
module VGA_color(
    input i_clk,
    input i_rst,
    input [9:0] i_x_pos,
    input [9:0] i_y_pos,
    input [3:0] i_word_cnt [0:`ROW_CNT-1],
    input [7:0] i_pattern_num [0:`ROW_CNT-1][0:`ROW_SIZE-1],
    output [7:0] o_Blue,
    output [7:0] o_Green,
    output [7:0] o_Red
);

logic [23:0] color_r, color_w; // color will be displayed in {blue, green, red}
logic is_color;
logic [3:0] row, column;
logic in_word_x, in_word_y;
// logic [4:0] cur_number_w, cur_number_r;
logic [9:0] cali_x_pos, cali_y_pos; // calibrate position by subtracting the offset from input position
logic [9:0] cur_offset_x_w, cur_offset_x_r, cur_offset_y_w, cur_offset_y_r;

assign o_Blue = color_r[23-:8];
assign o_Green = color_r[15-:8];
assign o_Red = color_r[7-:8];

// some display position const
parameter PIXEL_DIST = 10;
parameter PIXEL_LEN = 8;
parameter WORD_SIZE_X = PIXEL_DIST * 5;
parameter WORD_SIZE_Y = PIXEL_DIST * 7;
parameter WORD_DIST_X = WORD_SIZE_X + 10;
parameter WORD_DIST_Y = WORD_SIZE_Y + 10;
parameter INIT_OFFSET_X = 30;
parameter INIT_OFFSET_Y = 30;
parameter ROW_DIST = 20;


// pattern number declare here
parameter PAT_space = 8'd1;
parameter PAT_LOW_a = 8'd2;
parameter PAT_LOW_b = 8'd3;
parameter PAT_LOW_c = 8'd4;
parameter PAT_LOW_d = 8'd5;
parameter PAT_LOW_e = 8'd6;
parameter PAT_LOW_f = 8'd7;
parameter PAT_LOW_g = 8'd8;
parameter PAT_LOW_h = 8'd9;
parameter PAT_LOW_i = 8'd10;
parameter PAT_LOW_j = 8'd11;
parameter PAT_LOW_k = 8'd12;
parameter PAT_LOW_l = 8'd13;
parameter PAT_LOW_m = 8'd14;
parameter PAT_LOW_n = 8'd15;
parameter PAT_LOW_o = 8'd16;
parameter PAT_LOW_p = 8'd17;
parameter PAT_LOW_q = 8'd18;
parameter PAT_LOW_r = 8'd19;
parameter PAT_LOW_s = 8'd20;
parameter PAT_LOW_t = 8'd21;
parameter PAT_LOW_u = 8'd22;
parameter PAT_LOW_v = 8'd23;
parameter PAT_LOW_w = 8'd24;
parameter PAT_LOW_x = 8'd25;
parameter PAT_LOW_y = 8'd26;
parameter PAT_LOW_z = 8'd27;
parameter PAT_UPP_A = 8'd28;
parameter PAT_UPP_B = 8'd29;
parameter PAT_UPP_C = 8'd30;
parameter PAT_UPP_D = 8'd31;
parameter PAT_UPP_E = 8'd32;
parameter PAT_UPP_F = 8'd33;
parameter PAT_UPP_G = 8'd34;
parameter PAT_UPP_H = 8'd35;
parameter PAT_UPP_I = 8'd36;
parameter PAT_UPP_J = 8'd37;
parameter PAT_UPP_K = 8'd38;
parameter PAT_UPP_L = 8'd39;
parameter PAT_UPP_M = 8'd40;
parameter PAT_UPP_N = 8'd41;
parameter PAT_UPP_O = 8'd42;
parameter PAT_UPP_P = 8'd43;
parameter PAT_UPP_Q = 8'd44;
parameter PAT_UPP_R = 8'd45;
parameter PAT_UPP_S = 8'd46;
parameter PAT_UPP_T = 8'd47;
parameter PAT_UPP_U = 8'd48;
parameter PAT_UPP_V = 8'd49;
parameter PAT_UPP_W = 8'd50;
parameter PAT_UPP_X = 8'd51;
parameter PAT_UPP_Y = 8'd52;
parameter PAT_UPP_Z = 8'd53;


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
parameter [34:0] pattern_space   = {35'b00000000000000000000000000000000000};
parameter [34:0] pattern_lower_a = {35'b00000000000111000001011111000101111};
parameter [34:0] pattern_lower_b = {35'b10000100001011011001100011000111110};
parameter [34:0] pattern_lower_c = {35'b00000000000111010000100001000101110};
parameter [34:0] pattern_lower_d = {35'b00001000010110110011100011000101111};
parameter [34:0] pattern_lower_e = {35'b00000000000111010001111111000001110};
parameter [34:0] pattern_lower_f = {35'b00110010010100011100010000100001000};
parameter [34:0] pattern_lower_g = {35'b00000000000111110001011110000101110};
parameter [34:0] pattern_lower_h = {35'b10000100001011011001100011000110001};
parameter [34:0] pattern_lower_i = {35'b00100000000010001100001000010001110};
parameter [34:0] pattern_lower_j = {35'b00001000000001100001000010100100110};
parameter [34:0] pattern_lower_k = {35'b10000100001001010100110001010010010};
parameter [34:0] pattern_lower_l = {35'b01100001000010000100001000010001110};
parameter [34:0] pattern_lower_m = {35'b00000000001101010101101011010110101};
parameter [34:0] pattern_lower_n = {35'b00000000001011011001100011000110001};
parameter [34:0] pattern_lower_o = {35'b00000000000111010001100011000101110};
parameter [34:0] pattern_lower_p = {35'b00000000001111010001111101000010000};
parameter [34:0] pattern_lower_q = {35'b00000000000111110001011110000100001};
parameter [34:0] pattern_lower_r = {35'b00000000001011011001100001000010000};
parameter [34:0] pattern_lower_s = {35'b00000000000111010000011100000111110};
parameter [34:0] pattern_lower_t = {35'b01000111000100001000010000100100110};
parameter [34:0] pattern_lower_u = {35'b00000000001000110001100011001101101};
parameter [34:0] pattern_lower_v = {35'b00000000001000110001100010101000100};
parameter [34:0] pattern_lower_w = {35'b00000000001000110001101011010101010};
parameter [34:0] pattern_lower_x = {35'b00000000001000101010001000101010001};
parameter [34:0] pattern_lower_y = {35'b00000000001000110001011110000101110};
parameter [34:0] pattern_lower_z = {35'b00000000001111100010001000100011111};
parameter [34:0] pattern_upper_A = {35'b00100010101000110001111111000110001};
parameter [34:0] pattern_upper_B = {35'b11110010010100101110010010100111110};
parameter [34:0] pattern_upper_C = {35'b01110100011000010000100001000101110};
parameter [34:0] pattern_upper_D = {35'b11110010010100101001010010100111110};
parameter [34:0] pattern_upper_E = {35'b11111100001000011111100001000011111};
parameter [34:0] pattern_upper_F = {35'b11111100001000011110100001000010000};
parameter [34:0] pattern_upper_G = {35'b01110100011000010011100011000101111};
parameter [34:0] pattern_upper_H = {35'b10001100011000111111100011000110001};
parameter [34:0] pattern_upper_I = {35'b01110001000010000100001000010001110};
parameter [34:0] pattern_upper_J = {35'b00111000100001000010000101001001100};
parameter [34:0] pattern_upper_K = {35'b10001100101010011000101001001010001};
parameter [34:0] pattern_upper_L = {35'b10000100001000010000100001000011111};
parameter [34:0] pattern_upper_M = {35'b10001110111010110101100011000110001};
parameter [34:0] pattern_upper_N = {35'b10001100011100110101100111000110001};
parameter [34:0] pattern_upper_O = {35'b01110100011000110001100011000101110};
parameter [34:0] pattern_upper_P = {35'b11110100011000111110100001000010000};
parameter [34:0] pattern_upper_Q = {35'b01110100011000110001101011001001101};
parameter [34:0] pattern_upper_R = {35'b11110100011000111110101001001010001};
parameter [34:0] pattern_upper_S = {35'b01110100011000001110000011000101110};
parameter [34:0] pattern_upper_T = {35'b11111001000010000100001000010000100};
parameter [34:0] pattern_upper_U = {35'b10001100011000110001100011000101110};
parameter [34:0] pattern_upper_V = {35'b10001100011000110001100010101000100};
parameter [34:0] pattern_upper_W = {35'b10001100011000110101101011010101010};
parameter [34:0] pattern_upper_X = {35'b10001100010101000100010101000110001};
parameter [34:0] pattern_upper_Y = {35'b10001100011000101010001000010000100};
parameter [34:0] pattern_upper_Z = {35'b11111000010001000100010001000011111};


task calibrate_position;
    input [9:0] raw_pos_x;
    input [9:0] raw_pos_y;
    input [3:0] word_cnt [0:`ROW_CNT-1];
    input [9:0] offset_x;
    input [9:0] offset_y;
    output [9:0] cali_x;
    output [9:0] cali_y;
    output in_region_x;
    output in_region_y;
    output [3:0] row;
    output [3:0] col;
    integer i;
    // calculate which row
    row = 0;
    if (offset_y <= raw_pos_y && raw_pos_y < offset_y + (`ROW_CNT)*(ROW_DIST+WORD_SIZE_Y)) begin
        in_region_y = 1;
        for (i = 0; i <= `ROW_CNT-1; i = i+1) begin
            if (offset_y + i*(ROW_DIST+WORD_DIST_Y) <= raw_pos_y && raw_pos_y < offset_y + (i+1)*(ROW_DIST+WORD_DIST_Y)) begin
                row = i;
            end
        end
        cali_y = raw_pos_y - row*(ROW_DIST+WORD_DIST_Y) - offset_y;
    end else begin
        in_region_y = 0;
        cali_y = 0;
    end
    // calculate x position
    col = 0;
    if (offset_x <= raw_pos_x && raw_pos_x < offset_x + word_cnt[row]*WORD_DIST_X) begin
        in_region_x = 1;
        for (i = 0; i < word_cnt[row]; i = i+1) begin
            if (offset_x + i*WORD_DIST_X <= raw_pos_x && offset_x + (i+1)*WORD_DIST_X > raw_pos_x) begin
                col = i;
            end
        end
        cali_x = raw_pos_x - col*WORD_DIST_X - offset_x;
    end else begin
        in_region_x = 0;
        cali_x = 0;
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
            if (j*pixel_dist <= pos_x && pos_x < (j+1)*pixel_dist && i*pixel_dist <= pos_y && pos_y <= (i+1)*pixel_dist) begin
                if (pattern[34 - i*5 - j] == 0 || pos_x >= pixel_dist*j+pixel_len || pos_y >= pixel_dist*i+pixel_len) begin
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
    in_word_x = 0;
    in_word_y = 0;
    cali_x_pos = INIT_OFFSET_X;
    cali_y_pos = INIT_OFFSET_Y;
    row = 0;
    column = 0;
    calibrate_position(i_x_pos, i_y_pos, i_word_cnt ,INIT_OFFSET_X, INIT_OFFSET_Y, cali_x_pos, cali_y_pos, in_word_x, in_word_y, row, column);
    if (!in_word_x || !in_word_y) begin
        color_w = BLACK;
    end else begin
        case(i_pattern_num[row][column])
            PAT_space: begin
                check_display(pattern_space, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_a: begin
                check_display(pattern_lower_a, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_b: begin
                check_display(pattern_lower_b, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_c: begin
                check_display(pattern_lower_c, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_d: begin
                check_display(pattern_lower_d, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_e: begin
                check_display(pattern_lower_e, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_f: begin
                check_display(pattern_lower_f, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_g: begin
                check_display(pattern_lower_g, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_h: begin
                check_display(pattern_lower_h, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_i: begin
                check_display(pattern_lower_i, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_j: begin
                check_display(pattern_lower_j, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_k: begin
                check_display(pattern_lower_k, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_l: begin
                check_display(pattern_lower_l, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_m: begin
                check_display(pattern_lower_m, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_n: begin
                check_display(pattern_lower_n, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_o: begin
                check_display(pattern_lower_o, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_p: begin
                check_display(pattern_lower_p, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_q: begin
                check_display(pattern_lower_q, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_r: begin
                check_display(pattern_lower_r, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_s: begin
                check_display(pattern_lower_s, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_t: begin
                check_display(pattern_lower_t, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_u: begin
                check_display(pattern_lower_u, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_v: begin
                check_display(pattern_lower_v, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_w: begin
                check_display(pattern_lower_w, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_x: begin
                check_display(pattern_lower_x, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_y: begin
                check_display(pattern_lower_y, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_LOW_z: begin
                check_display(pattern_lower_z, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_A: begin
                check_display(pattern_upper_A, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_B: begin
                check_display(pattern_upper_B, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_C: begin
                check_display(pattern_upper_C, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_D: begin
                check_display(pattern_upper_D, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_E: begin
                check_display(pattern_upper_E, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_F: begin
                check_display(pattern_upper_F, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_G: begin
                check_display(pattern_upper_G, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_H: begin
                check_display(pattern_upper_H, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_I: begin
                check_display(pattern_upper_I, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_J: begin
                check_display(pattern_upper_J, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_K: begin
                check_display(pattern_upper_K, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_L: begin
                check_display(pattern_upper_L, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_M: begin
                check_display(pattern_upper_M, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_N: begin
                check_display(pattern_upper_N, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_O: begin
                check_display(pattern_upper_O, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_P: begin
                check_display(pattern_upper_P, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_Q: begin
                check_display(pattern_upper_Q, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_R: begin
                check_display(pattern_upper_R, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_S: begin
                check_display(pattern_upper_S, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_T: begin
                check_display(pattern_upper_T, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_U: begin
                check_display(pattern_upper_U, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_V: begin
                check_display(pattern_upper_V, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_W: begin
                check_display(pattern_upper_W, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_X: begin
                check_display(pattern_upper_X, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_Y: begin
                check_display(pattern_upper_Y, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
            end
            PAT_UPP_Z: begin
                check_display(pattern_upper_Z, cali_x_pos, cali_y_pos, PIXEL_LEN, PIXEL_DIST, is_color);
                color_w = is_color ? WHITE : BLACK;
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