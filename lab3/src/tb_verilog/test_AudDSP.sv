// `timescale 1ns/10ps

module tb;
  localparam CLK = 10;
	localparam HCLK = CLK/2;

  localparam DACLRCK = 160;
	localparam BIG_HCLK = DACLRCK/2;


  logic        rst;
  logic        clk;
  logic        start;
  logic        pause;
  logic        stop;
  logic [2:0]  speed;
  logic        fast;
  logic        slow_0;
  logic        slow_1;
  logic        daclrck;
  logic [15:0] cur_data;
  logic [15:0] sram_data [0:15]; // 8 data each 16 bits
  logic [15:0] out_data;
  logic [19:0] next_addr;
  
  initial clk = 0;
	always #HCLK clk = ~clk;
  initial daclrck = 0;
  always #BIG_HCLK daclrck = ~daclrck;

  AudDSP dsp0(
    .i_rst_n(rst),
    .i_clk(clk),
    .i_start(start),
    .i_pause(pause),
    .i_stop(stop),
    .i_speed(speed),
    .i_fast(fast),
    .i_slow_0(slow_0), // constant interpolation
    .i_slow_1(slow_1), // linear interpolation
    .i_daclrck(daclrck),
    .i_sram_data(cur_data),
    .o_dac_data(out_data),
    .o_sram_addr(next_addr)
  );

  initial begin
    for (int i = 0; i < 16; i = i + 1) begin
      sram_data[i] = i * 32;
    end
  end

  
  initial begin        
    $fsdbDumpfile("lab3_dsp.fsdb");
		$fsdbDumpvars;
    $display("START DEBUG");
    
    start  <= 0;
    pause  <= 0;
    stop   <= 0;
    speed  <= 3;
    fast   <= 0;
    slow_0 <= 0;
    slow_1 <= 1;
    rst    <= 1;
    cur_data = sram_data[0];


		#(2*CLK)
		rst <= 0;
    @(posedge clk) rst <= 1;

    start <= 1;
    #(CLK)
    start <= 0;
    
    $display("=========");
    $display("data[%2d]  = %2d", 0, cur_data);
    @(posedge daclrck) begin
      $display("out_data  = %2d", out_data);
      $display("next_addr = %2d", next_addr);
    end
    
    do begin
      cur_data = sram_data[next_addr];
      $display("=========");
      $display("data[%2d]  = %2d", next_addr, cur_data);
      @(posedge daclrck) begin
        $display("out_data  = %2d", out_data);
        $display("next_addr = %2d", next_addr);
      end
    end while (next_addr <= 3);
    $finish;
	end

  initial begin
		#(500000*CLK)
		$display("Too Slow, Abort");
		$finish;
	end


endmodule