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
    parameter S_PLAY = 2;

    logic [1:0] state_r, state_w;
    logic [3:0] counter_r, counter_w;
    logic [15:0] dac_data_r, dac_data_w;
	logic lrc_r, lrc_w;

    assign o_aud_dacdat = dac_data_r[15];

    always_comb begin
        state_w = state_r;
        dac_data_w = dac_data_r;
        counter_w = counter_r;
		lrc_w = i_daclrck;

        case (state_r)
            S_IDLE: begin
                counter_w = 4'b0;
                if (i_en) begin
					state_w = S_PREP;
                end
            end
            S_PREP: begin
                if (lrc_r != lrc_w) begin
					dac_data_w = i_dac_data;
                    state_w = S_PLAY;
                end
            end
            S_PLAY: begin
                if (counter_r == 15) begin
                    state_w = S_IDLE;
                end
				dac_data_w = dac_data_r << 1;
                counter_w = counter_r + 1'b1;
            end
        endcase
    end


    always_ff @(negedge i_bclk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_IDLE;
            dac_data_r <= 16'b0;
            counter_r <= 3'b0;
			lrc_r <= i_daclrck;
        end else begin
            state_r <= state_w;
            dac_data_r <= dac_data_w;
            counter_r <= counter_w;
			lrc_r <= lrc_w;
        end
    end
endmodule