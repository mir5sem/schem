module main #(
    parameter CLOCK_RATE = 100_000_000,
    parameter MAX_PERCENT = 100
)

(
    input clk,
    
    input PS2_DATA,
    input PS2_CLK,
    
    output LED_R,
    output LED_G,
    output LED_B
);

wire RO_ps2;
wire [3:0] flags_ps2;

PS2 PS2 (
    .clk(clk),
    .PS2_DATA(PS2_DATA),
    .PS2_CLK(PS2_CLK),
    .R_O(RO_ps2),
    .flags(flags_ps2)
);

wire up_speed_RGB; assign up_speed_RGB = RO_ps2 && flags_ps2[3]; 
//?????? ?????? W ? ???????? ????????? ?????? ?????????????

wire low_speed_RGB; assign low_speed_RGB = RO_ps2 && flags_ps2[2]; 
//?????? ?????? S ? ???????? ????????? ?????? ????????????

wire [7:0] percent_red, percent_green, percent_blue;
wire [7:0] percent_light;

RGB_controller  #(.CLOCK_RATE(CLOCK_RATE)) color_controller (
    .clk(clk),
    .up_speed(up_speed_RGB),
    .low_speed(low_speed_RGB),
    .red_signal(percent_red),
    .green_signal(percent_green),
    .blue_signal(percent_blue)
);

wire up_speed_LED; assign up_speed_LED = RO_ps2 && flags_ps2[1]; 
//?????? ?????? E ? ???????? ????????? ??????? ????????????? 

wire low_speed_LED; assign low_speed_LED = RO_ps2 && flags_ps2[0]; 
//?????? ?????? D ? ???????? ????????? ??????? ????????????

LED_controller #( .CLOCK_RATE(CLOCK_RATE)) light_controller (
    .clk(clk),
    .up_speed(up_speed_LED),
    .low_speed(low_speed_LED),
    .light(percent_light)
);

localparam COUNT_CLK = 185;

wire [14:0] PWM_in_red; assign PWM_in_red = ((percent_red * percent_light) >> 7);
PWM_SIGNAL #(COUNT_CLK) PWM_red (
    .clk(clk),
    .rst(1'b0),
    .ce(1'b1),
    .PWM_in(PWM_in_red),
    .PWM_signal(LED_R)
);

wire [14:0] PWM_in_green; assign PWM_in_green = ((percent_green * percent_light) >> 7);
PWM_SIGNAL #(COUNT_CLK) PWM_green (
    .clk(clk),
    .rst(1'b0),
    .ce(1'b1),
    .PWM_in(PWM_in_green),
    .PWM_signal(LED_G)
);

wire [14:0] PWM_in_blue; assign PWM_in_blue = ((percent_blue * percent_light) >> 7);
PWM_SIGNAL #(COUNT_CLK) PWM_blue (
    .clk(clk),
    .rst(1'b0),
    .ce(1'b1),
    .PWM_in(PWM_in_blue),
    .PWM_signal(LED_B)
); 

endmodule
