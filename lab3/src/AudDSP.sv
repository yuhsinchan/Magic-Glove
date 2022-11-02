module AudDSP (
    input          i_rst_n,
    input          i_clk,
    input          i_start,
    input          i_pause,
    input          i_stop,
    input   [2:0]  i_speed, // 0 ~ 7 map to speed of x1 ~ x8
    input          i_fast,
    input          i_slow_0,  // constant interpolation
    input          i_slow_1,  // linear interpolation
    input          i_daclrck, // 0 for left channel, 1 for right channel
    input  [15:0]  i_sram_data,
    input  [19:0]  i_end_addr,

    output [15:0]  o_dac_data,
    output [19:0]  o_sram_addr,
    output         o_finished
);

    localparam IDLE  = 0; // stop  will reset the state to IDLE
    localparam PLAY  = 1; // start will   set the state to PLAY
    localparam PAUSE = 2; // pause will   set the state to PAUSE
    localparam WAIT  = 3;
    
    localparam SP_NORMAL = 0;
    localparam SP_FAST   = 1;
    localparam SP_SLOW0  = 2;
    localparam SP_SLOW1  = 3;

    logic finished_w, finished_r;
    assign o_finished = finished_r;

    logic [1:0] state_w, state_r;
    logic [1:0] speed_state_w, speed_state_r;

    logic [2:0] sampling_counter_w, sampling_counter_r;
    
    logic signed [15:0] dac_data_w, dac_data_r;
    logic signed [15:0] pre_dac_data_w, pre_dac_data_r;
    logic        [19:0] sram_addr_w, sram_addr_r;

    logic daclrck_w, daclrck_r;
    logic posedge_daclrck;    

    assign o_dac_data  = dac_data_r;
    assign o_sram_addr = sram_addr_r;
    assign posedge_daclrck = i_daclrck & ~daclrck_r;


    always_comb begin
        state_w            = state_r;
        speed_state_w      = speed_state_r;
        sampling_counter_w = sampling_counter_r;
        dac_data_w         = dac_data_r;
        pre_dac_data_w     = pre_dac_data_r;
        sram_addr_w        = sram_addr_r;
        daclrck_w          = daclrck_r;
        finished_w         = finished_r;
        
        daclrck_w = i_daclrck;
        if (i_fast) begin
            speed_state_w = SP_FAST;
        end
        else if (i_slow_0) begin
            speed_state_w = SP_SLOW0;
        end
        else if (i_slow_1) begin
            speed_state_w = SP_SLOW1;
        end
        else begin
            speed_state_w = SP_NORMAL;
        end
        
        case (state_r)         
            IDLE: begin
                finished_w = 1'b0;
                if (i_start) begin
                    state_w = WAIT;
                end
            end
            PLAY: begin
                // $display("PLAY");
                case (speed_state_r)
                    SP_NORMAL: begin
                        // $display("Normal");
                        dac_data_w = $signed(i_sram_data);
                        sram_addr_w = sram_addr_r + 20'b1; 
                    end
                    SP_FAST: begin
                        // $display("Fast");
                        // down sampling
                        dac_data_w = $signed(i_sram_data);
                        if (i_speed <= 3'd6) begin
                            sram_addr_w = sram_addr_r + {17'b0, (i_speed + 3'b1)};
                        end else begin
                            sram_addr_w = sram_addr_r + {16'b0, 4'b1000};
                        end

                    end
                    SP_SLOW0: begin
                        // $display("Slow0");
                        // up sampling: piecewise-constant interpolation
                        dac_data_w = $signed(pre_dac_data_r);
                        sampling_counter_w = sampling_counter_r + 3'b1;
                        if (sampling_counter_r == i_speed) begin
                            sampling_counter_w = 3'b0;
                            sram_addr_w = sram_addr_r + 20'b1;
                            pre_dac_data_w = $signed(i_sram_data);
                        end
                    end
                    SP_SLOW1: begin
                        // $display("Slow1");
                        // up sampling: linear interpolation
                        dac_data_w = $signed( $signed(i_sram_data - pre_dac_data_r) * $signed({13'b0, sampling_counter_r}) / $signed({12'b0, i_speed} + 15'b1) ) + $signed(pre_dac_data_r);
                        sampling_counter_w = sampling_counter_r + 3'b1;
                        if (sampling_counter_r == i_speed) begin
                            sampling_counter_w = 3'b0;
                            sram_addr_w = sram_addr_r + 20'b1;
                            pre_dac_data_w = $signed(i_sram_data);
                        end
                    end
                endcase

                if (sram_addr_r >= i_end_addr) begin
                    state_w = IDLE;
                    sram_addr_w = 20'b1;
                    finished_w = 1'b1;
                end
                else if (i_stop) begin
                    state_w = IDLE;
                    sram_addr_w = 20'b1;
                end
                else if (i_pause) begin
                    state_w = PAUSE;
                end else begin
                    state_w = WAIT;
                end
            end
            PAUSE: begin    
                dac_data_w = 16'b0;
                if (i_stop) begin
                    state_w = IDLE;
                    sram_addr_w = 20'b1;
                end
                else if (i_start) begin
                    state_w = PLAY;
                end
            end
            WAIT: begin
                if (posedge_daclrck) begin
                    state_w = PLAY;
                end
            end
            default: begin
                dac_data_w = 16'b0;
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // reset
            // $display("RESTART");
            state_r            <= IDLE;
            speed_state_r      <= SP_NORMAL;
            sampling_counter_r <= 3'b0;
            dac_data_r         <= 16'b0;
            pre_dac_data_r     <= 16'b0;
            sram_addr_r        <= 20'b1;
            daclrck_r 	       <= i_daclrck;
            finished_r         <= 1'b0;
        end else begin
            state_r            <= state_w;
            speed_state_r      <= speed_state_w;
            sampling_counter_r <= sampling_counter_w;
            dac_data_r         <= dac_data_w;
            pre_dac_data_r     <= pre_dac_data_w;
            sram_addr_r        <= sram_addr_w;
            daclrck_r   	   <= daclrck_w;
            finished_r         <= finished_w;
        end
    end

endmodule
