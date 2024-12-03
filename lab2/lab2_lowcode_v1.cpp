#include <iostream>
using namespace std;

const int MEMORY_SIZE = 1000;
int memory[MEMORY_SIZE];

// Memory addresses
const int MAX_SIZE_ADDR   = 0;
const int dp_ADDR         = 1;   // dp starts at 1
const int prev_ADDR       = 101; // prev starts at 101
const int lis_ADDR        = 201; // lis starts at 201
const int input_ADDR      = 301; // input starts at 301
const int N_ADDR          = 401;
const int lis_length_ADDR = 402;
const int R1_ADDR         = 403;
const int R2_ADDR         = 404;
const int R3_ADDR         = 405;
const int R4_ADDR         = 406;
const int result_ADDR     = 407;

int main() {
    // Initialize constants
    memory[MAX_SIZE_ADDR] = 100;
    memory[N_ADDR] = 10;
    
    // Initialize input
    int input_data[] = {3, 10, 2, 11, 1, 20, 15, 30, 25, 28};
    for(int i = 0; i < memory[N_ADDR]; ++i) {
        memory[input_ADDR + i] = input_data[i];
    }
    
    // Initialize dp and prev
    // 0000 XOR R1
    memory[R1_ADDR] = 0;
    
    // 0001 CMP_REG R1, [N]
    // 0002 JGE 0007
    init_loop_start:
    if(memory[R1_ADDR] >= memory[N_ADDR])
        goto init_loop_end;
    
    // 0003 MOV_MEM [dp + R1], 1
    memory[dp_ADDR + memory[R1_ADDR]] = 1;
    
    // 0004 MOV_MEM [prev + R1], MAX_SIZE
    memory[prev_ADDR + memory[R1_ADDR]] = memory[MAX_SIZE_ADDR];
    
    // 0005 INCR R1
    memory[R1_ADDR] += 1;
    
    // 0006 JMP 0001
    goto init_loop_start;
    
    init_loop_end:
    
    // Fill dp and prev
    // 0007 MOV_REG R1, 1
    memory[R1_ADDR] = 1;
    
    outer_loop_start:
    // 0008 CMP_REG R1, [N]
    // 0009 JGE 0018
    if(memory[R1_ADDR] >= memory[N_ADDR]) goto outer_loop_end;
    
    // 0010 XOR R2
    memory[R2_ADDR] = 0;
    
    inner_loop_start:
    // 0011 CMP_REG R2, R1
    // 0012 JGE 0016
    if(memory[R2_ADDR] >= memory[R1_ADDR]) goto inner_loop_end;
    
    // 0013 CMP_MEM [input + R2], [input + R1]
    if(memory[input_ADDR + memory[R2_ADDR]] < memory[input_ADDR + memory[R1_ADDR]]) {
        // 0015 CMP_MEM [dp + R1], [dp + R2] + 1
        if(memory[dp_ADDR + memory[R1_ADDR]] < memory[dp_ADDR + memory[R2_ADDR]] + 1) {
            // 0017 MOV_MEM [dp + R1], [dp + R2] + 1
            memory[dp_ADDR + memory[R1_ADDR]] = memory[dp_ADDR + memory[R2_ADDR]] + 1;
            // 0018 MOV_MEM [prev + R1], R2
            memory[prev_ADDR + memory[R1_ADDR]] = memory[R2_ADDR];
        }
    }
    
    // 0019 INCR R2
    memory[R2_ADDR] += 1;
    
    // 0020 JMP 0011
    goto inner_loop_start;
    
    inner_loop_end:
    
    // 0021 INCR R1
    memory[R1_ADDR] += 1;
    
    // 0022 JMP 0008
    goto outer_loop_start;
    
    outer_loop_end:
    
    // Find the index of the maximum element in dp
    // 0023 XOR R1
    memory[R1_ADDR] = 0;
    
    // 0024 XOR R2
    memory[R2_ADDR] = 0;
    
    // 0025 MOV_REG R3, MAX_SIZE
    memory[R3_ADDR] = memory[MAX_SIZE_ADDR];
    
    find_max_start:
    // 0026 CMP_REG R1, [N]
    // 0027 JGE 0032
    if(memory[R1_ADDR] >= memory[N_ADDR]) goto find_max_end;
    
    // 0028 CMP_MEM [dp + R1], R2
    if(memory[dp_ADDR + memory[R1_ADDR]] > memory[R2_ADDR]) {
        // 0030 MOV_MEM [R2], [dp + R1]
        memory[R2_ADDR] = memory[dp_ADDR + memory[R1_ADDR]];
        // 0031 MOV_MEM [R3], R1
        memory[R3_ADDR] = memory[R1_ADDR];
    }
    
    // 0032 INCR R1
    memory[R1_ADDR] += 1;
    
    // 0033 JMP 0026
    goto find_max_start;
    
    find_max_end:
    
    // Restore LIS from dp and prev
    restore_lis_start:
    // 0034 CMP_REG R3, [MAX_SIZE]
    // 0035 JEQ 0040
    if(memory[R3_ADDR] == memory[MAX_SIZE_ADDR]) goto restore_lis_end;
    
    // 0036 MOV_MEM [lis + lis_length], [input + R3]
    memory[lis_ADDR + memory[lis_length_ADDR]] = memory[input_ADDR + memory[R3_ADDR]];
    
    // 0037 INCR lis_length
    memory[lis_length_ADDR] += 1;
    
    // 0038 MOV_REG R3, [prev + R3]
    memory[R3_ADDR] = memory[prev_ADDR + memory[R3_ADDR]];
    
    // 0039 JMP 0034
    goto restore_lis_start;
    
    restore_lis_end:
    
    // Reverse the lis array manually
    // 0040 XOR R1
    memory[R1_ADDR] = 0;
    
    // 0041 SUB R2, lis_length - 1
    memory[R2_ADDR] = memory[lis_length_ADDR] - 1;
    
    reverse_loop_start:
    // 0042 CMP_REG R1, R2
    // 0043 JGE 0050
    if(memory[R1_ADDR] >= memory[R2_ADDR]) goto reverse_loop_end;
    
    // 0044 MOV_REG R3, [lis + R1]
    memory[R3_ADDR] = memory[lis_ADDR + memory[R1_ADDR]];
    
    // 0045 MOV_REG R4, [lis + R2]
    memory[R4_ADDR] = memory[lis_ADDR + memory[R2_ADDR]];
    
    // 0046 MOV_MEM [lis + R1], R4
    memory[lis_ADDR + memory[R1_ADDR]] = memory[R4_ADDR];
    
    // 0047 MOV_MEM [lis + R2], R3
    memory[lis_ADDR + memory[R2_ADDR]] = memory[R3_ADDR];
    
    // 0048 INCR R1
    memory[R1_ADDR] += 1;
    
    // 0049 DECR R2
    memory[R2_ADDR] -= 1;
    
    // 0050 JMP 0042
    goto reverse_loop_start;
    
    reverse_loop_end:
    
    // HALT
    // 0051 HALT
    // Вывод результата
    // Выход из программы
    cout << "Longest Increasing Subsequence: ";
    for(int i = 0; i < memory[lis_length_ADDR]; ++i) {
        cout << memory[lis_ADDR + i] << " ";
    }
    cout << endl;
    
    return 0;
}