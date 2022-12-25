`timescale 1ns/100ps

module tb;
  localparam CLK = 10;
  localparam HCLK = CLK / 2;
  localparam SF = 2.0 ** -8.0;
  
  logic clk;
  logic [15:0] data1, data2;
  logic [23:0] result;
  logic [31:0] product;
  
  initial clk = 0;
  always #HCLK clk = ~clk;
  // logic [23:0] fx_point;
  
  initial begin
    data1 = -16'h55a6;
    data2 = 16'h4af0;
    
    $display("data1: %f", $itor($signed(data1) * SF));
    $display("data2: %f", $itor($signed(data2) * SF));

    $display("data1: %b", data1);
    $display("data2: %b", data2);

    product = ($signed(data1) * $signed(data2));

    $display("product: %b", product);

    result = product[31:8];
    
    $display("result: %b", result);
    
    /*
    data = data - mean;
    $display("data - mean: %0d", $signed(data));
    $display("data - mean: %0b", data);
    
    fx_point = {data, 8'b0};
    
    $display("fx_point: %0b", fx_point);
    
    fx_point = ($signed(fx_point) > 0) ? (fx_point / std) : -(-fx_point / std);
    */
    // @(posedge clk);
    $display("result: %f", $itor($signed(result) * SF));
    $finish;
  end
endmodule
