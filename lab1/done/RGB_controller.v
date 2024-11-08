`define HIGH_SPEED 2 // 2 ??????? ??????
`define MIDDLE_SPEED 6 // 6 ?????? ??????
`define LOW_SPEED 10 // 10 ?????? ??????

`define MAX_SPEED 10

// ?????? ??????????? RGB ? ?????????? ?????????
module RGB_controller #( 
    parameter CLOCK_RATE = 100_000_000,           // ??????? ?????????? ????????? ???????
    localparam COUNT_CHANGES = 512,               // ?????????? ????????? ?????
    localparam MAX_COUNTER = CLOCK_RATE / COUNT_CHANGES // ???????????? ???????? ????????
)

(
    input clk,                  // ??????? ????????? ???????? ??????
    input up_speed,             // ?????? ??? ?????????? ????????
    input low_speed,            // ?????? ??? ?????????? ????????
    output [7:0] red_signal,    // ???????? ?????? ???????? ?????
    output [7:0] green_signal,  // ???????? ?????? ???????? ?????
    output [7:0] blue_signal    // ???????? ?????? ?????? ?????
);

    // ?????????? ??? ???????? ??????? ????????
    reg [$clog2(`MAX_SPEED) - 1:0] speed;
    // ??????? ???????? ????????? ? ?????? ????????
    reg [$clog2(MAX_COUNTER * `MAX_SPEED) - 1 : 0] clk_counter;

    // ????????? ???????? ??? CORDIC
    reg [15:0] Xin, Yin;
    reg [63:0] i = 0;
    wire [31:0] red_angle, green_angle, blue_angle;

    // ???? ??? ??????? ?????
    assign red_angle = (((1 << 32)*i) >> 9);
    assign green_angle = (((1 << 32)*(i + 469)) >> 9);
    assign blue_angle = (((1 << 32)*(i + 299)) >> 9);

    // ????????? ???????? ??? CORDIC
    localparam start_X = 8000, half_sX = start_X >> 1;

    // ?????????? ??????? CORDIC ??? ??????? ?????
    wire signed [16:0] red_func, green_func, blue_func;

    // ????????? ?????? CORDIC ??? ???????? ?????
    CORDIC cordic_red (
        .clk(clk), 
        .angle(red_angle), 
        .x_in(Xin), 
        .y_in(Yin), 
        .cos_out(red_func)
    );

    // ????????? ?????? CORDIC ??? ???????? ?????
    CORDIC cordic_green (
        .clk(clk), 
        .angle(green_angle), 
        .x_in(Xin), 
        .y_in(Yin), 
        .sin_out(green_func)
    );

    // ????????? ?????? CORDIC ??? ?????? ?????
    CORDIC cordic_blue (
        .clk(clk), 
        .angle(blue_angle), 
        .x_in(Xin), 
        .y_in(Yin), 
        .sin_out(blue_func)
    );

    // ?????????????? ???????? ???????? CORDIC ? ??????? RGB
    assign red_signal = (red_func >= $signed(-half_sX)) ? ((red_func + half_sX) >>> 6): 0;
    assign green_signal = (green_func >= $signed(-half_sX)) ? ((green_func + half_sX) >>> 6): 0;
    assign blue_signal = (blue_func >= $signed(-half_sX)) ? ((blue_func + half_sX) >>> 6) : 0;

    // ????????? ?????????????
    initial begin 
        Xin = start_X / 1.647;
        Yin = 0;
        
        speed = `MIDDLE_SPEED;
        clk_counter = {$clog2(`MAX_SPEED * MAX_COUNTER){1'b0}};
    end

    // ??????, ??????????? ?? ????????? ????
    wire angle_changed = clk_counter == speed * MAX_COUNTER - 1;

    // ??????? ???????? ?????????
    always @(posedge clk)
        clk_counter = angle_changed ? {$clog2(`MAX_SPEED * MAX_COUNTER){1'b0}} : clk_counter + 1;

    // ????????? ???? ?? ?????? ????????
    always @(posedge clk)
        if (angle_changed) begin
            i = (i == COUNT_CHANGES - 1) ? 0 : i + 1;
        end

    // ?????????? ????????? ????????? ?????
    always @(posedge clk) begin
        if (low_speed)
            case (speed)
                `HIGH_SPEED: speed <= `MIDDLE_SPEED;
                `MIDDLE_SPEED: speed <= `LOW_SPEED;
            endcase

        if (up_speed)
            case (speed)
                `MIDDLE_SPEED: speed <= `HIGH_SPEED;
                `LOW_SPEED: speed <= `MIDDLE_SPEED;
            endcase
    end

endmodule
