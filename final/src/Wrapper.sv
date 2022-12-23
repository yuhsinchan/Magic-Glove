// display constant
`define ROW_CNT 3
`define ROW_SIZE 10
module Wrapper (
    input         avm_rst,
    input         avm_clk,
	input         i_start,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest,
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

localparam RX_BASE     = 0*4;
localparam STATUS_BASE = 2*4;
localparam RX_OK_BIT   = 7;
localparam WINDOW_PAD_ITER = 80; // after receiving 80 iterations(total 80 bytes), the window is filled, we can start feeding to the core
// 8*2 bytes

logic [2:0] state_r, state_w;
logic [6:0] counter_r, counter_w;
logic [4:0] avm_address_w, avm_address_r;
logic avm_read_r, avm_read_w;

// FSM
localparam S_FINISH = 0;
localparam S_QUERY_RX = 1;
localparam S_READ_ADV = 2;
localparam S_READ_MAIN = 3;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask

logic [15:0] read_seq_r [0:39];
logic [15:0] read_seq_w [0:39];
logic model_start_r, model_start_w;
logic model_next_input_r, model_next_input_w;
logic model_next_output;
logic model_finish;
logic [7:0] model_next_letter;
logic display_start;
logic [3:0] letter_count_r [0:`ROW_CNT-1];
logic [3:0] letter_count_w [0:`ROW_CNT-1];
logic [7:0] letters_r [0:`ROW_CNT-1][0:`ROW_SIZE-1];
logic [7:0] letters_w [0:`ROW_CNT-1][0:`ROW_SIZE-1];
logic [119:0] model_results;
integer i, j;


// RS232 transmission
always_comb begin
    model_start_w = model_start_r;
    model_next_input_w = model_next_input_r;
    case(state_r)
        S_IDLE: begin
            state_w = state_r;
            counter_w = 0;
        end
        S_QUERY_RX: begin
            if (~avm_waitrequest && avm_readdata[RX_OK_BIT] == 1) begin
                StartRead(RX_BASE);
                if (model_start_r) begin
                    state_w = S_READ_MAIN;
                end else begin
                    state_w = S_READ_ADV;
                end
                model_next_in = 0;
            end
        end
        S_READ_ADV: begin
            // read in advanced to fill the window
            if (~avm_waitrequest) begin
                StartRead(STATUS_BASE); 
                read_seq_w[counter_r>>1] = {read_seq_r[counter_r>>1][7:0], avm_readdata[7:0]};
                if (counter_r == WINDOW_PAD_ITER-1) begin
                    model_start_w = 1;
                    model_next_input_w = 1;
                end
                state_w = S_QUERY_RX;
                counter_w = counter_r < WINDOW_PAD_ITER - 1 ? counter_r + 1: 0;
            end
        end
        S_READ_MAIN: begin
            if (~avm_waitrequest) begin
                StartRead(STATUS_BASE);
                read_seq_w[counter_r>>1] = {read_seq_r[counter_r>>1][7:0], avm_readdata[7:0]};
                if (model_finish) begin
                    model_start_w = 0;
                end
                model_next_input_w = (counter_r & 4'b1111) == 0; // every 16 iterations
                state_w = S_QUERY_RX;
                counter_w = counter_r < WINDOW_PAD_ITER - 1 ? counter_r + 1: 0;
            end
        end
        default: begin
            state_w = state_r;
        end
    endcase
end

// VGA display
always_comb begin
    if (avm_rst) begin
        display_start = 0;
        for (i = 0; i < `ROW_CNT; i = i+1) begin
            for (j = 0; j < `ROW_SIZE; j = j + 1) begin
                letters_w[i][j] = 0;
            end
            letter_count_w[i] = 0;
        end
    end else begin
        display_start = 1;
        if (model_next_output_r) begin
            if (letter_count_r[0] == 0) begin
                letter_count_w[0] = 1;
                letters_w[0] = model_next_letter + 26; // capitalized
            end else begin
                for (i = 0; i < `ROW_CNT; i = i+1) begin
                    if (i == 0) begin
                        if (letter_count_r[i] < `ROW_SIZE) begin
                            letter_count_w[i] = letter_count_r[i] + 1;
                            letters_w[i][letter_count_r[i]] = model_next_letter;
                        end
                    end else begin
                        if (letter_count_r[i-1] == `ROW_SIZE && letter_count_r[i] < `ROW_SIZE) begin
                            letter_count_w[i] = letter_count_r[i] + 1;
                            letters_w[i][letter_count_r[i]] = model_next_letter;
                        end
                    end
                end
            end
        end else if (model_finish) begin
            for (i = 0; i < `ROW_CNT; i = i+1) begin
                
            end
        end
    end
end

always_ff @( posedge avm_clk or posedge avm_rst ) begin
    if (avm_rst) begin
        state_r <= S_IDLE;
        counter_r <= 0;
        for (i = 0; i < `ROW_CNT; i = i + 1) begin
            for (j = 0; j < `ROW_SIZE; j = j + 1) begin
                letters_r[i][j] <= 0;
            end
            letter_count_r[i] <= 0;
        end
    end else if (i_start) begin
        state_r <= S_QUERY_RX;
        counter_r <= counter_w;
        for (i = 0; i < `ROW_CNT; i = i + 1) begin
            for (j = 0; j < `ROW_SIZE; j = j + 1) begin
                letters_r[i][j] <= 0;
            end
            letter_count_r[i] <= 0;
        end
    end else begin
        state_r <= state_w;
        counter_r <= counter_w;
        for (i = 0; i < `ROW_CNT; i = i + 1) begin
            for (j = 0; j < `ROW_SIZE; j = j + 1) begin
                letters_r[i][j] <= letters_w[i][j];
            end
            letter_count_r[i] <= letter_count_w[i];
        end
    end
end

VGA_display vga(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(display_start),
    .i_letter_cnt(letter_count_r),
    .i_letters(letters_r),
    .o_VGA_B(o_VGA_B),
    .o_VGA_R(o_VGA_R),
    .o_VGA_G(o_VGA_G),
    .o_VGA_blank(o_VGA_blank),
    .o_VGA_HS(o_VGA_HS),
    .o_VGA_VS(o_VGA_VS),
    .o_VGA_sync(o_VGA_sync),
	.o_VGA_clk(o_VGA_clk)
);
// Core core(
//     .i_clk(),
//     .i_rst_n(),
//     .i_start(),
//     .i_data(),
//     .o_norm(),
//     .o_cnn(),
//     .o_logits(),
//     .o_finished()
// );

endmodule