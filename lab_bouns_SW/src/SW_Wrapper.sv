
`define REF_MAX_LENGTH              128
`define READ_MAX_LENGTH             128

`define REF_LENGTH                  128
`define READ_LENGTH                 128

//* Score parameters
`define DP_SW_SCORE_BITWIDTH        10

`define CONST_MATCH_SCORE           1
`define CONST_MISMATCH_SCORE        -4
`define CONST_GAP_OPEN              -6
`define CONST_GAP_EXTEND            -1

module SW_Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
// Follow the finite state machine on pages 25.
localparam S_QUERY_RX = 0;
localparam S_READ = 1;
localparam S_CALC = 2;
localparam S_QUERY_TX = 3;
localparam S_WRITE = 4;

// local paramenters
logic [2:0] state_r, state_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic [247:0] result_r, result_w;
logic [4:0] avm_address_w, avm_address_r;
logic avm_read_r, avm_read_w;
logic avm_write_r, avm_write_w;


// module output assignment
assign avm_writedata = result_r[247-:8];
assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;

// parameters communicating with core
logic [2*`REF_MAX_LENGTH-1:0] ref_r, ref_w;
logic [2*`READ_MAX_LENGTH-1:0] read_r, read_w;
logic [$clog2(`REF_MAX_LENGTH):0] ref_length_r;
logic [$clog2(`READ_MAX_LENGTH):0] read_length_r;
logic signed [`DP_SW_SCORE_BITWIDTH-1:0] alignment_score;
logic [$clog2(`REF_MAX_LENGTH)-1:0] column;
logic [$clog2(`READ_MAX_LENGTH)-1:0] row;
logic core_read_ready_w, core_write_ready_w;
logic wrapper_read_ready_w, wrapper_write_ready_w, wrapper_read_ready_r, wrapper_write_ready_r;

// Remember to complete the port connection
SW_core sw_core(
    .clk				(avm_clk),
    .rst				(avm_rst),

	.o_ready			(core_read_ready_w),
    .i_valid			(wrapper_read_ready_r),
    .i_sequence_ref		(ref_r),
    .i_sequence_read	(read_r),
    .i_seq_ref_length	(ref_length_r),
    .i_seq_read_length	(read_length_r),
    
    .i_ready			(wrapper_write_ready_r),
    .o_valid			(core_write_ready_w),
    .o_alignment_score	(alignment_score),
    .o_column			(column),
    .o_row				(row)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

// TODO
always_comb begin
    state_w = state_r;
    bytes_counter_w = bytes_counter_r;
    wrapper_read_ready_w = wrapper_read_ready_r;
    wrapper_write_ready_w = wrapper_write_ready_r;

    avm_address_w = avm_address_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;

    ref_w = ref_r;
    read_w = read_r;

    result_w = result_r;
    case (state_r) 
        S_QUERY_RX: begin
            if (~avm_waitrequest && avm_readdata[RX_OK_BIT] == 1) begin
                StartRead(RX_BASE);
                state_w = S_READ;
                bytes_counter_w = bytes_counter_r + 1;
            end else begin
                StartRead(STATUS_BASE);
            end
        end
        S_READ: begin
            if (~avm_waitrequest) begin
                StartRead(STATUS_BASE);
                if (bytes_counter_r <= (`REF_MAX_LENGTH >> 2)) begin
                    // reference sequence
                    state_w = S_QUERY_RX;
                    ref_w = {ref_r[2*`REF_MAX_LENGTH-9:0], avm_readdata[7:0]};
                    wrapper_read_ready_w = 0;
                end
                else if (bytes_counter_r < ((`READ_MAX_LENGTH + `REF_MAX_LENGTH) >> 2)) begin
                    // read sequence
                    state_w = S_QUERY_RX;
                    read_w = {read_r[2*`READ_MAX_LENGTH-9:0], avm_readdata[7:0]};
                    wrapper_read_ready_w = 0;
                end
                else begin
                    // finished
                    state_w = S_CALC;
                    read_w = {read_r[2*`READ_MAX_LENGTH-9:0], avm_readdata[7:0]};
                    bytes_counter_w = 0;
                    wrapper_read_ready_w = 1;
                    avm_read_w = 0;
                end
            end
        end
        S_CALC: begin
            if (core_write_ready_w) begin
                if (~wrapper_write_ready_r) begin
                    wrapper_write_ready_w = 1;
                end else begin
                    result_w[`DP_SW_SCORE_BITWIDTH-1-:`DP_SW_SCORE_BITWIDTH] = alignment_score;
                    result_w[63+$clog2(`READ_MAX_LENGTH)-:$clog2(`READ_MAX_LENGTH)] = row;
                    result_w[127+$clog2(`REF_MAX_LENGTH)-:$clog2(`REF_MAX_LENGTH)] = column;
                    state_w = S_QUERY_TX;
                    wrapper_write_ready_w = 0;
                end
            end
        end
        S_QUERY_TX: begin
            if (~avm_waitrequest && avm_readdata[TX_OK_BIT] == 1) begin
                StartWrite(TX_BASE);
                state_w = S_WRITE;
                bytes_counter_w = bytes_counter_r + 1;
            end else begin
                StartRead(STATUS_BASE);
            end
        end
        S_WRITE: begin
            if (~avm_waitrequest) begin
                StartRead(STATUS_BASE);
                if (bytes_counter_r == 31) begin
                    bytes_counter_w = 0;
                    state_w = S_QUERY_RX;
                    avm_write_w = 0;
                end else begin
                    state_w = S_QUERY_TX;
                    result_w = {result_r[239:0], result_r[247:240]};    
                end
            end
        end
        default: begin

        end
    endcase
end

// TODO
always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
    	ref_r <= 0;
        read_r <= 0;
        wrapper_read_ready_r <= 0;
        wrapper_write_ready_r <= 0;
        state_r <= S_QUERY_RX;
        bytes_counter_r <= 0;
        result_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        ref_length_r <= `REF_LENGTH;
        read_length_r <= `READ_LENGTH;
    end
	else begin
    	ref_r <= ref_w;
        read_r <= read_w;
        wrapper_read_ready_r <= wrapper_read_ready_w;
        wrapper_write_ready_r <= wrapper_write_ready_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        result_r <= result_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
    end
end

endmodule
