module Top (
    input i_rst_n,
    input i_clk,
    input i_key_0,  // start
    input i_key_1,  // pause
    input i_key_2,  // stop
    input [2:0] i_speed,  // design how user can decide mode on your own
    input i_play_mode,  // 0: slow, 1: fast
    input i_slow_mode,
    input i_mode,  // 0: record, 1: play

    // AudDSP and SRAM
    output [19:0] o_SRAM_ADDR,
    inout  [15:0] io_SRAM_DQ,
    output        o_SRAM_WE_N,
    output        o_SRAM_CE_N,
    output        o_SRAM_OE_N,
    output        o_SRAM_LB_N,
    output        o_SRAM_UB_N,

    // I2C
    input  i_clk_100k,
    output o_I2C_SCLK,
    inout  io_I2C_SDAT,

    // AudPlayer
    input  i_AUD_ADCDAT,
    inout  i_AUD_ADCLRCK,
    inout  i_AUD_BCLK,
    inout  i_AUD_DACLRCK,
    output o_AUD_DACDAT,
    output [2:0] o_state,
    output [5:0] o_rec_time,
    output [3:0] o_progress

    // SEVENDECODER (optional display)
    // output [5:0] o_record_time,
    // output [5:0] o_play_time,

    // LCD (optional display)
    // input        i_clk_800k,
    // inout  [7:0] o_LCD_DATA,
    // output       o_LCD_EN,
    // output       o_LCD_RS,
    // output       o_LCD_RW,
    // output       o_LCD_ON,
    // output       o_LCD_BLON,

    // LED
    // output  [8:0] o_ledg,
    // output [17:0] o_ledr
);

    // design the FSM and states as you like
    parameter S_IDLE = 0;
    parameter S_I2C = 1;
    parameter S_RECD = 2;
    parameter S_RECD_PAUSE = 3;
    parameter S_PLAY = 4;
    parameter S_PLAY_PAUSE = 5;

    logic i2c_oen, i2c_sdat;
    logic [19:0] addr_record, addr_play;
    logic [19:0] addr_end_r, addr_end_w;
    logic [15:0] data_record, data_play, dac_data;

    logic [2:0] state_r, state_w;
    assign o_state = state_r;

    // for i2c
    logic i2c_start_r, i2c_start_w;
    logic i2c_finished;

    // for record
    logic rec_start_r, rec_start_w, rec_pause, rec_stop;

    // for output record time
    logic [5:0]  rec_time_r, rec_time_w;
    logic [23:0] rec_counter_r, rec_counter_w;

    assign rec_pause = (state_r == S_RECD_PAUSE) ? 1'b1 : 1'b0;
    assign rec_stop  = (state_r == S_IDLE) ? 1'b1 : 1'b0;
    assign o_rec_time = rec_time_r;

    // for play
    logic play_start_r, play_start_w, play_pause, play_stop, enable;
    logic mode_0, mode_1;
    logic dsp_finished;

    assign enable = (state_r == S_PLAY) ? 1'b1 : 1'b0;
    assign play_pause = (state_r == S_PLAY_PAUSE) ? 1'b1 : 1'b0;
    assign play_stop = (state_r == S_IDLE) ? 1'b1 : 1'b0;
    assign mode_0 = ((i_slow_mode == 0) ? 1'b1 : 1'b0) & (!i_play_mode);
    assign mode_1 = ((i_slow_mode == 1) ? 1'b1 : 1'b0) & (!i_play_mode);

    // for progress
    logic [3:0] progress_r, progress_w;
    assign o_progress = progress_r;


    assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

    assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
    assign io_SRAM_DQ = (state_r == S_RECD) ? data_record : 16'dz;  // sram_dq as output
    assign data_play = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0;  // sram_dq as input

    assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
    assign o_SRAM_CE_N = 1'b0;
    assign o_SRAM_OE_N = 1'b0;
    assign o_SRAM_LB_N = 1'b0;
    assign o_SRAM_UB_N = 1'b0;

    // below is a simple example for module division
    // you can design these as you like

    // === I2cInitializer ===
    // sequentially sent out settings to initialize WM8731 with I2C protocal
    I2cInitializer init0 (
        .i_rst_n(i_rst_n),
        .i_clk(i_clk_100k),
        .i_start(i2c_start_r),
        .o_finished(i2c_finished),
        .o_sclk(o_I2C_SCLK),
        .o_sdat(i2c_sdat),
        .o_oen(i2c_oen)  // you are outputing (you are not outputing only when you are "ack"ing.)
    );

    // === AudDSP ===
    // responsible for DSP operations including fast play and slow play at different speed
    // in other words, determine which data addr to be fetch for player 
    AudDSP dsp0 (
        .i_rst_n(i_rst_n),
        .i_clk(i_clk),
        .i_start(play_start_r),
        .i_pause(play_pause),
        .i_stop(play_stop),
        .i_speed(i_speed),
        .i_fast(i_play_mode),
        .i_slow_0(mode_0),  // constant interpolation
        .i_slow_1(mode_1),  // linear interpolation
        .i_daclrck(i_AUD_DACLRCK),
        .i_sram_data(data_play),
        .i_end_addr(addr_end_r),
        .o_dac_data(dac_data),
        .o_sram_addr(addr_play),
        .o_finished(dsp_finished)
    );

    // === AudPlayer ===
    // receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
    AudPlayer player0 (
        .i_rst_n(i_rst_n),
        .i_bclk(i_AUD_BCLK),
        .i_daclrck(i_AUD_DACLRCK),
        .i_en(enable),  // enable AudPlayer only when playing audio, work with AudDSP
        .i_dac_data(dac_data),  //dac_data
        .o_aud_dacdat(o_AUD_DACDAT)
    );

    // === AudRecorder ===
    // receive data from WM8731 with I2S protocal and save to SRAM
    AudRecorder recorder0 (
        .i_rst_n(i_rst_n),
        .i_clk(i_AUD_BCLK),
        .i_lrc(i_AUD_ADCLRCK),
        .i_start(rec_start_r),
        .i_pause(rec_pause),
        .i_stop(rec_stop),
        .i_data(i_AUD_ADCDAT),
        .o_address(addr_record),
        .o_data(data_record),
    );

    always_comb begin
        // design your control here
        state_w = state_r;
        i2c_start_w = i2c_start_r;
        rec_time_w = rec_time_r;
        rec_counter_w = rec_counter_r;
        rec_start_w = rec_start_r;
        play_start_w = play_start_r;
        progress_w = progress_r;
        addr_end_w = addr_end_r;

        case (state_r)
            S_IDLE: begin
                rec_counter_w = 24'd0;
                rec_time_w = 6'b0;
                if (i_mode == 1 & i_key_0 == 1) begin
                    state_w = S_PLAY;
                    play_start_w = 1'b1;
                end else if (i_mode == 0 & i_key_0 == 1) begin
                    state_w = S_RECD;
                    rec_start_w = 1'b1;
                end
            end

            S_I2C: begin
                if (i2c_finished) begin
                    i2c_start_w = 1'b0;
                    state_w = S_IDLE;
                end
            end

            S_RECD: begin
                rec_counter_w = rec_counter_r + 24'd1;
                if (rec_counter_r == 24'd12000000) begin
                    rec_counter_w = 24'b0;
                    rec_time_w = rec_time_r + 6'b1;
                end
                rec_start_w = 1'b0;
                if (i_key_1 == 1) begin
                    state_w = S_RECD_PAUSE;
                end else if (i_key_2 == 1) begin
                    addr_end_w = addr_record;
                    state_w = S_IDLE;
                end
            end

            S_RECD_PAUSE: begin
                if (i_key_0 == 1) begin
                    state_w = S_RECD;
                    rec_start_w = 1'b1;
                end else if (i_key_2 == 1) begin
                    addr_end_w = addr_record;
                    state_w = S_IDLE;
                end
            end

            S_PLAY: begin
                rec_counter_w = rec_counter_r + 24'd1;
                if (rec_counter_r == 24'd12000000) begin
                    rec_counter_w = 24'b0;
                    rec_time_w = rec_time_r + 6'b1;
                end
                play_start_w = 1'b0;
                if (dsp_finished) begin
                    state_w = S_IDLE;
                end

                if (i_key_1 == 1) begin
                    state_w = S_PLAY_PAUSE;
                end else if (i_key_2 == 1) begin
                    state_w = S_IDLE;
                end
            end

            S_PLAY_PAUSE: begin
                if (i_key_0 == 1) begin
                    state_w = S_PLAY;
                    play_start_w = 1'b1;
                end else if (i_key_2 == 1) begin
                    state_w = S_IDLE;
                end
            end
        endcase

        if (rec_counter_r <= 24'd0) begin
            progress_w = 0;
        end else if (rec_counter_r <= 24'd1500000) begin
            progress_w = 1; 
        end else if (rec_counter_r <= 24'd3000000) begin
            progress_w = 2; 
        end else if (rec_counter_r <= 24'd4500000) begin
            progress_w = 3; 
        end else if (rec_counter_r <= 24'd5000000) begin
            progress_w = 4; 
        end else if (rec_counter_r <= 24'd7500000) begin
            progress_w = 5; 
        end else if (rec_counter_r <= 24'd9000000) begin
            progress_w = 6; 
        end else if (rec_counter_r <= 24'd10500000) begin
            progress_w = 7; 
        end else if (rec_counter_r <= 24'd12000000) begin
            progress_w = 8;
        end

    end

    always_ff @(posedge i_AUD_BCLK or negedge i_rst_n) begin
        if (!i_rst_n) begin
            state_r <= S_I2C;
            i2c_start_r <= 1'b1;
            rec_start_r <= 1'b0;
            play_start_r <= 1'b0;
            rec_time_r <= 6'b0;
            rec_counter_r <= 24'b0;
            progress_r <= 4'b0;
            addr_end_r <= 20'b0;
        end else begin
            state_r <= state_w;
            i2c_start_r <= i2c_start_w;
            rec_start_r <= rec_start_w;
            play_start_r <= play_start_w;
            rec_time_r <= rec_time_w;
            rec_counter_r <= rec_counter_w;
            progress_r <= progress_w;
            addr_end_r <= addr_end_w;
        end
    end

endmodule
