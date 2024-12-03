`define PC_WIDTH 10
`define COMMAND_SIZE 46
`define PROGRAM_SIZE 1024
`define DATA_SIZE 1024
`define OP_SIZE 4
`define ADDR_SIZE 10

`define NOP     0   // Пустая команда
`define LOAD    1   // Загрузить число в ячейку памяти по Адресу 1
`define MOV     2   // Переместить значение из Адреса 1 в Адрес 2
`define MOV_M   3   // Переместить значение из Адреса 1 в адрес, указанный по Адресу 2
`define ADD     4   // A (Адрес 1) + B (Адрес 2) => C (Адрес 3)
`define SUB     5   // A (Адрес 1) - B (Адрес 2) => C (Адрес 3)
`define SUM     6   // Сумма цифр значения по Адресу 1 => Адрес 2
`define MUL     7   // A (Адрес 1) + B (Адрес 2) => C (Адрес 3)
`define INCR    8   // Инкремент значения по Адресу 1
`define DECR    9   // Декремент значения по Адресу 1
`define JMP    10   // Безусловный переход
`define JMP_Z  11   // Условный переход при flag_Z = 1
`define JMP_NZ 12   // Условный переход при flag_Z = 0
`define CALL   13   // Вызов процедуры
`define RET    14   // Возврат
`define HLT    15   // Остановка процессора

/*
    Формат команды:
    ADD, SUB, MUL:
    | код операции  | Адрес 1            | Адрес 2         | Адрес 3        |
         4 бита     | 10 бит             | 10 бит          | 10 бит         | 12 бит
    LOAD:
    | код операции  |           адрес в памяти      |           Литерал             |
         4 бита     |            10 бит             |           32 бита             |
    JMP_?:
    | код операции  |           Адрес перехода      |                              
         4 бита     |            10 бит             |      32 бита        
    MOV, MOV_M, SUM:
    | код операции  | Адрес 1            | Адрес 2         | 
         4 бита     | 10 бит             | 10 бит          | 22 бита
    INCR, DECR:
    | код операции  | Адрес 1            |
         4 бита     | 10 бит             | 32 бита
*/

module CPU(
    input i_clk,
    input reset
    );
    
reg[`PC_WIDTH-1 : 0] pc, newpc, sp;

reg [`COMMAND_SIZE-1 : 0]   Program [0:`PROGRAM_SIZE - 1  ];
reg [31:0]                  Data    [0:`DATA_SIZE - 1];
reg [31:0]                  Stack   [0:`DATA_SIZE - 1];

reg[`COMMAND_SIZE-1 : 0] command_1, command_2;
wire [`OP_SIZE - 1 : 0] op_1 = command_1 [`COMMAND_SIZE - 1 -: `OP_SIZE];
wire [`OP_SIZE - 1 : 0] op_2 = command_2 [`COMMAND_SIZE - 1 -: `OP_SIZE];

wire [`ADDR_SIZE - 1 : 0] addr1 = command_1[`COMMAND_SIZE - 1 - `OP_SIZE                 -: `ADDR_SIZE];
wire [`ADDR_SIZE - 1 : 0] addr2 = command_1[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE    -: `ADDR_SIZE];

wire [`ADDR_SIZE - 1 : 0] addr_from = command_2[`COMMAND_SIZE - 1 - `OP_SIZE                 -: `ADDR_SIZE];
wire [`ADDR_SIZE - 1 : 0] addr_to = command_2[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE    -: `ADDR_SIZE];

wire [$clog2(`DATA_SIZE) - 1 : 0] new_addr = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE -: $clog2(`DATA_SIZE)];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr_to_load = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE - `ADDR_SIZE -: $clog2(`DATA_SIZE)];
wire [$clog2(`DATA_SIZE) - 1 : 0] addr_to_load_L = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE  -: `ADDR_SIZE];

//wire [`ADDR_SIZE - 1 : 0] addr1_3 = command_3[`COMMAND_SIZE - 1 - `OP_SIZE                 -: `ADDR_SIZE];
//wire [`ADDR_SIZE - 1 : 0] addr2_3 = command_3[`COMMAND_SIZE - 1 - `OP_SIZE - `ADDR_SIZE    -: `ADDR_SIZE];

wire [31:0] literal_to_load = command_2 [`COMMAND_SIZE - 1 - `OP_SIZE - $clog2(`DATA_SIZE) -: 32];

reg [31:0] Reg_A = 0, Reg_B = 0, newReg_A = 0, newReg_B = 0;

reg flag_Z = 0, flag_end = 0;

wire clk = i_clk & !flag_end;

integer i;
initial 
begin
    pc = 0; newpc = 0; sp = 0;
    $readmemb("Program.mem", Program);
    for(i = 0; i < `DATA_SIZE; i = i + 1)
        Data[i] = 32'b0;
    for(i = 0; i < `DATA_SIZE; i = i + 1)
        Stack[i] = 32'b0;
    command_1 = 0;
    command_2 = 0;
    Reg_A = 0;
    Reg_B = 0;
    newReg_A = 0; 
    newReg_B = 0;
end

always@(posedge clk)
    if(reset)
        pc <= 0;
    else begin
        case (op_2)
        `HLT:
            pc <= pc;
        default:
            pc <= newpc;
        endcase
    end

always @(posedge clk)
begin 
    if(reset) Reg_A <= 0;
    else Reg_A <= newReg_A;
end

always @(posedge clk)
begin 
    if(reset) Reg_B <= 0;
    else Reg_B <= newReg_B;
end

always@(posedge clk)
begin
    command_1 <= Program[pc];
    command_2 <= command_1;
end

always @*
begin
    case(op_1)
        `ADD, `SUB, `SUM, `MUL, `INCR, `DECR:
            newReg_A <= Data[addr1];
        default: newReg_A <= newReg_A;
    endcase
end

always @*
begin
    case(op_1)
        `ADD, `SUB, `MUL:
            newReg_B <= Data[addr2];
        default: newReg_B <= newReg_B;
    endcase
end

reg [31:0] new_data = 0;

always @(posedge clk)
begin
    case(op_2)
        `ADD, `SUB, `MUL:
            Data[addr_to_load] <= new_data;
        `LOAD:
            Data[addr_to_load_L] <= new_data;
        `MOV, `SUM:
            Data[addr_to] <= new_data;
        `MOV_M:
            Data[Data[addr_to]] <= new_data;
        `INCR, `DECR:
            Data[addr_from] <= new_data;
    endcase
end

always @*
begin
    case(op_2)
        `ADD: new_data <= Reg_A + Reg_B;
        `SUB: new_data <= Reg_A - Reg_B;
        `SUM: new_data <= Reg_A[31:28] + Reg_A[27:24] + Reg_A[23:20] + Reg_A[19:16] + Reg_A[15:12] + Reg_A[11:8] + Reg_A[7:4] + Reg_A[3:0];
        `MUL: new_data <= Reg_A * Reg_B;
        `LOAD: new_data <= literal_to_load;
        `MOV, `MOV_M: new_data <= Data[addr_from];
        `INCR: new_data <= Reg_A + 1'b1;
        `DECR: new_data <= Reg_A - 1'b1;
    endcase
    
    if (new_data == 0)
        flag_Z <= 1'b1;
    else
        flag_Z <= 1'b0;
end

always @*
begin
    case(op_2)
        `JMP: begin
            newpc = new_addr;
        end
        
        `JMP_Z: begin
            if (flag_Z)
                newpc = new_addr;
            else
                newpc = pc + 1;
        end
        
        `JMP_NZ: begin
            if (!flag_Z)
                newpc = new_addr;
            else
                newpc = pc + 1;
        end
        
        `CALL: begin
            Stack[sp] = pc + 1;
            sp = sp + 1;
            newpc = new_addr;
        end
            
        `RET: begin
            if (sp > 0)
            begin
                sp = sp - 1;
                newpc = Stack[sp];
                Stack[sp] = 0;
            end
            else newpc <= pc + 1;
        end
        
        `HLT: begin
            flag_end <= 1;
        end
        
        default: newpc <= pc + 1;
    endcase
end

endmodule
