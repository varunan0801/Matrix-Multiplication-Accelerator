`timescale 1ns / 1ps

module tb_NxN_multiplier;

  parameter integer N = 5;
  parameter integer DATA_WIDTH = 16;
  parameter integer CLK_PERIOD = 10;

  reg clk;
  reg reset;

  reg  signed [N*DATA_WIDTH-1:0] a_flat;
  reg  signed [N*DATA_WIDTH-1:0] b_flat;
  wire signed [N*N*2*DATA_WIDTH-1:0] c_flat;

  wire signed [DATA_WIDTH-1:0] a_dbg [0:N-1];
  wire signed [DATA_WIDTH-1:0] b_dbg [0:N-1];
  wire signed [2*DATA_WIDTH-1:0] c_dbg [0:N-1][0:N-1];

  integer i, j;
  
  NxN_multiplier #(
    .N(N),
    .DATA_WIDTH(DATA_WIDTH)
  ) dut (
    .clk(clk),
    .reset(reset),
    .a_flat(a_flat),
    .b_flat(b_flat),
    .c_flat(c_flat)
  );

  always #(CLK_PERIOD/2) clk = ~clk;

  genvar l, m;
  generate
    for (l = 0; l < N; l = l + 1) begin
      assign a_dbg[l] = a_flat[(l+1)*DATA_WIDTH-1 -: DATA_WIDTH];
      assign b_dbg[l] = b_flat[(l+1)*DATA_WIDTH-1 -: DATA_WIDTH];
    end
  endgenerate

  generate
    for (l = 0; l < N; l = l + 1) begin
      for (m = 0; m < N; m = m + 1) begin
        assign c_dbg[l][m] =
          c_flat[(l*N + m + 1)*2*DATA_WIDTH-1 -: 2*DATA_WIDTH];
      end
    end
  endgenerate

  initial begin
    clk = 0;
    reset = 1;
    a_flat = 0;
    b_flat = 0;

    #(2*CLK_PERIOD);
    reset = 0;

    @(posedge clk);
    a_flat = {16'd21, 16'd16, 16'd11, 16'd6, 16'd1};
    b_flat = {16'd1, 16'd1,  16'd1, 16'd1, 16'd1};

    @(posedge clk);
    a_flat = {16'd22, 16'd17, 16'd12, 16'd7, 16'd2};
    b_flat = {16'd1, 16'd1,  16'd1, 16'd1, 16'd1};

    @(posedge clk);
    a_flat = {16'd23, 16'd18, 16'd13, 16'd8, 16'd3};
    b_flat = {16'd1, 16'd1,  16'd1, 16'd1, 16'd1};

    @(posedge clk);
    a_flat = {16'd24, 16'd19, 16'd14, 16'd9, 16'd4};
    b_flat = {16'd1, 16'd1,  16'd1, 16'd1, 16'd1};
    
    @(posedge clk);
    a_flat = {16'd25, 16'd20, 16'd15, 16'd10, 16'd5};
    b_flat = {16'd1, 16'd1,  16'd1, 16'd1, 16'd1};


    @(posedge clk);
    a_flat = 0;
    b_flat = 0;

    #(20*CLK_PERIOD);
    
    $display("\n===== OUTPUT MATRIX C =====");
    for (i = 0; i < N; i = i + 1) begin
      for (j = 0; j < N; j = j + 1) begin
        $write("%4d ", c_dbg[i][j]);
      end
      $write("\n");
    end

    $finish;
  end

endmodule
