// display constant
`define ROW_CNT 3
`define ROW_SIZE 10

module VGA_display(
    input i_clk, // 25MHz
    input i_rst,
	input i_start,
    input [3:0] i_letter_cnt [0:`ROW_CNT-1],
    input [7:0] i_letters [0:`ROW_CNT-1][0:`ROW_SIZE-1],
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
logic [9:0] active_x, active_y;
logic hsync_r, hsync_w;
logic vsync_r, vsync_w;
logic [7:0] vga_R_r, vga_R_w, vga_B_r, vga_B_w, vga_G_r, vga_G_w; 
logic state_r, state_w;
integer i, j;

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
assign active_x = counter_x_r < H_BLANK ? -1 : counter_x_r - H_BLANK;
assign active_y = counter_y_r < V_BLANK ? -1 : counter_y_r - V_BLANK;

// patterns
// logic [3:0] word_count_r [0:`ROW_CNT-1];
// logic [3:0] word_count_w [0:`ROW_CNT-1];
// logic [7:0] pattern_number_r [0:`ROW_CNT-1][0:`ROW_SIZE-1];
// logic [7:0] pattern_number_w [0:`ROW_CNT-1][0:`ROW_SIZE-1];

// pattern display test
// always_comb begin
//     for (i = 0; i < `ROW_CNT; i = i+1) begin
//         for (j = 0; j < `ROW_SIZE; j = j+1) begin
//             pattern_number_w[i][j] = 0;
//         end
//         word_count_w[i] = 0;
//     end
//     case(state_r)
//         S_IDLE: begin
//             for (i = 0; i < `ROW_CNT; i = i+1) begin
//                 for (j = 0; j < `ROW_SIZE; j = j+1) begin
//                     pattern_number_w[i][j] = 0;
//                 end
//                 word_count_w[i] = 0;
//             end
//         end
//         S_DISPLAY: begin
//             word_count_w[0] = 8;
//             word_count_w[1] = 10;
//             word_count_w[2] = 3;
//             pattern_number_w[0][0] = 8'd37;
//             pattern_number_w[0][1] = 8'd10;
//             pattern_number_w[0][2] = 8'd15;
//             pattern_number_w[0][3] = 8'd8;
//             pattern_number_w[0][4] = 8'd26;
//             pattern_number_w[0][5] = 8'd22;
//             pattern_number_w[0][6] = 8'd2;
//             pattern_number_w[0][7] = 8'd15;

//             pattern_number_w[1][0] = 8'd10;
//             pattern_number_w[1][1] = 8'd20;
//             pattern_number_w[1][2] = 8'd1;
//             pattern_number_w[1][3] = 8'd14;
//             pattern_number_w[1][4] = 8'd26;
//             pattern_number_w[1][5] = 8'd1;
//             pattern_number_w[1][6] = 8'd29;
//             pattern_number_w[1][7] = 8'd42;
//             pattern_number_w[1][8] = 8'd46;
//             pattern_number_w[1][9] = 8'd46;

//             pattern_number_w[2][0] = 8'd16;
//             pattern_number_w[2][1] = 8'd19;
//             pattern_number_w[2][2] = 8'd27;
//         end
//     endcase
// end

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
        counter_x_r <= 0;
        counter_y_r <= 0;
        hsync_r <= 1;
        vsync_r <= 1;
        state_r <= S_IDLE;
    end else begin
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
    .i_x_pos(active_x),
    .i_y_pos(active_y),
    .i_letter_cnt(i_letter_cnt),
    .i_letters(i_letters),
    .o_Blue(o_VGA_B),
    .o_Green(o_VGA_G),
    .o_Red(o_VGA_R)
);

endmodule