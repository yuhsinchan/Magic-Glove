`timescale 1ns/100ps

module tb;
  localparam CLK = 10;
  localparam HCLK = CLK / 2;
  localparam SF = 2.0 ** -8.0;

  localparam [15:0] cnn_weight [0:23] = '{
    -16'h13b2,
    -16'h15cb,
    -16'h1b00,
    16'h2c69,
    16'h2c30,
    16'h2c5e,
    -16'h0b70,
    -16'h0354,
    16'h0385,
    -16'h2905,
    -16'h2852,
    -16'h28ef,
    16'h2051,
    16'h2058,
    16'h1f30,
    -16'h2937,
    -16'h2966,
    -16'h2986,
    -16'h009b,
    -16'h0089,
    -16'h0019,
    16'h1936,
    16'h18cb,
    16'h1810
  
  };

localparam [15:0] inputs [0:39] = '{
    16'h0072,
    16'h0070,
    16'h006e,
    16'h006e,
    16'h0072,
    -16'h00b2,
    -16'h0093,
    -16'h008f,
    -16'h009b,
    -16'h0097,
    -16'h0041,
    -16'h003d,
    -16'h0044,
    -16'h0027,
    -16'h0027,
    16'h009c,
    16'h0059,
    16'h004c,
    16'h0031,
    16'h0024,
    -16'h00c8,
    -16'h00ea,
    -16'h00ea,
    -16'h00f0,
    -16'h00f5,
    -16'h00be,
    -16'h00ed,
    -16'h00ed,
    -16'h00ed,
    -16'h00ed,
    16'h012e,
    16'h00f6,
    16'h00e8,
    16'h00e1,
    16'h00da,
    -16'h014d,
    -16'h0172,
    -16'h0172,
    -16'h0172,
    -16'h0172
  
};

  localparam [15:0] bias = 16'h08d8;

  logic clk, rst;
  logic [23:0] outputs [0:2];

  initial clk = 0;
  always #HCLK clk = ~clk;
  // logic [23:0] fx_point;

  Conv conv(
    .i_clk(clk),
    .i_rst_n(rst),
    .i_kernel(cnn_weight),
    .i_data(inputs),
    .i_bias(bias),
    .o_weights(outputs)
  );

  initial begin
    // $display("data: %0d", $signed(data));
    // $display("mean: %0d", mean);
    // $display("std: %0d", std);

    // /*
    // data = data - mean;
    // $display("data - mean: %0d", $signed(data));
    // $display("data - mean: %0b", data);

    // fx_point = {data, 8'b0};

    // $display("fx_point: %0b", fx_point);

    // fx_point = ($signed(fx_point) > 0) ? (fx_point / std) : -(-fx_point / std);
    // */
    // @(posedge clk);
    // $display("norm: %b", norm);
    // $display("norm: %f", $itor($signed(norm) * SF));

    rst <= 1;
    #(2*CLK)
    rst <= 0;
    @(posedge clk) rst <= 1;
    $display("=========inputs============");
    for (int i = 0; i < 40; i++) begin
        $display("input %0d: %f", i, $itor($signed(inputs[i]) * SF));
    end
    $display("=========cnn weights=========");
    for (int i = 0; i < 24; i++) begin
        $display("weight %0d: %f", i, $itor($signed(cnn_weight[i]) * SF));
    end
    for (int i = 0; i < 4; i++) begin
        @(posedge clk);
        // $display("%f\t%f\t%f", $itor($signed(outputs[0]) * SF), $itor($signed(outputs[1]) * SF), $itor($signed(outputs[2]) * SF));
    end

    $display("%f\t%f\t%f", $itor($signed(outputs[0]) * SF), $itor($signed(outputs[1]) * SF), $itor($signed(outputs[2]) * SF));

    $finish;
  end
endmodule
