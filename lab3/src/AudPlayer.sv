module AudPlayer (
    input i_rst_n,
    input i_bclk,
    input i_daclrck,
    input i_en,  // enable AudPlayer only when playing audio, work with AudDSP
    input [15:0] i_dac_data,  //dac_data
    output o_aud_dacdat
);

    parameter S_IDLE = 0;
    parameter S_PREP = 1;
    parameter S_WAIT = 2;
    parameter S_PLAY = 3;
    parameter S_DONE = 4;

    logic [3:0] state_r, state_w;
    logic [5:0] counter_r, counter_w;
    logic [15:0] dac_data_r, dac_data_w;
    logic aud_data_r, aud_data_w;

    assign o_aud_dacdat = aud_data_r;

    always_comb begin
        state_w = state_r;
        dac_data_w = dac_data_r;
        aud_data_w = aud_data_r;

        case (state_r)
            S_IDLE: begin
                counter_w = 0;
                if (i_en) begin
                    if (!i_daclrck) begin
                        state_w = S_PREP;
                    end else begin
                        state_w = S_WAIT;
                    end
                end
            end
            S_PREP: begin
                if (i_daclrck) begin
                    state_w = S_WAIT;
                end
            end
            S_WAIT: begin
                if (!i_bclk) begin
                    state_w = S_PLAY;
                end
            end
            S_PLAY: begin
                if (counter_r == 15) begin
                    state_w = S_DONE;
                end
                aud_data_w = dac_data_r[15];
                dac_data_w = dac_data_r << 1;
                counter_w  = counter_r + 1;
            end
            S_DONE: begin
                if (i_en) begin
                    state_w = S_PREP;
                end else begin
                    state_w = S_IDLE;
                end
            end
        endcase
    end


    always_ff @(posedge i_bclk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            dac_data_r <= 16'b0;
            aud_data_r <= 1'b0;
            counter_r <= 5'b0;
        end else begin
            state_r <= state_w;
            dac_data_r <= dac_data_w;
            aud_data_r <= aud_data_w;
            counter_r <= counter_w;
        end
    end


endmodule
