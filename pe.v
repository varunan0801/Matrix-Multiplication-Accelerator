`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/28/2025 11:36:07 PM
// Design Name: 
// Module Name: pe
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pe #(
  parameter DATA_WIDTH = 16
)(
  input  wire clk,
  input  wire reset,

  input  wire signed [DATA_WIDTH-1:0] a_in,
  input  wire signed [DATA_WIDTH-1:0] b_in,

  output reg  signed [DATA_WIDTH-1:0] a_out,
  output reg  signed [DATA_WIDTH-1:0] b_out,

  output reg  signed [2*DATA_WIDTH-1:0] acc
);

  always @(posedge clk) begin
    if (reset) begin
      acc   <= 0;
      a_out <= 0;
      b_out <= 0;
    end else begin
      acc   <= acc + (a_in * b_in);
      a_out <= a_in;
      b_out <= b_in;
    end
  end

endmodule