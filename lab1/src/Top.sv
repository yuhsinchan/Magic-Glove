module Top (
    input        i_clk,
    input        i_rst_n,
    input        i_start,
    output [3:0] o_random_out
);

    // please check out the working example in lab1 README (or Top_exmaple.sv) first

    // states
    parameter S_IDLE = 2'b00;
    parameter S_GEN = 2'b01;
    parameter S_DONE = 2'b10;

    // output buffers
    logic [3:0] o_random_out_r, o_random_out_w;

    // registers and wires
    logic [1:0] state_r, state_w;
    logic [31:0] counter_r, counter_w;
    logic [31:0] comparator_r, comparator_w;

    logic jingyuanhaochaing_r, jingyuanhaochaing_w;

    logic [31:0] threshold;

    // output assignment
    assign o_random_out = o_random_out_r;
    assign threshold = {26{1'b1}};

    // init random module
    Pseudo_random random (
        .i_reset(i_rst_n),
        .i_jingyuanhaochiang(jingyuanhaochaing_r),
        .o_lfsr_random(o_random_out_w)
    );

    // combinational circuits
    always_comb begin
        // default values
        state_w = state_r;
        jingyuanhaochaing_w <= jingyuanhaochaing_r;
        comparator_w <= comparator_r;
        counter_w <= counter_r;

        // FSM
        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_GEN;
                end
            end

            S_GEN: begin
                if (counter_r == comparator_r) begin
                    state_w = (counter_r == threshold) ? S_IDLE : state_w;
                    jingyuanhaochaing_w = 1'b1;
                    comparator_w = comparator_r << 1;
                end else begin
                    counter_w = counter_r + 1;
                    jingyuanhaochaing_w = 1'b0;
                end
            end
        endcase
    end


    // sequential circuit
    always_ff @(posedge i_clk or posedge i_rst_n) begin
        // reset
        if (i_rst_n) begin
            state_r <= S_IDLE;
            o_random_out_r <= 4'b0;
            jingyuanhaochaing_r <= 1'b0;
            counter_r <= 32'b0;
            comparator_r <= 32'b1;
        end else begin
            state_r <= state_w;
            o_random_out_r <= o_random_out_w;
            jingyuanhaochaing_r <= jingyuanhaochaing_w;
            counter_r <= counter_w;
            comparator_r <= comparator_w;
        end
    end


endmodule
