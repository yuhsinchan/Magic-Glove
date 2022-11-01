`timescale 1ns/10ps

module tb;

  AudDSP dsp0(
    .i_rst_n        (rst),
    .i_clk          (clk),
    .i_start        (start),
    .i_pause        (pause),
    .i_stop         (stop),
    .i_speed        (speed),
    .i_fast         (fast),
    .i_slow_0       (slow_0), // constant interpolation
    .i_slow_1       (slow_1), // linear interpolation
    .i_daclrck      (daclrck),
    .i_sram_data    (data),
    .i_end_addr     (end_addr),
    .o_dac_data     (out_data),
    .o_sram_addr    (next_addr)
  );

	initial begin
    
  end
  
  initial begin        
    $fsdbDumpfile("dsp.fsdb");
		$fsdbDumpvars;
    $display("reset dsp ...");
    
	end

  initial begin
		
	end

endmodule