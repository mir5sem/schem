`timescale 1ns / 1ps

module trig_table #(
    VALUE_WIDTH = 32,
    ANGLE_WIDTH = 10,
    COUNT = 2**ANGLE_WIDTH
)
(
    input [ANGLE_WIDTH-1:0] angle_in,
    output signed [VALUE_WIDTH-1:0] sin_out,
    output signed [VALUE_WIDTH-1:0] cos_out
);

wire [VALUE_WIDTH-1:0] sin_table [0:COUNT-1];
`include "sin_table.vh"

wire [VALUE_WIDTH-1:0] cos_table [0:COUNT-1];
`include "cos_table.vh"

wire sin_cond = angle_in >= 0 && angle_in < COUNT/2;
wire cos_cond = (angle_in >= 0 && angle_in < COUNT/4) || (angle_in >= 3*COUNT/4 && angle_in < COUNT);

assign sin_out = sin_cond ? sin_table[angle_in] : -sin_table[angle_in];
assign cos_out = cos_cond ? cos_table[angle_in] : -cos_table[angle_in];

endmodule
