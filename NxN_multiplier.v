`timescale 1ns / 1ps

module NxN_multiplier #(
  parameter integer N = 5,
  parameter integer DATA_WIDTH = 16
)(
  input  wire clk,
  input  wire reset,
  
  //cannot declare array as an input in verilog so flattening it into a single concatenated number
  input  wire signed [N*DATA_WIDTH-1:0] a_flat,
  input  wire signed [N*DATA_WIDTH-1:0] b_flat,
  
  //cannot declare array a 2d array as an output in verilog so flattening it into a single concatenated number
  output wire signed [N*N*2*DATA_WIDTH-1:0] c_flat
);

  //converting inputs into an array for easier processing
  wire signed [DATA_WIDTH-1:0] a [0:N-1];
  wire signed [DATA_WIDTH-1:0] b [0:N-1];

  genvar k;
  generate
    for (k = 0; k < N; k = k + 1) begin
      assign a[k] = a_flat[(k+1)*DATA_WIDTH-1 -: DATA_WIDTH];
      assign b[k] = b_flat[(k+1)*DATA_WIDTH-1 -: DATA_WIDTH];
    end
  endgenerate

  //preceding zeroes initialization
  reg signed [DATA_WIDTH-1:0] A_d [0:N-1][0:N-1];
  reg signed [DATA_WIDTH-1:0] B_d [0:N-1][0:N-1];

  integer i, j;

  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < N; i = i + 1)
        for (j = 0; j < N; j = j + 1) begin
          A_d[i][j] <= 0;
          B_d[i][j] <= 0;
        end
    end 
    else begin
      for (i = 0; i < N; i = i + 1) begin
        A_d[i][0] <= a[i];
        B_d[i][0] <= b[i];
      end

      for (i = 0; i < N; i = i + 1)
        for (j = 1; j <= i; j = j + 1) begin
          A_d[i][j] <= A_d[i][j-1];
          B_d[i][j] <= B_d[i][j-1];
        end
    end
  end

  //pipelining arrays
  reg signed [DATA_WIDTH-1:0] a_pipe [0:N-1][0:N-1];
  reg signed [DATA_WIDTH-1:0] b_pipe [0:N-1][0:N-1];

  always @(posedge clk) begin
    if (reset) begin
      for (i = 0; i < N; i = i + 1)
        for (j = 0; j < N; j = j + 1) begin
          a_pipe[i][j] <= 0;
          b_pipe[i][j] <= 0;
        end
    end 
    else begin
      for (i = 0; i < N; i = i + 1)
        for (j = N-1; j > 0; j = j - 1)
          a_pipe[i][j] <= a_pipe[i][j-1];

      for (j = 0; j < N; j = j + 1)
        for (i = N-1; i > 0; i = i - 1)
          b_pipe[i][j] <= b_pipe[i-1][j];

      for (i = 0; i < N; i = i + 1) begin
        a_pipe[i][0] <= A_d[i][i];
        b_pipe[0][i] <= B_d[i][i];
      end
    end
  end

  //loading elements into the processing elements
  wire signed [2*DATA_WIDTH-1:0] c [0:N-1][0:N-1];

  genvar row, col;
  generate
    for (row = 0; row < N; row = row + 1) begin
      for (col = 0; col < N; col = col + 1) begin
        pe #(DATA_WIDTH) pe_inst (
          .clk   (clk),
          .reset (reset),
          .a_in  (a_pipe[row][col]),
          .b_in  (b_pipe[row][col]),
          .a_out (),
          .b_out (),
          .acc   (c[row][col])
        );
      end
    end
  endgenerate

  //converting 2d array output back into original output form
  generate
    for (row = 0; row < N; row = row + 1) begin
      for (col = 0; col < N; col = col + 1) begin
        assign c_flat[(row*N + col + 1)*2*DATA_WIDTH-1 -: 2*DATA_WIDTH] = c[row][col];
      end
    end
  endgenerate

endmodule
