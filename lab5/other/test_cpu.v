`timescale 1ns / 1ps

module test_cpu();

reg clk, reset;

CPU conv(.i_clk(clk), .reset(reset));

always #10 clk <= ~clk;

initial
begin
    clk = 0;
    reset = 0;
end

endmodule
