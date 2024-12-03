`timescale 1ns / 1ps

module test;

reg clk = 0;
always #0.5 clk = ~clk;
reg reset = 0;
wire [2:0] stage_counter;
cpu uut (
    .clk(clk),
    .reset(reset),
    .stage_counter(stage_counter)
);

initial
begin
    @(posedge clk)
    @(posedge clk)
    reset = 0;
end

endmodule
