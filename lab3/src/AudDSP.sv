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

    output [15:0]  o_dac_data,
    output [19:0]  o_sram_addr
);

    localparam IDLE  = 0; // stop  will reset the state to IDLE
    localparam PLAY  = 1; // start will   set the state to PLAY
    localparam PAUSE = 2; // pause will   set the state to PAUSE 
    
    localparam SP_NORMAL = 0;
    localparam SP_FAST   = 1;
    localparam SP_SLOW0  = 2;
    localparam SP_SLOW1  = 3;

    logic [1:0] state_w, state_r;
    logic [1:0] speed_state_w, speed_state_r;

    logic [2:0] sampling_counter_w, sampling_counter_r;
    
    logic signed [15:0] dac_data_w, dac_data_r;
    logic signed [15:0] pre_dac_data_w, pre_dac_data_r;
    logic        [19:0] sram_addr_w, sram_addr_r;
    

    assign o_dac_data = dac_data_r;
    assign o_sram_addr = sram_addr_r;
    assign o_sram_addr = sram_addr_r;


    always_comb begin
        state_w = state_r;
        speed_state_w = speed_state_r;
        sampling_counter_w =  sampling_counter_r;
        dac_data_w = dac_data_r;
        pre_dac_data_w = pre_dac_data_r;
        sram_addr_w = sram_addr_r;
        
        if (i_fast) begin
            speed_state_w = SP_FAST;
        end
        else if (i_slow0) begin
            speed_state_w = SP_SLOW0;
        end
        else if (i_slow1) begin
            speed_state_w = SP_SLOW1;
        end
        else begin
            speed_state_w = SP_NORMAL;
        end
        
        case (state_r)         
            IDLE: begin
                if (i_start) begin
                    state_w = PLAY;
                end
            end
            PLAY: begin
                pre_dac_data_w = dac_data_r;
                
                if (i_stop) begin
                    state_w = IDLE;
                end
                else if (i_pause) begin
                    state_w = PAUSE;
                end
                else begin
                    case (speed_state_r)
                        SP_NORMAL: begin
                            dac_data_w = $signed(i_sram_data);
                            sram_addr_w = sram_addr_r + 19'd1; 
                        end
                        SP_FAST: begin
                            // down sampling
                            dac_data_w = $signed(i_sram_data);
                            sram_addr_w = sram_addr_r + {17'b0, (i_speed + 3'd1)}; 
                        end
                        SP_SLOW0: begin
                            // up sampling: piecewise-constant interpolation
                            sampling_counter_w = sampling_counter_r + 3'd1;
                            dac_data_w = $signed(pre_dac_data_r);
                            if (sampling_counter_r = i_speed) begin
                                sampling_counter_w = 3'd0;
                                sram_addr_w = sram_addr_r + 19'd1;
                            end
                        end
                        SP_SLOW1: begin
                            // up sampling: linear interpolation
                            sampling_counter_w = sampling_counter_r + 3'd1;
                            dac_data_w = $signed( $signed(dac_data_r - pre_dac_data_r) / $signed(i_speed - sampling_counter_r)) + $signed(pre_dac_data_r);
                            if (sampling_counter_r = i_speed) begin
                                
                            end
                        end
                    endcase
                end
            end
            PAUSE: begin    
                o_dac_data_w = 15'b0;
                if (i_stop) begin
                    state_w = IDLE;
                end
                else if (i_start) begin
                    state_w = PLAY;
                end
            end
            default: begin
                out_dac_data = 15'b0;
            end
        endcase
    end

    always_ff @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // reset
            state_r <= 0;
            speed_state_r <= 0;
            sampling_counter_r <= 0;
            dac_data_r <= 0;
            pre_dac_data_r <= 0;
            sram_addr_r <= 1;
        end else begin
            state_r <= state_w;
            speed_state_r <= speed_state_w;
            sampling_counter_r <=  sampling_counter_w;
            dac_data_r <= dac_data_w;
            pre_dac_data_r <= pre_dac_data_w;
            sram_addr_r <= sram_addr_w;
        end
    end

endmodule
