`timescale 1ns / 1ps

module trig_table_tb;

    // Параметры модуля для тестирования
    parameter VALUE_WIDTH = 32;
    parameter ANGLE_WIDTH = 10;
    parameter COUNT = 2**ANGLE_WIDTH;

    // Входные и выходные сигналы
    reg [ANGLE_WIDTH-1:0] angle_in;
    wire signed [VALUE_WIDTH-1:0] sin_out, cos_out;
    reg [5:0] errors = 0;
    
    // Модуль под тестированием
    trig_table #(
        .VALUE_WIDTH(VALUE_WIDTH),
        .ANGLE_WIDTH(ANGLE_WIDTH)
    ) uut (
        .angle_in(angle_in),
        .sin_out(sin_out),
        .cos_out(cos_out)
    );

    // Таблицы для сравнения
    wire [VALUE_WIDTH-1:0] sin_table [0:COUNT-1];
    wire [VALUE_WIDTH-1:0] cos_table [0:COUNT-1];

    `include "sin_table.vh"
    `include "cos_table.vh"

    // Процедура тестирования
    initial begin
        // Инициализация тестирования
        angle_in = 0;

        // Проход по всем возможным углам
        for (angle_in = 0; angle_in < COUNT; angle_in = angle_in + 1) begin
            #10;
        end

        // Окончание симуляции
        $stop;
    end
endmodule
