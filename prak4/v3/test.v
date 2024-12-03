`timescale 1ns / 1ps

module tb_cpu();
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 8;
    localparam REG_NUM = 16;
    localparam REG_ADDR_WIDTH = $clog2(REG_NUM);
    localparam CMD_WIDTH = 16;

    reg clk;
    reg reset;

    cpu cpu1 (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        uut.instruction_memory[0] = {4'b0101, 4'b0001, 8'd10}; // LOAD R1, 10
        uut.instruction_memory[1] = {4'b0101, 4'b0010, 8'd20}; // LOAD R2, 20
        uut.instruction_memory[2] = {4'b0011, 4'b0010, 4'b0001, 4'b0000}; // MOV R2, R1
        uut.instruction_memory[3] = {4'b0001, 4'b0001, 4'b0010, 4'b0100}; // MUL R1, R2, R4
        uut.instruction_memory[4] = {4'b0010, 4'b0001, 4'b0010, 4'b0101}; // XNOR R1, R2, R5
        uut.instruction_memory[5] = {4'b0100, 4'b0000, 8'd8}; // JUMP, если > 0, перейти на адрес 8
        uut.instruction_memory[6] = {4'b0101, 4'b0000, 8'd0}; // LOAD R0, 0
        uut.instruction_memory[8] = {4'b0011, 4'b0101, 4'b0010, 4'b0000}; // MOV R5, R2
        $finish;
    end
endmodule
        
        
