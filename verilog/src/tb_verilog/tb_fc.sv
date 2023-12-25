`timescale 1ns/100ps

module tb;
  localparam CLK = 10;
  localparam HCLK = CLK / 2;
  localparam SF = 2.0 ** -8.0;

  localparam [15:0] fc_weight [0:29] = '{
    16'h09e6,
    16'h06b3,
    16'h0cdb,
    -16'h112f,
    -16'h0f7e,
    -16'h0e91,
    16'h0a8c,
    16'h09a9,
    16'h0b1e,
    16'h0d97,
    16'h0c3a,
    16'h0c0a,
    -16'h0d7f,
    -16'h0adc,
    -16'h0731,
    16'h0857,
    16'h0835,
    16'h0c04,
    -16'h096c,
    -16'h0921,
    -16'h0952,
    -16'h0702,
    -16'h06ab,
    -16'h04c2,
    16'h1470,
    16'h14d3,
    16'h1386,
    -16'h1587,
    -16'h1653,
    -16'h1881
  
  };

localparam [23:0] inputs [0:29] = '{
   -24'h00e7df,
-24'h00d320,
-24'h00cd09,
24'h00d557,
24'h00d963,
24'h00d6cb,
24'h005a9a,
24'h0051c8,
24'h004df1,
-24'h002021,
-24'h0032eb,
-24'h003528,
24'h01f72c,
24'h01ee4e,
24'h01e669,
24'h008f6f,
24'h007954,
24'h00706a,
24'h00cde0,
24'h00c2ad,
24'h00bef4,
-24'h00e713,
-24'h00f0eb,
-24'h00f7f9,
-24'h016a57,
-24'h0164ca,
-24'h01601e,
-24'h00c07a,
-24'h00b38b,
-24'h00ac34 
};

  localparam [15:0] bias = -16'h2a85;

  logic clk, rst;
  logic [31:0] outputs;

  initial clk = 0;
  always #HCLK clk = ~clk;
  // logic [23:0] fx_point;

  FC fc(
    .i_clk(clk),
    .i_rst_n(rst),
    .i_weight(fc_weight),
    .i_data(inputs),
    .i_bias(bias),
    .o_output(outputs)
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
    
    for (int i = 0; i < 30; i++) begin
        $display("%0d: %f\t%f", i, $itor($signed(fc_weight[i]) * SF), $itor($signed(inputs[i]) * SF));
    end
    
    for (int i = 0; i < 5; i++) begin
        @(posedge clk);
    end

    $display("%f", $itor($signed(outputs) * SF));

    $finish;
  end
endmodule
