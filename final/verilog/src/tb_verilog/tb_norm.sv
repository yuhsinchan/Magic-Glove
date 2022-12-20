`timescale 1ns/100ps

module tb;
  localparam CLK = 10;
  localparam HCLK = CLK / 2;
  localparam SF = 2.0 ** -8.0;
  
  logic clk;
  logic [15:0] data, mean, std, norm;
  
  initial clk = 0;
  always #HCLK clk = ~clk;
  // logic [23:0] fx_point;
  
  Normalize Norm(
    .i_data(data),
    .i_mean(mean),
    .i_std(std),
    .o_norm(norm)
  );
  
  initial begin
    data = -69;
    mean = 7;
    std = 3;
    
    $display("data: %0d", $signed(data));
    $display("mean: %0d", mean);
    $display("std: %0d", std);
    
    /*
    data = data - mean;
    $display("data - mean: %0d", $signed(data));
    $display("data - mean: %0b", data);
    
    fx_point = {data, 8'b0};
    
    $display("fx_point: %0b", fx_point);
    
    fx_point = ($signed(fx_point) > 0) ? (fx_point / std) : -(-fx_point / std);
    */
    @(posedge clk);
    $display("norm: %b", norm);
    $display("norm: %f", $itor($signed(norm) * SF));
    $finish;
  end
endmodule
