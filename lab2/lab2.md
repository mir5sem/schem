
Необходимо разработать процессор на Verilog, который исполняет заданный набор инструкций в котором заданный алгоритм ниже будет записан в формате этих инструкций в памяти команд.

Всё это будет в одном модуле (память инструкций и память данных должны находится в разных областях)

Основные шаги:
- Определи полный наобр инструкций необходимых для заданного алгоритма, который был написан на c++
- Опиши алгоритм в виде последовательности инструкций в модуле процессора
- Инициализируй входные данные и память инструкций в модуле процессора
- После того как сделал это допиши до конца память инструкций, не используй заполнители и не пропускай никакие команды.
- После того как полностью определил память инструкций переходи к 5 стадиям обработки команд
- Проанализируй как все команды процессора должны выполняться во всех 5 стадиях процессора и напиши для этого алгоритм в модуле процессора
- Также допиши все команды, которые используются в алгоритме до конца. Не пропускай никакие строчки.

В конце напиши мне где будет собираться выходная последовательность, чтобы я мог проверить работу процессора. Желательно сразу предоставить полный код модуля, а не просить меня дописать его самостоятельно.

Например для входной последовательности 10, 22, 9, 33, 21, 50, 41, 60, выходная последовательность должна быть равна 3, 10, 11, 20, 25, 28

Не торопись с ответом и выбирай самый правильный, а не самый популярный ответ. Задавай вопросы если тебе что-то не понятно в моих запросах.

### [lab2_1](lab2_1.cpp)

### [lab2_lowcode](lab2_lowcode.cpp)

### [lab2_lowcode_minimal](lab2_lowcode_minimal.cpp)

### [lab2_lowcode_v1](lab2_lowcode_v1.cpp)

### [lab2_lowcode_v2](lab2_lowcode_v2.cpp)

### fsm_Dirtyform.v

```verilog
module LIS_processor(
    input clk,                // Clock signal
    input reset,              // Asynchronous reset
    input start,              // Start signal for the process
    output reg done           // Done signal
);
    // Constants
    parameter N = 10;                  // Number of elements in the input array
    parameter MAX_SIZE = 100;          // Maximum size of the array

    integer i;

    // Registers for the algorithm
    reg [7:0] arr [0:9];                     // Input array
    reg [7:0] dp [0:MAX_SIZE-1];             // DP array
    reg signed [7:0] prev [0:MAX_SIZE-1];    // Previous indices array
    reg [7:0] lis [0:MAX_SIZE-1];            // Temporary LIS storage
    reg [7:0] result [0:MAX_SIZE-1];         // Result array

    // Separate indices for different states
    reg signed [7:0] idx_init;
    reg signed [7:0] idx_outer;
    reg signed [7:0] idx_inner;
    reg signed [7:0] idx_find_max;
    reg signed [7:0] R5;
    reg signed [7:0] R6;
    reg signed [7:0] lis_length;
    reg [7:0] temp;

    // Indices for reversal
    reg signed [7:0] idx_reverse_start;
    reg signed [7:0] idx_reverse_end;

    // Index for OUTPUT_LIS
    reg signed [7:0] idx_output;

    // State variables for FSM control
    reg [3:0] state;
    parameter INIT_LOOP = 0, OUTER_LOOP = 1, INNER_LOOP = 2, FIND_MAX = 3,
              RESTORE_LIS = 4, REVERSE_LIS = 5, OUTPUT_LIS = 6, DONE_STATE = 7;

    // Initialize the input array
    initial begin
        arr[0] = 3;  arr[1] = 10; arr[2] = 2;  arr[3] = 11;
        arr[4] = 1;  arr[5] = 20; arr[6] = 15; arr[7] = 30;
        arr[8] = 25; arr[9] = 28;
    end

    // Main sequential block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INIT_LOOP;
            idx_init <= 0;
            done <= 0;
            // Initialize other indices to 0 to prevent latches
            idx_outer <= 0;
            idx_inner <= 0;
            idx_find_max <= 0;
            R5 <= 0;
            R6 <= -1;
            lis_length <= 0;
            idx_reverse_start <= 0;
            idx_reverse_end <= 0;
            idx_output <= 0;
            // Clear dp and prev arrays for clarity
            for (i = 0; i < N; i = i + 1) begin
                dp[i] <= 0;
                prev[i] <= -1;
            end
            $display("RESET: All registers initialized.");
        end else begin
            case (state)
                INIT_LOOP: begin
                    if (idx_init < N) begin
                        dp[idx_init] <= 1;
                        prev[idx_init] <= -1;
                        $display("INIT_LOOP: dp[%0d] <= 1, prev[%0d] <= -1", idx_init, idx_init);
                        idx_init <= idx_init + 1;
                    end else begin
                        $display("INIT_LOOP: Initialization complete. Moving to OUTER_LOOP.");
                        idx_outer <= 1;
                        state <= OUTER_LOOP;
                    end
                end
                OUTER_LOOP: begin
                    if (idx_outer < N) begin
                        $display("OUTER_LOOP: Processing index %0d.", idx_outer);
                        idx_inner <= 0;
                        state <= INNER_LOOP;
                    end else begin
                        $display("OUTER_LOOP: Completed outer loop. Moving to FIND_MAX.");
                        idx_find_max <= 0;
                        R5 <= 0;
                        R6 <= -1;
                        state <= FIND_MAX;
                    end
                end
                INNER_LOOP: begin
                    if (idx_inner < idx_outer) begin
                        $display("INNER_LOOP: Comparing arr[%0d]=%0d < arr[%0d]=%0d", 
                                 idx_inner, arr[idx_inner], idx_outer, arr[idx_outer]);
                        if (arr[idx_inner] < arr[idx_outer]) begin
                            $display("INNER_LOOP: arr[%0d] < arr[%0d]", idx_inner, idx_outer);
                            if (dp[idx_outer] < dp[idx_inner] + 1) begin
                                $display("INNER_LOOP: dp[%0d]=%0d < dp[%0d]=%0d + 1", 
                                         idx_outer, dp[idx_outer], idx_inner, dp[idx_inner]);
                                dp[idx_outer] <= dp[idx_inner] + 1;
                                prev[idx_outer] <= idx_inner;
                                $display("INNER_LOOP: Updated dp[%0d] <= %0d, prev[%0d] <= %0d", 
                                         idx_outer, dp[idx_outer], idx_outer, idx_inner);
                            end else begin
                                $display("INNER_LOOP: No update needed for dp[%0d].", idx_outer);
                            end
                        end else begin
                            $display("INNER_LOOP: arr[%0d] >= arr[%0d], no action.", idx_inner, idx_outer);
                        end
                        idx_inner <= idx_inner + 1;
                    end else begin
                        $display("INNER_LOOP: Completed inner loop for index %0d. Moving to next OUTER_LOOP.", idx_outer);
                        idx_outer <= idx_outer + 1;
                        state <= OUTER_LOOP;
                    end
                end
                FIND_MAX: begin
                    if (idx_find_max < N) begin
                        $display("FIND_MAX: Comparing dp[%0d]=%0d with current max dp=%0d at index=%0d", 
                                 idx_find_max, dp[idx_find_max], R5, R6);
                        if (dp[idx_find_max] > R5) begin
                            R5 <= dp[idx_find_max];
                            R6 <= idx_find_max;
                            $display("FIND_MAX: New max dp found. R5 <= %0d, R6 <= %0d", R5, R6);
                        end
                        idx_find_max <= idx_find_max + 1;
                    end else begin
                        $display("FIND_MAX: Completed finding max. Max dp=%0d at index=%0d", R5, R6);
                        lis_length <= 0;
                        state <= RESTORE_LIS;
                    end
                end
                RESTORE_LIS: begin
                    if (R6 !== -8'sd1) begin  // Корректное сравнение с -1
                        $display("RESTORE_LIS: Adding arr[%0d]=%0d to LIS at lis[%0d]", R6, arr[R6], lis_length);
                        lis[lis_length] <= arr[R6];
                        lis_length <= lis_length + 1;
                        $display("RESTORE_LIS: Updated lis_length <= %0d", lis_length);
                        $display("RESTORE_LIS: Moving to previous index prev[%0d]=%0d", R6, prev[R6]);
                        R6 <= prev[R6];
                    end else begin
                        $display("RESTORE_LIS: Completed restoring LIS. lis_length=%0d", lis_length);
                        // После восстановления, настройка для реверса
                        idx_reverse_start <= 0;
                        idx_reverse_end <= lis_length - 1;
                        state <= REVERSE_LIS;
                    end
                end
                REVERSE_LIS: begin
                    if (idx_reverse_start < idx_reverse_end) begin
                        $display("REVERSE_LIS: Swapping lis[%0d]=%0d <-> lis[%0d]=%0d", 
                                 idx_reverse_start, lis[idx_reverse_start], idx_reverse_end, lis[idx_reverse_end]);
                        // Используем блокирующие присваивания для корректного обмена
                        temp = lis[idx_reverse_start];
                        lis[idx_reverse_start] = lis[idx_reverse_end];
                        lis[idx_reverse_end] = temp;
                        $display("RESTORE_LIS: Updated lis_length <= %0d", lis_length + 1);
                        $display("REVERSE_LIS: After swap lis[%0d]=%0d, lis[%0d]=%0d", 
                                 idx_reverse_start, lis[idx_reverse_start], idx_reverse_end, lis[idx_reverse_end]);
                        idx_reverse_start <= idx_reverse_start + 1;
                        idx_reverse_end <= idx_reverse_end - 1;
                    end else begin
                        $display("REVERSE_LIS: Completed reversing LIS. Moving to OUTPUT_LIS.");
                        // После реверса, настройка для вывода
                        idx_output <= 0;
                        state <= OUTPUT_LIS;
                    end
                end
                OUTPUT_LIS: begin
                    if (idx_output < lis_length) begin
                        result[idx_output] <= lis[idx_output];
                        $display("OUTPUT_LIS: result[%0d] <= lis[%0d]=%0d", 
                                 idx_output, idx_output, lis[idx_output]);
                        idx_output <= idx_output + 1;
                    end else begin
                        $display("OUTPUT_LIS: Completed output. Final LIS:");
                        for (i = 0; i < lis_length; i = i + 1) begin
                            $display("LIS[%0d] = %0d", i, lis[i]);
                        end
                        state <= DONE_STATE;
                        done <= 1;
                        $display("DONE: LIS processing completed.");
                    end
                end
                DONE_STATE: begin
                    // Ожидание сброса
                    $display("DONE: Waiting for reset.");
                end
                default: begin
                    state <= DONE_STATE;
                    $display("DEFAULT: Undefined state. Moving to DONE.");
                end
            endcase
        end end
endmodule
```


### fsm_CleanForm.v
```verilog
module LIS_processor(
    input clk, 
    input reset,
    input start,
    output reg done
);

    parameter N = 10;
    parameter MAX_SIZE = 100;
    integer i;
    reg [7:0] arr [0:9]; // входная последовательность (вводится заранее)
    reg [7:0] dp [0:MAX_SIZE-1]; 
    reg signed [7:0] prev [0:MAX_SIZE-1];
    reg [7:0] lis [0:MAX_SIZE-1]; 
    reg [7:0] result [0:MAX_SIZE-1]; // последовательно которая формируется на выходе

    reg signed [7:0] idx_init;
    reg signed [7:0] idx_outer;
    reg signed [7:0] idx_inner;
    reg signed [7:0] idx_find_max;
    reg signed [7:0] R5;
    reg signed [7:0] R6;
    reg signed [7:0] lis_length;
    reg [7:0] temp;

    reg signed [7:0] idx_reverse_start;
    reg signed [7:0] idx_reverse_end;
    reg signed [7:0] idx_output;

    reg [3:0] state;
    parameter INIT_LOOP = 0, OUTER_LOOP = 1, INNER_LOOP = 2, FIND_MAX = 3,
              RESTORE_LIS = 4, REVERSE_LIS = 5, OUTPUT_LIS = 6, DONE_STATE = 7;

    // инициализация массива и очищение двух других массивов (не входит в сам алгоритм программы) 
    initial begin
        arr[0] = 3;  arr[1] = 10; arr[2] = 2;  arr[3] = 11;
        arr[4] = 1;  arr[5] = 20; arr[6] = 15; arr[7] = 30;
        arr[8] = 25; arr[9] = 28;

    for (i = 0; i < N; i = i + 1) begin
        dp[i] <= 0;
        prev[i] <= -1;
    end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INIT_LOOP;
            idx_init <= 0;
            done <= 0;
            idx_outer <= 0;
            idx_inner <= 0;
            idx_find_max <= 0;
            R5 <= 0;
            R6 <= -1;
            lis_length <= 0;
            idx_reverse_start <= 0;
            idx_reverse_end <= 0;
            idx_output <= 0;

        end else begin
            case (state)
                INIT_LOOP: begin
                    if (idx_init < N) begin
                        dp[idx_init] <= 1;
                        prev[idx_init] <= -1;
                        idx_init <= idx_init + 1;
                    end else begin
                        idx_outer <= 1;
                        state <= OUTER_LOOP;
                    end
                end
                OUTER_LOOP: begin
                    if (idx_outer < N) begin
                        idx_inner <= 0;
                        state <= INNER_LOOP;
                    end else begin
                        idx_find_max <= 0;
                        R5 <= 0;
                        R6 <= -1;
                        state <= FIND_MAX;
                    end
                end
                INNER_LOOP: begin
                    if (idx_inner < idx_outer) begin
                        if (arr[idx_inner] < arr[idx_outer]) begin
                            if (dp[idx_outer] < dp[idx_inner] + 1) begin
                                dp[idx_outer] <= dp[idx_inner] + 1;
                                prev[idx_outer] <= idx_inner;
                            end else begin
                            end
                        end
                        idx_inner <= idx_inner + 1;
                    end else begin
                        idx_outer <= idx_outer + 1;
                        state <= OUTER_LOOP;
                    end
                end
                FIND_MAX: begin
                    if (idx_find_max < N) begin
                        if (dp[idx_find_max] > R5) begin
                            R5 <= dp[idx_find_max];
                            R6 <= idx_find_max;
                        end
                        idx_find_max <= idx_find_max + 1;
                    end else begin
                        lis_length <= 0;
                        state <= RESTORE_LIS;
                    end
                end
                RESTORE_LIS: begin
                    if (R6 !== -8'sd1) begin  // как лучше проверять на -1 в процессорном ядре?
                        lis[lis_length] <= arr[R6];
                        lis_length <= lis_length + 1;
                        R6 <= prev[R6];
                    end else begin
                        idx_reverse_start <= 0;
                        idx_reverse_end <= lis_length - 1;
                        state <= REVERSE_LIS;
                    end
                end
                REVERSE_LIS: begin
                    if (idx_reverse_start < idx_reverse_end) begin
                        // Используем блокирующие присваивания для корректного обмена (проверить что процессорное ядро будет обрабатывать их корректно)
                        temp = lis[idx_reverse_start];
                        lis[idx_reverse_start] = lis[idx_reverse_end];
                        lis[idx_reverse_end] = temp;
                        idx_reverse_start <= idx_reverse_start + 1;
                        idx_reverse_end <= idx_reverse_end - 1;
                    end else begin
                        // После реверса, настройка для вывода
                        idx_output <= 0;
                        state <= OUTPUT_LIS;
                    end
                end
                OUTPUT_LIS: begin
                    if (idx_output < lis_length) begin
                        result[idx_output] <= lis[idx_output];
                        idx_output <= idx_output + 1;
                    end else begin
                        state <= DONE_STATE;
                        done <= 1;
                    end
                end
                default: begin
                end
            endcase
        end end
endmodule
```

### test_fsm_CleanForm.v
```verilog
`timescale 1ns / 1ps

module tb_LIS_processor();

    // Testbench uses the same parameter as the LIS_processor
    parameter N = 10;
    parameter MAX_SIZE = 100;

    // Internal signals to connect to the DUT
    reg clk;
    reg reset;
    reg start;
    wire done;

    // Instantiate the LIS_processor
    LIS_processor #(
        .N(N),
        .MAX_SIZE(MAX_SIZE)
    ) DUT (
        .clk(clk),
        .reset(reset),
        .start(start),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate a clock with a period of 10 ns
    end

    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        start = 0;

        // Apply reset
        #10;
        reset = 0;
        start = 1;

        // Wait for the processor to finish
        wait(done);

        // Read and print the results
        $display("LIS computation finished.");
        printLIS();

        // End the simulation
        #100;
        $finish;
    end

    // Task to print the LIS computed by the processor
    task printLIS;
        integer i;
        begin
            $display("Longest Increasing Subsequence (LIS):");
            for (i = 0; i < DUT.lis_length; i = i + 1) begin
                $write("%d ", DUT.result[i]);
            end
            $display(""); // Newline
        end
    endtask

endmodule
```

### o1_preview
```verilog
module SimpleProcessor(
    input clk,
    input reset,
    output reg [7:0] pc,
    output reg halted,
    output reg zero_flag,
    output reg sign_flag
);

    // Определение инструкций
    parameter NOP   = 4'd0;
    parameter LOAD  = 4'd1;
    parameter STORE = 4'd2;
    parameter ADD   = 4'd3;
    parameter SUB   = 4'd4;
    parameter CMP   = 4'd5;
    parameter JMP   = 4'd6;
    parameter JLE   = 4'd7;
    parameter JGE   = 4'd8;
    parameter MOV   = 4'd9;
    parameter INC   = 4'd10;
    parameter DEC   = 4'd11;
    parameter HALT  = 4'd15;

    integer arr_start = 0;
    integer dp_start = 100;
    integer prev_start = 200;
    integer lis_start = 300;
    integer result_start = 400;

    reg [15:0] instruction;
    reg [15:0] memory [0:255];
    reg [7:0] data_mem [0:511];
    reg [15:0] regfile [0:15]; // 16 регистров

    // Декодирование инструкции
    wire [3:0] opcode     = instruction[15:12];
    wire [3:0] reg_dest   = instruction[11:8];
    wire [3:0] reg_base   = instruction[7:4];
    wire [3:0] reg_offset = instruction[3:0];
    wire [15:0] immediate  = instruction[15:0];

    integer idx;
    integer i;
    integer j;

    // Инициализация Памяти Инструкций
    initial begin
        // Пример Явной Инициализации
        memory[0] = {4'd9, 4'd8, arr_start[7:0]};     // MOV R8, #arr_start
        memory[1] = {4'd9, 4'd9, dp_start[7:0]};      // MOV R9, #dp_start
        memory[2] = {4'd9, 4'd10, prev_start[7:0]};   // MOV R10, #prev_start
        memory[3] = {4'd9, 4'd11, lis_start[7:0]};    // MOV R11, #lis_start
        memory[4] = {4'd9, 4'd12, result_start[7:0]}; // MOV R12, #result_start

        // Инициализация idx_init = 0 (R0)
        memory[5] = {4'd9, 4'd0, 8'd0};               // MOV R0, #0

        // init_loop:
        memory[6] = {4'd5, 4'd0, 8'd10};               // CMP R0, #N
        memory[7] = {4'd8, 8'd14};                    // JGE outer_loop

        // dp[idx_init] = 1
        memory[8] = {4'd9, 4'd1, 8'd1};               // MOV R1, #1
        memory[9] = {4'd2, 4'd1, 4'd9, 4'd0};         // STORE R1, [R9 + R0]

        // prev[idx_init] = -1
        memory[10] = {4'd9, 4'd1, 8'd255};            // MOV R1, #-1 (255)
        memory[11] = {4'd2, 4'd1, 4'd10, 4'd0};       // STORE R1, [R10 + R0]

        // idx_init++
        memory[12] = {4'd10, 4'd0, 8'd0};             // INC R0

        // JMP init_loop
        memory[13] = {4'd6, 8'd6};                    // JMP addr 6

        // outer_loop:
        memory[14] = {4'd9, 4'd2, 4'd0};              // MOV R2, R0 (idx_outer = idx_init)

        memory[15] = {4'd5, 4'd2, 8'd10};              // CMP R2, #N
        memory[16] = {4'd8, 8'd44};                   // JGE find_max

        // idx_inner = 0
        memory[17] = {4'd9, 4'd1, 8'd0};              // MOV R1, #0

        // inner_loop:
        memory[18] = {4'd5, 4'd1, 4'd2};              // CMP R1, R2
        memory[19] = {4'd8, 8'd39};                   // JGE increment_outer

        // arr[idx_inner] в R3
        memory[20] = {4'd1, 4'd3, 4'd8, 4'd1};        // LOAD R3, [R8 + R1]

        // arr[idx_outer] в R4
        memory[21] = {4'd1, 4'd4, 4'd8, 4'd2};        // LOAD R4, [R8 + R2]

        // CMP R3, R4
        memory[22] = {4'd5, 4'd3, 4'd4};              // CMP R3, R4

        // JGE skip_if_not_less
        memory[23] = {4'd8, 8'd27};                   // JGE skip_if_not_less

        // dp[idx_inner] в R5
        memory[24] = {4'd1, 4'd5, 4'd9, 4'd1};        // LOAD R5, [R9 + R1]

        // R5 = R5 + 1
        memory[25] = {4'd10, 4'd5, 8'd0};             // INC R5

        // dp[idx_outer] в R6
        memory[26] = {4'd1, 4'd6, 4'd9, 4'd2};        // LOAD R6, [R9 + R2]

        // CMP R5, R6
        memory[27] = {4'd5, 4'd5, 4'd6};              // CMP R5, R6

        // JLE skip_update_dp
        memory[28] = {4'd7, 8'd31};                   // JLE skip_update_dp

        // dp[idx_outer] = R5
        memory[29] = {4'd2, 4'd5, 4'd9, 4'd2};        // STORE R5, [R9 + R2]

        // prev[idx_outer] = idx_inner (R1)
        memory[30] = {4'd2, 4'd1, 4'd10, 4'd2};       // STORE R1, [R10 + R2]

        // skip_update_dp:
        // skip_if_not_less:
        // idx_inner++
        memory[31] = {4'd10, 4'd1, 8'd0};             // INC R1

        // JMP inner_loop
        memory[32] = {4'd6, 8'd18};                   // JMP addr 18

        // increment_outer:
        memory[39] = {4'd0, 12'd0};                   // NOP (заполнение адресов)

        // idx_outer++
        memory[40] = {4'd10, 4'd2, 8'd0};             // INC R2

        // idx_init = idx_outer
        memory[41] = {4'd9, 4'd0, 4'd2};              // MOV R0, R2

        // JMP outer_loop
        memory[42] = {4'd6, 8'd15};                   // JMP addr 15

        // find_max:
        memory[44] = {4'd9, 4'd0, 8'd0};              // MOV R0, #0

        // max_length = 0 (R5), max_idx = -1 (R6)
        memory[45] = {4'd9, 4'd5, 8'd0};              // MOV R5, #0
        memory[46] = {4'd9, 4'd6, 8'd255};            // MOV R6, #-1

        // find_max_loop:
        memory[47] = {4'd5, 4'd0, 8'd10};              // CMP R0, #N
        memory[48] = {4'd8, 8'd56};                   // JGE restore_lis

        // dp[idx] в R7
        memory[49] = {4'd1, 4'd7, 4'd9, 4'd0};        // LOAD R7, [R9 + R0]

        // CMP R7, R5
        memory[50] = {4'd5, 4'd7, 4'd5};              // CMP R7, R5

        // JLE skip_update_max
        memory[51] = {4'd7, 8'd54};                   // JLE skip_update_max

        // max_length = R7
        memory[52] = {4'd9, 4'd5, 4'd7};              // MOV R5, R7

        // max_idx = R0
        memory[53] = {4'd9, 4'd6, 4'd0};              // MOV R6, R0

        // skip_update_max:
        // idx++
        memory[54] = {4'd10, 4'd0, 8'd0};             // INC R0

        // JMP find_max_loop
        memory[55] = {4'd6, 8'd47};                   // JMP addr 47

        // restore_lis:
        memory[56] = {4'd9, 4'd7, 8'd0};              // MOV R7, #0  ; lis_length = 0

        // restore_loop:
        memory[57] = {4'd5, 4'd6, 8'd255};            // CMP R6, #-1
        memory[58] = {4'd8, 8'd66};                   // JLE reverse_lis

        // arr[max_idx] в R0
        memory[59] = {4'd1, 4'd0, 4'd8, 4'd6};        // LOAD R0, [R8 + R6]

        // lis[lis_length] = R0
        memory[60] = {4'd2, 4'd0, 4'd11, 4'd7};       // STORE R0, [R11 + R7]

        // lis_length++
        memory[61] = {4'd10, 4'd7, 8'd0};             // INC R7

        // R6 = prev[max_idx]
        memory[62] = {4'd1, 4'd6, 4'd10, 4'd6};       // LOAD R6, [R10 + R6]

        // JMP restore_loop
        memory[63] = {4'd6, 8'd57};                   // JMP addr 57

        // reverse_lis:
        memory[66] = {4'd9, 4'd1, 8'd0};              // MOV R1, #0      ; idx_start
        memory[67] = {4'd9, 4'd2, 4'd7};              // MOV R2, R7      ; idx_end = lis_length
        memory[68] = {4'd11, 4'd2, 8'd0};             // DEC R2          ; idx_end--

        // reverse_loop:
        memory[69] = {4'd5, 4'd1, 4'd2};              // CMP R1, R2
        memory[70] = {4'd8, 8'd78};                   // JGE output_result

        // lis[idx_start] в R3
        memory[71] = {4'd1, 4'd3, 4'd11, 4'd1};       // LOAD R3, [R11 + R1]

        // lis[idx_end] в R4
        memory[72] = {4'd1, 4'd4, 4'd11, 4'd2};       // LOAD R4, [R11 + R2]

        // lis[idx_start] = R4
        memory[73] = {4'd2, 4'd4, 4'd11, 4'd1};       // STORE R4, [R11 + R1]

        // lis[idx_end] = R3
        memory[74] = {4'd2, 4'd3, 4'd11, 4'd2};       // STORE R3, [R11 + R2]

        // idx_start++
        memory[75] = {4'd10, 4'd1, 8'd0};             // INC R1

        // idx_end--
        memory[76] = {4'd11, 4'd2, 8'd0};             // DEC R2

        // JMP reverse_loop
        memory[77] = {4'd6, 8'd69};                   // JMP addr 69

        // output_result:
        memory[78] = {4'd9, 4'd0, 8'd0};              // MOV R0, #0      ; idx_output = 0

        // output_loop:
        memory[79] = {4'd5, 4'd0, 4'd7};              // CMP R0, R7
        memory[80] = {4'd8, 8'd86};                   // JGE finish

        // lis[idx_output] в R1
        memory[81] = {4'd1, 4'd1, 4'd11, 4'd0};       // LOAD R1, [R11 + R0]

        // result[idx_output] = R1
        memory[82] = {4'd2, 4'd1, 4'd12, 4'd0};       // STORE R1, [R12 + R0]

        // idx_output++
        memory[83] = {4'd10, 4'd0, 8'd0};             // INC R0

        // JMP output_loop
        memory[84] = {4'd6, 8'd79};                   // JMP addr 79

        // finish:
        memory[86] = {4'd15, 12'd0};                  // HALT
        // Инициализация памяти данных значениями 0
        for (j = 0; j < 512; j = j + 1) begin
            data_mem[j] = 8'd0;
        end

        // Инициализация Памяти Данных
        data_mem[arr_start + 0] = 8'd3;
        data_mem[arr_start + 1] = 8'd10;
        data_mem[arr_start + 2] = 8'd2;
        data_mem[arr_start + 3] = 8'd11;
        data_mem[arr_start + 4] = 8'd1;
        data_mem[arr_start + 5] = 8'd20;
        data_mem[arr_start + 6] = 8'd15;
        data_mem[arr_start + 7] = 8'd30;
        data_mem[arr_start + 8] = 8'd25;
        data_mem[arr_start + 9] = 8'd28;
    end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        pc <= 0;
        halted <= 0;
        zero_flag <= 0;
        sign_flag <= 0;
        for (idx = 0; idx < 16; idx = idx + 1) begin
            regfile[idx] <= 0;
        end
        // Инициализация регистров и памяти при необходимости
    end else if (!halted) begin
        instruction <= memory[pc];
        pc <= pc + 1;

        case (opcode)
            NOP: begin
                // Нет операции
            end
            MOV: begin
                if (instruction[7:4] == 4'd0) begin
                    // MOV Rdest, Rsrc
                    regfile[reg_dest] <= regfile[instruction[3:0]];
                end else begin
                    // MOV Rdest, #immediate
                    regfile[reg_dest][7:0] <= instruction[7:0]; // Загрузка младших 8 бит
                    // Старшие 8 бит должны быть установлены отдельной инструкцией
                end
            end
            ADD: begin
                regfile[reg_dest] <= regfile[reg_base] + regfile[reg_offset];
            end
            SUB: begin
                regfile[reg_dest] <= regfile[reg_base] - regfile[reg_offset];
            end
            INC: begin
                regfile[reg_dest] <= regfile[reg_dest] + 1;
            end
            DEC: begin
                regfile[reg_dest] <= regfile[reg_dest] - 1;
            end
            CMP: begin
                if (regfile[reg_dest] == regfile[reg_base])
                    zero_flag <= 1;
                else
                    zero_flag <= 0;
                if ($signed(regfile[reg_dest]) < $signed(regfile[reg_base]))
                    sign_flag <= 1;
                else
                    sign_flag <= 0;
                $display("CMP: R%d=%d, R%d=%d | Zero: %b, Sign: %b", reg_dest, regfile[reg_dest], reg_base, regfile[reg_base], zero_flag, sign_flag);
            end
            JMP: begin
                pc <= immediate;
            end
            JLE: begin
                if (sign_flag || zero_flag)
                    pc <= immediate;
            end
            JGE: begin
                if (!sign_flag)
                    pc <= immediate;
            end
            LOAD: begin
                regfile[reg_dest] <= {8'd0, data_mem[ regfile[reg_base] + regfile[reg_offset] ]};
            end
            STORE: begin
                data_mem[ regfile[reg_base] + regfile[reg_offset] ] <= regfile[reg_dest][7:0];
                $display("STORE: Writing %d to data_mem[%d] at time %0t", regfile[reg_dest][7:0], regfile[reg_base] + regfile[reg_offset], $time);
            end
            HALT: begin
                halted <= 1;
            end
            default: begin
                // Неизвестная инструкция
            end
        endcase
    end
end

always @(posedge clk) begin
    if (!reset && !halted) begin
        $display("Time: %0t | PC: %d | Instruction: %h", $time, pc, instruction);
        $display("Registers: R0=%d, R1=%d, R2=%d, R3=%d, R4=%d, R5=%d, R6=%d, R7=%d, R8=%d, R9=%d, R10=%d, R11=%d, R12=%d, R13=%d, R14=%d, R15=%d",
                 regfile[0], regfile[1], regfile[2], regfile[3],
                 regfile[4], regfile[5], regfile[6], regfile[7],
                 regfile[8], regfile[9], regfile[10], regfile[11],
                 regfile[12], regfile[13], regfile[14], regfile[15]);
        $display("Zero flag: %b, Sign flag: %b", zero_flag, sign_flag);
    end
end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;
            halted <= 0;
            zero_flag <= 0;
            sign_flag <= 0;
            for (idx = 0; idx < 16; idx = idx + 1) begin
                regfile[idx] <= 0;
            end
            // Инициализация регистров и памяти при необходимости
        end else if (!halted) begin
            instruction <= memory[pc];
            pc <= pc + 1;

            case (opcode)
                NOP: begin
                    // Нет операции
                end
                MOV: begin
                    if (immediate[7:4] == 4'd0) begin
                        // MOV Rdest, Rsrc
                        regfile[reg_dest] <= regfile[immediate[3:0]];
                    end else begin
                        // MOV Rdest, #immediate
                        regfile[reg_dest] <= immediate;
                    end
                end
                ADD: begin
                    regfile[reg_dest] <= regfile[reg_base] + regfile[reg_offset];
                end
                SUB: begin
                    regfile[reg_dest] <= regfile[reg_base] - regfile[reg_offset];
                end
                INC: begin
                    regfile[reg_dest] <= regfile[reg_dest] + 1;
                end
                DEC: begin
                    regfile[reg_dest] <= regfile[reg_dest] - 1;
                end
                CMP: begin
                    if (regfile[reg_dest] == regfile[reg_base])
                        zero_flag <= 1;
                    else
                        zero_flag <= 0;
                    if ($signed(regfile[reg_dest]) < $signed(regfile[reg_base]))
                        sign_flag <= 1;
                    else
                        sign_flag <= 0;
                    $display("CMP: R%d=%d, R%d=%d | Zero: %b, Sign: %b", reg_dest, regfile[reg_dest], reg_base, regfile[reg_base], zero_flag, sign_flag);
                end
                JMP: begin
                    pc <= immediate;
                end
                JLE: begin
                    if (sign_flag || zero_flag)
                        pc <= immediate;
                end
                JGE: begin
                    if (!sign_flag)
                        pc <= immediate;
                end
                LOAD: begin
                    regfile[reg_dest] <= data_mem[ regfile[reg_base] + regfile[reg_offset] ];
                end
                STORE: begin
                    data_mem[ regfile[reg_base] + regfile[reg_offset] ] <= regfile[reg_dest];
                    $display("STORE: Writing %d to data_mem[%d] at time %0t", regfile[reg_dest], regfile[reg_base] + regfile[reg_offset], $time);
                end
                HALT: begin
                    halted <= 1;
                end
                default: begin
                    // Неизвестная инструкция
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (!reset && !halted) begin
            $display("Time: %0t | PC: %d | Instruction: %h", $time, pc, instruction);
            $display("Registers: R0=%d, R1=%d, R2=%d, R3=%d, R4=%d, R5=%d, R6=%d, R7=%d", regfile[0], regfile[1], regfile[2], regfile[3], regfile[4], regfile[5], regfile[6], regfile[7]);
            $display("Zero flag: %b, Sign flag: %b", zero_flag, sign_flag);
        end
    end


endmodule
```

```verilog
`timescale 1ns/1ps

module SimpleProcessor_tb;

    // Входы
    reg clk;
    reg reset;

    // Выходы
    wire [7:0] pc;
    wire halted;
    wire zero_flag;
    wire sign_flag;

    // Параметры для доступа к памяти данных
    integer result_start = 400;
    integer lis_length;

    integer i;
    
    // Экземпляр тестируемого модуля
    SimpleProcessor uut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .halted(halted),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag)
    );

    // Генерация тактового сигнала с периодом 10 нс
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Переключение состояния каждые 5 нс
    end

    // Инициализация сигнала reset
    initial begin
        reset = 1;
        #20;           // Сохраняем сигнал reset активным на первых 20 нс
        reset = 0;     // Деактивируем reset
    end

    // Мониторинг важных сигналов
    initial begin
        // Отслеживаем изменения сигналов и выводим их
        $monitor("Time: %0t | PC: %d | Halted: %b | Zero Flag: %b | Sign Flag: %b",
                 $time, pc, halted, zero_flag, sign_flag);
    end

    // Завершение симуляции и вывод результирующей LIS при достижении состояния HALT
    initial begin
        // Ожидаем, пока сигнал halted станет высоким
        wait (halted == 1);
        #10; // Небольшая задержка для завершения всех операций

        // Получение длины LIS из регистра R7 (предполагается, что R7 содержит lis_length)
        lis_length = uut.regfile[7]; // Обратите внимание на индекс регистра (R7)

        // Проверка, что длина LIS не превышает допустимый диапазон
        if (lis_length > 100) begin
            $display("Ошибка: Длина LIS (%0d) превышает допустимый диапазон.", lis_length);
            $finish;
        end

        // Вывод результирующей LIS
        $display("Resulting LIS (Length: %0d):", lis_length);
 
        for (i = 0; i < lis_length; i = i + 1) begin
            $display("Result[%0d]: %0d", i, uut.data_mem[result_start + i]);
        end

        $display("Simulation finished at time %0t", $time);
        $finish;
    end

    // Дополнительная отладочная информация (опционально)
    // Можно добавить, если требуется более детальная отладка
    /*
    always @(posedge clk) begin
        if (!reset && !halted) begin
            $display("PC: %d | Instruction: %h", pc, uut.instruction);
            // Добавьте вывод регистров или других сигналов, если необходимо
        end
    end
    */

endmodule
```
## Система команд
Чтобы реализовать систему команд и сгенерировать программу в формате `.mem`, нам нужно определить набор инструкций, которые будут отображать операции, выполняемые в алгоритме.  Предлагаю следующую систему команд и соответствующую ей программу:

**Система команд:**

| Команда          | Операнды                                       | Описание                                                                           |
| ---------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------- |
| `LD R, addr`     | `R` - регистр (R1-R7), `addr` - адрес в памяти | Загрузить значение из памяти по адресу `addr` в регистр `R`                        |
| `ST R, addr`     | `R` - регистр (R1-R7), `addr` - адрес в памяти | Сохранить значение из регистра `R` в память по адресу `addr`                       |
| `ADD R1, R2, R3` | `R1, R2, R3` - регистры                        | `R1 = R2 + R3`                                                                     |
| `SUB R1, R2, R3` | `R1, R2, R3` - регистры                        | `R1 = R2 - R3`                                                                     |
| `CMP R1, R2`     | `R1, R2` - регистры                            | Сравнить значения регистров `R1` и `R2` и установить флаги (Z - равно, N - меньше) |
| `BEQ addr`       | `addr` - адрес в памяти                        | Перейти по адресу `addr`, если Z=1                                                 |
| `BNE addr`       | `addr` - адрес в памяти                        | Перейти по адресу `addr`, если Z=0                                                 |
| `BLT addr`       | `addr` - адрес в памяти                        | Перейти по адресу `addr`, если N=1                                                 |
| `JMP addr`       | `addr` - адрес в памяти                        | Безусловный переход по адресу `addr`                                               |
| `HALT`           |                                                | Остановить выполнение программы                                                    |
|                  |                                                |                                                                                    |


**Программа в формате .mem (пример, требует доработки и оптимизации):**

```assembly
// Инициализация
LD R1, arr_start  // R1 - указатель на начало массива arr
LD R2, dp_start   // R2 - указатель на начало массива dp
LD R3, prev_start // R3 - указатель на начало массива prev
LD R4, N          // R4 - размер массива (N)
LD R5, 1          // R5 - константа 1
LD R6, -1         // R6 - константа -1

init_loop:
ST R5, [R2]      // dp[i] = 1
ST R6, [R3]      // prev[i] = -1
ADD R2, R2, 1    // Увеличить указатель dp
ADD R3, R3, 1    // Увеличить указатель prev
SUB R4, R4, 1    // Декремент счетчика цикла
BNE init_loop

// ... (Остальной код для OUTER_LOOP, INNER_LOOP, FIND_MAX, RESTORE_LIS, REVERSE_LIS, OUTPUT_LIS) ...

halt:
HALT

// Данные (адреса начала массивов и значение N)
arr_start:  0x1000
dp_start:   0x2000
prev_start: 0x3000
N:          10

// ... (данные массива arr) ...
```

**Пояснения и дальнейшие шаги:**
* **Соответствие состояний и команд:** Каждое состояние в Verilog коде должно быть преобразовано в последовательность команд. Например,  блок `INIT_LOOP`  в коде Verilog реализуется  меткой `init_loop` и последующими командами в ассемблерном коде.
* **Регистры:**  Используйте регистры R1-R7 для хранения промежуточных значений и указателей.  R5 и R6 в данном примере используются для хранения констант 1 и -1.
* **Адресация памяти:**  `arr_start`, `dp_start`, `prev_start` - это символические адреса начала массивов в памяти.  В реальной программе  нужно заменить их на конкретные адреса.  Обращение к элементам массива осуществляется с помощью косвенной адресации (например, `ST R5, [R2]`  -  сохранить R5 по адресу, хранящемуся в R2).
* **Условные переходы:** Используйте команды сравнения (`CMP`) и условные переходы (`BEQ`, `BNE`, `BLT`) для реализации  условной логики  в  `if-else`  блоках.
* **Реализация сложных операций:**  Некоторые операции, такие как поиск максимума (`FIND_MAX`) и реверс массива (`REVERSE_LIS`), потребуют более сложных последовательностей команд.  Возможно, потребуется разбить их на подпрограммы.
* **Обработка отрицательных чисел:** В системе команд  используется  дополнительный код для представления отрицательных чисел.


Этот пример предоставляет базовый каркас. Вам необходимо  заполнить  пропущенный код  (`// ...`)  и  адаптировать  его  под  конкретные требования  вашей  задачи.  Также  рекомендуется  оптимизировать  полученный  код  для  уменьшения  его  размера  и  повышения  производительности.

```verilog
`timescale 1ns / 1ps

module LIS_processor_instruction_mem(
    output reg [15:0] instruction,
    input clk,
    input [7:0] program_counter
);

  reg [15:0] memory [0:255];

  initial begin
    // Инициализация
    memory[0] = 16'b0001_0001_0100_0000;  // LD R1, arr_start
    memory[1] = 16'b0001_0010_0100_0001;  // LD R2, dp_start
    memory[2] = 16'b0001_0011_0100_0010;  // LD R3, prev_start
    memory[3] = 16'b0001_0100_0100_0011;  // LD R4, N
    memory[4] = 16'b0001_0101_0000_0100;  // LD R5, 1
    memory[5] = 16'b0001_0110_0000_0101;  // LD R6, -1

    // init_loop:
    memory[6] = 16'b0010_0101_0010_0000;  // ST R5, [R2]
    memory[7] = 16'b0010_0110_0011_0000;  // ST R6, [R3]
    memory[8] = 16'b0011_0010_0010_0101;  // ADD R2, R2, 1
    memory[9] = 16'b0011_0011_0011_0101;  // ADD R3, R3, 1
    memory[10] = 16'b0100_0100_0100_0101; // SUB R4, R4, 1
    memory[11] = 16'b1001_0000_0000_0000 | 6; // BNE init_loop

    // outer_loop:
    memory[12] = 16'b0001_0111_0000_0000; // LD R7, 0 // idx_inner = 0

    // inner_loop:
    memory[13] = 16'b0101_0111_0100_0000; // CMP R7, R4
    memory[14] = 16'b1010_0000_0000_0000 | 22; // BLT inner_loop_body
    memory[15] = 16'b1011_0000_0000_0000 | 19; // JMP outer_loop_end

    // inner_loop_body:
    memory[22] = 16'b0100_0000_0001_0111; // SUB R0, R1, R7 // R0 = idx_outer - idx_inner (for arr access)
    memory[23] = 16'b0001_0000_0100_0000 | 256; // LD R0, arr[idx_outer]
    memory[24] = 16'b0100_0000_0001_0111; // SUB R0, R1, R7 // R0 = idx_outer - idx_inner (for arr access)
    memory[25] = 16'b0001_0101_0100_0000 | 256; // LD R5, arr[idx_inner]
    memory[26] = 16'b0101_0101_0000_0000; // CMP R5, R0  // arr[idx_inner] < arr[idx_outer]
    memory[27] = 16'b1010_0000_0000_0000 | 30; // BLT if_body
    memory[28] = 16'b1011_0000_0000_0000 | 36; // JMP inner_loop_end

    // if_body:
    // ... (инструкции для обновления dp и prev)
    memory[30] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[31] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[32] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[33] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[34] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[35] = 16'b1011_0000_0000_0000 | 36; // JMP inner_loop_end

    // inner_loop_end:
    memory[36] = 16'b0011_0111_0111_0101; // ADD R7, R7, 1
    memory[37] = 16'b1011_0000_0000_0000 | 13; // JMP inner_loop


    // outer_loop_end:
    memory[19] = 16'b0011_0100_0100_0101; // ADD R4, R4, 1
    memory[20] = 16'b0101_0100_0100_0011; // CMP R4, N
    memory[21] = 16'b1001_0000_0000_0000 | 12; // BNE outer_loop

    // ... (find_max, restore_lis, reverse_lis, output_lis, halt) ...  //  Add instructions for these states

    memory[100] = 16'b1111_0000_0000_0000; // HALT

    // Data
    memory[256] = 256;    // arr_start
    memory[257] = 260;   // dp_start
    memory[258] = 270;  // prev_start
    memory[259] = 10;      // N
    // ... (arr data from 256 onwards) ...
     // ... (dp data from 260 onwards) ...
     // ... (prev data from 270 onwards) ...

  end

  always @(posedge clk) begin
    instruction <= memory[program_counter];
  end

endmodule
```

```verilog
`timescale 1ns / 1ps

module LIS_processor_instruction_mem(
    output reg [15:0] instruction,
    input clk,
    input [7:0] program_counter
);

  reg [15:0] memory [0:255];

  initial begin
    // Инициализация
    memory[0] = 16'b0001_0001_0100_0000;  // LD R1, arr_start
    memory[1] = 16'b0001_0010_0100_0001;  // LD R2, dp_start
    memory[2] = 16'b0001_0011_0100_0010;  // LD R3, prev_start
    memory[3] = 16'b0001_0100_0100_0011;  // LD R4, N
    memory[4] = 16'b0001_0101_0000_0100;  // LD R5, 1
    memory[5] = 16'b0001_0110_0000_0101;  // LD R6, -1

    // init_loop:
    memory[6] = 16'b0010_0101_0010_0000;  // ST R5, [R2]
    memory[7] = 16'b0010_0110_0011_0000;  // ST R6, [R3]
    memory[8] = 16'b0011_0010_0010_0101;  // ADD R2, R2, 1
    memory[9] = 16'b0011_0011_0011_0101;  // ADD R3, R3, 1
    memory[10] = 16'b0100_0100_0100_0101; // SUB R4, R4, 1
    memory[11] = 16'b1001_0000_0000_0000 | 6; // BNE init_loop

    // outer_loop:
    memory[12] = 16'b0001_0111_0000_0000; // LD R7, 0 // idx_inner = 0

    // inner_loop:
    memory[13] = 16'b0101_0111_0100_0000; // CMP R7, R4
    memory[14] = 16'b1010_0000_0000_0000 | 22; // BLT inner_loop_body
    memory[15] = 16'b1011_0000_0000_0000 | 19; // JMP outer_loop_end

    // inner_loop_body:
    memory[22] = 16'b0100_0000_0001_0111; // SUB R0, R1, R7 // R0 = idx_outer - idx_inner (for arr access)
    memory[23] = 16'b0001_0000_0100_0000 | 256; // LD R0, arr[idx_outer]
    memory[24] = 16'b0100_0000_0001_0111; // SUB R0, R1, R7 // R0 = idx_outer - idx_inner (for arr access)
    memory[25] = 16'b0001_0101_0100_0000 | 256; // LD R5, arr[idx_inner]
    memory[26] = 16'b0101_0101_0000_0000; // CMP R5, R0  // arr[idx_inner] < arr[idx_outer]
    memory[27] = 16'b1010_0000_0000_0000 | 30; // BLT if_body
    memory[28] = 16'b1011_0000_0000_0000 | 36; // JMP inner_loop_end

    // if_body:
    // ... (инструкции для обновления dp и prev)
    memory[30] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[31] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[32] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[33] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[34] = 16'b0000_0000_0000_0000; //  NOP - Placeholder, replace with actual instructions
    memory[35] = 16'b1011_0000_0000_0000 | 36; // JMP inner_loop_end

    // inner_loop_end:
    memory[36] = 16'b0011_0111_0111_0101; // ADD R7, R7, 1
    memory[37] = 16'b1011_0000_0000_0000 | 13; // JMP inner_loop


    // outer_loop_end:
    memory[19] = 16'b0011_0100_0100_0101; // ADD R4, R4, 1
    memory[20] = 16'b0101_0100_0100_0011; // CMP R4, N
    memory[21] = 16'b1001_0000_0000_0000 | 12; // BNE outer_loop

    // ... (find_max, restore_lis, reverse_lis, output_lis, halt) ...  //  Add instructions for these states

    memory[100] = 16'b1111_0000_0000_0000; // HALT

    // Data
    memory[256] = 256;    // arr_start
    memory[257] = 260;   // dp_start
    memory[258] = 270;  // prev_start
    memory[259] = 10;      // N
    // ... (arr data from 256 onwards) ...
     // ... (dp data from 260 onwards) ...
     // ... (prev data from 270 onwards) ...

  end

  always @(posedge clk) begin
    instruction <= memory[program_counter];
  end

endmodule
```


```verilog
`timescale 1ns / 1ps

module LIS_processor_instruction_mem(
    output reg [15:0] instruction,
    input clk,
    input [7:0] program_counter
);

  reg [15:0] memory [0:255];

  initial begin
    // ... (Initialization, init_loop, outer_loop, inner_loop, inner_loop_body, outer_loop_end - same as before) ...

    // find_max: (40)
    memory[40] = 16'b0001_0111_0000_0000; // 40: LD R7, 0 // idx_find_max = 0
    memory[41] = 16'b0001_0101_0000_0000; // 41: LD R5, 0 // R5 = max_val = 0
    memory[42] = 16'b0001_0110_0000_0101; // 42: LD R6, -1 // R6 = max_idx = -1

    // find_max_loop: (43)
    memory[43] = 16'b0101_0111_0100_0011; // 43: CMP R7, N
    memory[44] = 16'b1010_0000_0000_0000 | 47; // 44: BLT find_max_loop_body
    memory[45] = 16'b1011_0000_0000_0000 | 58; // 45: JMP restore_lis

    // find_max_loop_body: (47)
    memory[47] = 16'b0001_0000_0010_0000 | 260; // 47: LD R0, dp[idx_find_max]
    memory[48] = 16'b0101_0000_0101_0000; // 48: CMP R0, R5 // dp[idx] > max_val
    memory[49] = 16'b1010_0000_0000_0000 | 52; // 49: BLT update_max
    memory[50] = 16'b1011_0000_0000_0000 | 55; // 50: JMP find_max_loop_end

    // update_max: (52)
    memory[52] = 16'b0110_0101_0000_0000; // 52: MOV R5, R0 // max_val = dp[idx]
    memory[53] = 16'b0110_0110_0111_0000; // 53: MOV R6, R7 // max_idx = idx

    // find_max_loop_end: (55)
    memory[55] = 16'b0011_0111_0111_0101; // 55: ADD R7, R7, 1 // idx++
    memory[56] = 16'b1011_0000_0000_0000 | 43; // 56: JMP find_max_loop


    // restore_lis: (58)
    memory[58] = 16'b0001_0100_0000_0000; // 58: LD R4, 0  // lis_length = 0
    // restore_lis_loop: (59)
    memory[59] = 16'b0101_0110_0000_0101; // 59: CMP R6, -1
    memory[60] = 16'b1000_0000_0000_0000 | 70; // 60: BEQ reverse_lis

    // restore_lis_loop_body: (62)
    memory[62] = 16'b0000_0000_0000_0000; // 62: NOP - Placeholder (load arr[R6] into lis[R4])
    memory[63] = 16'b0011_0100_0100_0101; // 63: ADD R4, R4, 1 // lis_length++
    memory[64] = 16'b0000_0000_0000_0000; // 64: NOP - Placeholder (R6 = prev[R6])
    memory[65] = 16'b1011_0000_0000_0000 | 59; // 65: JMP restore_lis_loop

    // reverse_lis: (70)
    // ... (instructions for reverse_lis) ...

    // output_lis: (80)
    // ... (instructions for output_lis) ...

    memory[100] = 16'b1111_0000_0000_0000; // 100: HALT

    // Data (same as before)
    // ...

  end

  always @(posedge clk) begin
    instruction <= memory[program_counter];
  end

endmodule
```