module AudRecorder (
    input i_rst_n,
    input i_clk,
    input i_lrc,
    input i_start,
    input i_pause,
    input i_stop,
    input i_data,
    output [19:0] o_address,
    output [15:0] o_data
);

    parameter S_IDLE = 0;
    parameter S_PREP = 1;
    parameter S_WAIT = 2;
    parameter S_RECD = 3;
    parameter S_DONE = 4;

    logic [2:0] state_r, state_w;
    logic [19:0] address_r, address_w;
    logic [15:0] rec_data_r, rec_data_w;
    logic [15:0] data_r, data_w;
    logic [4:0] counter_r, counter_w;

    logic start_rec;

    assign o_address = address_r;
    assign o_data = data_r;

    always_comb begin
        state_w = state_r;
        address_w = address_r;
        rec_data_w = rec_data_r;
        data_w = data_r;
        counter_w = counter_r;

        case (state_r)
            S_IDLE: begin
                counter_w = 0;
                if (i_start) begin
                    if (!i_lrc) begin
                        state_w = S_PREP;
                    end
                end
            end
            S_PREP: begin
                if (i_lrc) begin
                    state_w = S_WAIT;
                end
            end
            S_WAIT: begin
                if (!i_lrc) begin
                    state_w = S_RECD;
                end
            end
            S_RECD: begin
                if (counter_r < 16) begin
                    rec_data_w = {rec_data_r[14:0], i_data};
                    counter_w  = counter_r + 1;
                end else begin
                    state_w = S_DONE;
                end
            end
            S_DONE: begin
                data_w = rec_data_r;
                if (i_stop) begin
                    address_w = 0;
                    state_w   = S_IDLE;
                end else if (i_pause) begin
                    address_w = address_r + 1;
                    state_w   = S_IDLE;
                end else begin
                    address_w = address_r + 1;
                    state_w   = S_PREP;
                end
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            address_r <= 20'b0;
            rec_data_r <= 16'b0;
            data_r <= 16'b0;
            counter_r <= 5'b0;
        end else begin
            state_r <= state_w;
            address_r <= address_w;
            rec_data_r <= rec_data_w;
            data_r <= data_w;
            counter_r <= counter_w;
        end
    end

endmodule
