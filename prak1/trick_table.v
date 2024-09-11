`timescale 1ns / 1ps


module trick_table(
    
    #(VALUE_WIDTH = 33,
    ANGLE_WIDTH = 10,
    COUNT = 2**ANGLE_WIDTH
    )
    (
        input [ANGLE_WIDTH-1:0] angle_in,
        output signed [VALUE_WIDTH - 1:0] sin_out,
        output signed [VALUE_WIDTH  -1;0] cos_out

    );
    
    wire [VALUE_WIDTH -1:0] sin_table(0:COUNT-1);
    include "sin_table.vh"
    wire [VALUE_WIDTH -1:0] cos_table(0:COUNT-1);
    include "cos_table.vh"
endmodule
