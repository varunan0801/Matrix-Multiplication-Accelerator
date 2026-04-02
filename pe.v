`timescale 1ns / 1ps


module pe #(
  parameter integer DATA_WIDTH = 16, //set by the top file
  parameter integer ACC_WIDTH = 40  //set by the top file
)(
  input wire clk,
  input wire reset,
  input wire clear,

  input wire signed [DATA_WIDTH-1:0] a_in,
  input wire signed [DATA_WIDTH-1:0] b_in,

  output reg  signed [DATA_WIDTH-1:0] a_out,
  output reg  signed [DATA_WIDTH-1:0] b_out,

  output reg  signed [ACC_WIDTH-1:0] acc
);

//sign extension of a_in and b_in so negative numbers dont get extended with zeroes and turning into a positive number
wire signed [ACC_WIDTH-1:0] a_ext = {{(ACC_WIDTH - DATA_WIDTH){a_in[DATA_WIDTH-1]}}, a_in};
wire signed [ACC_WIDTH-1:0] b_ext = {{(ACC_WIDTH - DATA_WIDTH){b_in[DATA_WIDTH-1]}}, b_in};

always @(posedge clk) begin
    if (reset || clear) begin
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
