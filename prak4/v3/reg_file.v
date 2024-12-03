`timescale 1ns / 1ps

module reg_file #(
    parameter DATA_WIDTH = 8,
    parameter REG_FILE_SIZE = 16,
    parameter ADDR_WIDTH = $clog2(REG_FILE_SIZE)
)(
    input clk, reset, wen,
    input [DATA_WIDTH-1:0] data_in,
    input [ADDR_WIDTH-1:0] addr_write,
    input [ADDR_WIDTH-1:0] addr_a,
    input [ADDR_WIDTH-1:0] addr_b,
    output reg [DATA_WIDTH-1:0] operand_a,
    output reg [DATA_WIDTH-1:0] operand_b
);

    reg [DATA_WIDTH-1:0] GPR [0:REG_FILE_SIZE-1];
    integer i;

    // Инициализация регистров и выходов
    initial begin
        for (i = 0; i < REG_FILE_SIZE; i = i + 1) begin
            GPR[i] = {DATA_WIDTH{1'b0}};
        end
        operand_a = {DATA_WIDTH{1'b0}};
        operand_b = {DATA_WIDTH{1'b0}};
    end

    // Запись данных в регистр
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < REG_FILE_SIZE; i = i + 1) begin
                GPR[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (wen && addr_write != {ADDR_WIDTH{1'b0}}) begin
            GPR[addr_write] <= data_in;
        end
    end

    // Чтение данных из регистров
    always @(posedge clk) begin
        if (reset) begin
            operand_a <= {DATA_WIDTH{1'b0}};
            operand_b <= {DATA_WIDTH{1'b0}};
        end else begin
            operand_a <= GPR[addr_a];
            operand_b <= GPR[addr_b];
        end
    end

endmodule
