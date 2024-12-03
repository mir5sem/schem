module instruction_memory (
    input wire [7:0] addr,
    output reg [15:0] instruction
);

    reg [15:0] memory [255:0];

    initial begin
        // Пример программы
        memory[0] = 16'b0000000100100011; // MUL R1, R2, R3
        memory[1] = 16'b0010001101000101; // XNOR R3, R4, R5
        memory[2] = 16'b0100000101100110; // MOV R1, R6
        memory[3] = 16'b0110000000000100; // BRZ 4
        memory[4] = 16'b1000001100001000; // LDI 3, 8
    end

    always @(*) begin
        instruction = memory[addr];
    end
endmodule
