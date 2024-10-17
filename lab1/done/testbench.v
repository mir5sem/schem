`timescale 1ns / 1ps

module test_main;

reg clk;

initial clk = 0;
always #1 clk = ~clk;

localparam CLOCK_RATE = 100_000;
localparam MAX_PERCENT = 100;

reg PS2_DATA, PS2_CLK;
wire LED_R, LED_G, LED_B;

main #(.CLOCK_RATE(CLOCK_RATE), .MAX_PERCENT(MAX_PERCENT)) main (
    .clk(clk),
    .PS2_DATA(PS2_DATA),
    .PS2_CLK(PS2_CLK),
    .LED_R(LED_R),
    .LED_G(LED_G),
    .LED_B(LED_B)
);

endmodule
