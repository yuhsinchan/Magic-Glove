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
    parameter threshold = {24{1'b1}};
    parameter incre = {20{1'b1}};

    // output buffers
    logic [3:0] o_random_out_r, o_random_out_w;

    // registers and wires
    logic [1:0] state_r, state_w;
    logic [31:0] counter_r, counter_w;
    logic [31:0] comparator_r, comparator_w;

    logic [31:0] x_r, x_w;
    logic [31:0] interval_r, interval_w;

    logic jingyuanhaochaing_r, jingyuanhaochaing_w;

    // output assignment
    assign o_random_out = o_random_out_r;

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
        jingyuanhaochaing_w = jingyuanhaochaing_r;
        comparator_w = comparator_r;
        counter_w = counter_r;
        interval_w = interval_r;
        x_w = x_r;

        // FSM
        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_GEN;
                end
            end

            S_GEN: begin
                if (counter_r == comparator_r) begin
                    state_w = (interval_r >= threshold) ? S_DONE : state_w;
                    jingyuanhaochaing_w = 1'b1;
                    comparator_w = comparator_r + interval_r;
                    x_w = x_r + 1 << 18;
                    interval_w = interval_r + x_r * 2;
                end else begin
                    counter_w = counter_r + 1;
                    jingyuanhaochaing_w = 1'b0;
                end
            end

            S_DONE: begin
                counter_w = 32'b0;
                comparator_w = 32'b0;
                state_w = S_IDLE;
                interval_w = 32'b0;
                x_w = {20{1'b1}};
            end
        endcase
    end


    // sequential circuit
    always_ff @(posedge i_clk or negedge i_rst_n) begin
        // reset
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            o_random_out_r <= 4'b0;
            jingyuanhaochaing_r <= 1'b0;
            counter_r <= 32'b0;
            comparator_r <= 32'b1;
            interval_r <= 32'b0;
            x_r <= {20{1'b1}};
        end else begin
            state_r <= state_w;
            if (state_w == S_GEN) begin
                o_random_out_r <= o_random_out_w;
            end
            jingyuanhaochaing_r <= jingyuanhaochaing_w;
            counter_r <= counter_w;
            comparator_r <= comparator_w;
            interval_r <= interval_w;
            x_r <= x_w;
        end
    end


endmodule
