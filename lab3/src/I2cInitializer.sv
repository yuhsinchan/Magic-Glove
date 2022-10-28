module I2cInitializer (
    input i_rst_n,
    input i_clk,
    input i_start,
    output o_finished,
    output o_sclk,
    output o_sdat,
    output o_oen  // you are outputing (you are not outputing only when you are "ack"ing.)
);
    localparam data_num = 7;
    localparam [data_num * 24 - 1:0] setup_data = {
        24'b001101000001111000000000,
        24'b001101000000100000010101,
        24'b001101000000101000000000,
        24'b001101000000110000000000,
        24'b001101000000111001000010,
        24'b001101000001000000011001,
        24'b001101000001001000000001
    };

    parameter S_IDLE = 0;
    parameter S_PROC = 1;
    parameter S_NEXT = 2;
    parameter S_DONE = 3;

    logic [1:0] state_r, state_w;
    logic [3:0] counter_r, counter_w;
    logic [23:0] data_r, data_w;
    logic start_r, start_w;
    logic finished_w, finished_r;

    logic scl;
    logic sda;
    logic ack;

    assign o_sclk = scl;
    assign o_sdat = sda;
    assign o_oen  = !ack;

    I2C i2c (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_start(start_r),
        .i_data(data_r),
        .o_finished(finished),
        .o_scl(scl),
        .o_sda(sda),
        .o_ack(ack)
    );


    always_comb begin
        data_w = data_r;
        finished_w = finished_r;
        state_w = state_r;
        counter_w = counter_r;
        start_w = start_r;

        case (state_r)
            S_IDLE: begin
                if (i_start) begin
                    state_w = S_PROC;
                    counter_w = 3'd1;
                    data_w = setup_data[23:0];
                    start_w = 1'b1;
                end
            end
            S_PROC: begin
                start_w = 1'b0;
                if (finished) begin
                    if (counter_r == data_num) begin
                        state_w = S_DONE;
                    end else begin
                        state_w = S_NEXT;
                    end
                end
            end
            S_NEXT: begin
                counter_w = counter_r + 1;
                data_w = setup_data[(counter_r+1)*24-1:counter_r*24];
                start_w = 1'b1;
            end
            S_DONE: begin
                finished_w = 1'b1;
                state_w = S_IDLE;
            end

        endcase

    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            counter_r <= 3'd0;
            data_r <= 24'b0;
            start_r <= 1'b0;
            finished_r <= 1'b0;
        end else begin
            state_r <= state_w;
            counter_r <= counter_w;
            data_r <= data_w;
            start_r <= start_w;
            finished_r <= finished_w;
        end
    end

endmodule

module I2C (
    input i_rst_n,
    input i_clk,
    input i_start,
    input [23:0] i_data,
    output o_finished,
    output o_sclk,
    output o_sdat,
    output o_ack
);

    parameter S_IDLE = 0;
    parameter S_INIT = 1;
    parameter S_SDAT = 2;
    parameter S_ACK = 3;
    parameter S_COMPLETE = 4;

    logic [23:0] data_r, data_w;
    logic [3:0] state_r, state_w;
    logic [3:0] counter_r, counter_w;
    logic [4:0] left_r, left_w;
    logic ack_r, ack_w;
    logic finished_r, finished_w;

    logic sda_r, sda_w;
    logic scl_r, scl_w;
    logic ack_r, ack_w;

    assign o_sclk = scl_r;
    assign o_sdat = sda_r;
    assign o_ack = ack_r;
    assign o_finished = finished_r;


    always_comb begin
        data_w = data_r;
        state_w = state_r;
        counter_w = counter_r;
        ack_w = ack_r;

        case (state_r)
            S_INIT: begin
                sda_w   = 1'b0;
                scl_w   = 1'b1;
                state_w = S_SDAT;
            end

            S_SDAT: begin
                if (scl_r == 0) begin
                    scl_w  = 1'b1;
                    data_w = data_r << 1;
                    left_w = left_r - 1;
                end else if (counter_r == 7) begin
                    sda_w = 1'bZ;
                    scl_w = 1'b0;
                    state_w = S_ACK;
                    counter_w = 3'b0;
                    ack_w = 1'b1;
                end else if (left_r > 0) begin
                    sda_w = data_r[0];
                    scl_w = 1'b0;
                    counter_w = counter_r + 1;
                    ack_w = 1'b0;
                end else begin
                    sda_w   = 1'b0;
                    ack_w   = 1'b0;
                    state_w = S_COMPLETE;
                end
            end

            S_ACK: begin
                scl_w   = 1'b1;
                state_w = S_SDAT;
            end

            S_COMPLETE: begin
                if (scl_r == 0) begin
                    scl_w = 1'b1;
                end else begin
                    sda_w = 1'b1;
                    state_w = S_IDLE;
                    finished_w = 1'b1;
                end
            end

            default: begin
                sda_w   = 1'b1;
                scl_w   = 1'b1;
                state_w = S_IDLE;
            end

        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            data_r <= i_data;
            state_r <= S_IDLE;
            ack_r <= 1'b0;
            counter_r <= 3'b000;
            scl_r <= 1'b1;
            sda_r <= 1'b1;
            ack_r <= 1'b0;
            left_r <= 5'd0;
            finished_r <= 1'b0;
        end else if (i_start) begin
            data_r <= i_data;
            state_r <= S_INIT;
            ack_r <= ack_w;
            counter_r <= 3'b000;
            scl_r <= 1'b1;
            sda_r <= 1'b1;
            ack_r <= 1'b0;
            left_r <= 5'd24;
            finished_r <= 1'b0;
        end else begin
            data_r <= data_w;
            state_r <= state_w;
            ack_r <= ack_w;
            counter_r <= counter_w;
            scl_r <= scl_w;
            sda_r <= sda_w;
            ack_r <= ack_w;
            left_r <= left_w;
            finished_r <= finished_w;
        end
    end

endmodule
