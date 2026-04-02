`timescale 1ns / 1ps

module NxN_multiplier #(
  parameter integer N          = 5,
  parameter integer DATA_WIDTH = 16,
  parameter integer ACC_WIDTH = 2*DATA_WIDTH + $clog2(N) //added to make sure overflow doesnt happen when MAC happens
)(
  input wire clk,
  input wire reset,
  input wire clear,

  //cannot declare array as an input in verilog so flattening it into a single concatenated number
  input wire signed [N*DATA_WIDTH-1:0] a_flat,
  input wire signed [N*DATA_WIDTH-1:0] b_flat,

  //cannot declare array a 2d array as an output in verilog so flattening it into a single concatenated number
  output wire signed [N*N*ACC_WIDTH-1:0] c_flat
);

  //convert inputs into an array for easier processing
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
    if (reset || clear) begin
      for (i = 0; i < N; i = i + 1)
        for (j = 0; j < N; j = j + 1) begin
          A_d[i][j] <= 0;
          B_d[i][j] <= 0;
        end
    end else begin
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


  wire signed [DATA_WIDTH-1:0] a_wire [0:N-1][0:N];   
  wire signed [DATA_WIDTH-1:0] b_wire [0:N][0:N-1];   

  genvar gi;
  generate
    for (gi = 0; gi < N; gi = gi + 1) begin
      assign a_wire[gi][0] = A_d[gi][gi];   
      assign b_wire[0][gi] = B_d[gi][gi];  
    end
  endgenerate

  wire signed [2*DATA_WIDTH-1:0] c [0:N-1][0:N-1];


  genvar row, col;
  generate
    for (row = 0; row < N; row = row + 1) begin
      for (col = 0; col < N; col = col + 1) begin
        pe #(.DATA_WIDTH(DATA_WIDTH),.ACC_WIDTH(ACC_WIDTH)) pe_inst (
          .clk(clk),
          .reset(reset),
          .clear(clear),
          .a_in(a_wire[row][col]),       // arrives from the left neighbour
          .b_in(b_wire[row][col]),       // arrives from the top  neighbour
          .a_out(a_wire[row][col+1]),     // passes right to next PE in row
          .b_out(b_wire[row+1][col]),     // passes down  to next PE in col
          .acc(c[row][col])
        );
      end
    end
  endgenerate

  //converting 2d array output back into original output form(flattening)
  generate
    for (row = 0; row < N; row = row + 1) begin
      for (col = 0; col < N; col = col + 1) begin
        assign c_flat[(row*N + col + 1)*ACC_WIDTH-1 -: ACC_WIDTH] = c[row][col];
      end
    end
  endgenerate
  
  reg [$clog2(2*N):0] cycle_count;
 
  always @(posedge clk) begin
    if (reset || clear)
      cycle_count <= 0;
    else if (cycle_count < 2*N - 1)
      cycle_count <= cycle_count + 1;
  end
 
  assign valid_out = (cycle_count == 2*N - 1);
endmodule
