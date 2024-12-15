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
	int R1, R2, R3, R4;

	// Initialize constants
	memory[MAX_SIZE_ADDR] = 100;
	memory[N_ADDR] = 10;

	// Initialize input
	int input_data[] = {3, 10, 2, 11, 1, 20, 15, 30, 25, 28};
	for(int i = 0; i < memory[N_ADDR]; ++i) {
		memory[input_ADDR + i] = input_data[i];
	}

	// Initialize dp and prev
	memory[R1_ADDR] = 0; // 0000 MEM_XOR R1_ADDR
	init_loop_start:
	R1 = memory[R1_ADDR]; // 0001 LOAD R1, R1_ADDR
	R2 = memory[N_ADDR]; // 0002 LOAD R2, N_ADDR
	if(R1 >= R2) // 0003 CMP R1, R2
		goto init_loop_end; // 0004 JGE to 0011
	R1 = R1 + dp_ADDR; // 0005 ADD_REG R1, dp_ADDR
	R1 = memory[R1_ADDR]; // 0006 LOAD R1, R1_ADDR
	R1 = R1 + prev_ADDR; // 0007 ADD_REG R1, prev_ADDR
	memory[R1] = memory[MAX_SIZE_ADDR]; // 0008 MEM_MEM R1, MAX_SIZE_ADDR
	memory[R1_ADDR] += 1;  // 0009 INCR_MEM R1_ADDR
	goto init_loop_start; // 0010 JMP 0001
	init_loop_end:

	// Fill dp and prev
	memory[R1_ADDR] = 1; // 0011 MEM_ONE R1_ADDR
	outer_loop_start:
	R1 = memory[R1_ADDR]; // 0012 LOAD R1, R1_ADDR
	R2 = memory[N_ADDR]; // 0013 LOAD R2, N_ADDR
	if(R1 >= R2) // 0014 CMP R1, R2
		goto outer_loop_end; // 0015 JGE to 0051
	memory[R2_ADDR] = 0; // 0016 MEM_XOR R2_ADDR
	inner_loop_start:
	R1 = memory[R2_ADDR]; // 0017 LOAD R1, R2_ADDR
	R2 = memory[R1_ADDR]; // 0018 LOAD R2, R1_ADDR
	if(R1 >= R2) // 0019 CMP R1, R2
		goto inner_loop_end; // 0020 JGE to 0049
	R1 = memory[R2_ADDR]; // 0021 LOAD R1, R2_ADDR
	R1= R1 + input_ADDR; // 0022 ADD_REG R1, input_ADDR
	R3 = memory[R1]; // 0023 REG_MEM R3, R1
	R2 = memory[R1_ADDR]; // 0024 LOAD R2, R1_ADDR
	R2 = R2 + input_ADDR; // 0025 ADD_REG R2, input_ADDR
	R4 = memory[R2]; // 0026 REG_MEM R4, R2
	if(R3 >= R4) // 0027 CMP R3, R4
		goto inner2; // 0028 JGE to 0047
	R1 = memory[R1_ADDR]; // 0029 LOAD R1, R1_ADDR
	R3 = R1 + dp_ADDR; // 0030 ADD_ANOTHER_REG R3, R1, dp_ADDR
	R3 = memory[R3]; // 0031 REG_MEM R3, R3
	R2 = memory[R2_ADDR]; // 0032 LOAD R2, R2_ADDR
	R4 = R2 + dp_ADDR; // 0033 ADD_ANOTHER_REG R4, R2, dp_ADDR
	R4 = memory[R4]; // 0034 REG_MEM R4, R4
	R4 += 1; // 0035 INCR_REG R4
	if(R3 >= R4) // 0036 CMP R3, R4
		goto inner2; // 0037 JGE to 0047
	R2 = memory[R2_ADDR]; // 0038 LOAD R2, R2_ADDR
	R3 = R2 + dp_ADDR; // 0039 ADD_ANOTHER_REG R3, R2, dp_ADDR
	R3 = memory[R3]; // 0040 REG_MEM R3, R3
	R1 = memory[R1_ADDR]; // 0041 LOAD R1, R1_ADDR
	R1 = R1 + dp_ADDR; // 0042 ADD_REG R1, dp_ADDR
	R3 += 1; // 0043 INCR_REG R3
	memory[R1] = R3; // 0044 MEM_REG R1, R3
	R1 = memory[R1_ADDR]; // 0045 LOAD R1, R1_ADDR
	R1 = R1 + prev_ADDR; // 0044 ADD_REG R1, prev_ADDR
	memory[R1] = memory[R2_ADDR]; // 0046 MEM_MEM R1, R2_ADDR
	inner2:
	memory[R2_ADDR] += 1; // 0047 INCR_MEM R2_ADDR
	goto inner_loop_start; // 0048 JMP 0017
	inner_loop_end:
	memory[R1_ADDR] += 1; // 0049 INCR_MEM R1_ADDR
	goto outer_loop_start; // 0050 JMP 0012
	outer_loop_end:

	// Find the index of the maximum element in dp
	memory[R1_ADDR] = 0; // 0051 MEM_XOR R1_ADDR
	memory[R2_ADDR] = 0; // 0052 MEM_XOR R2_ADDR
	memory[R3_ADDR] = memory[MAX_SIZE_ADDR]; // 0053 MEM_MEM R3_ADDR, MAX_SIZE_ADDR
	find_max_start:
	R1 = memory[R1_ADDR]; // 0054 REG_MEM R1, R1_ADDR
	R2 = memory[N_ADDR]; // 0055 REG_MEM R2, N_ADDR
	if(R1 >= R2) // 0056 CMP R1, R2
		goto find_max_end; // 0057 JGE to 0068
	R1 = memory[R1_ADDR]; // 0058 REG_MEM R1, R1_ADDR
	R1 = R1 + dp_ADDR; // 0059 ADD_REG R1, dp_ADDR
	R3 = memory[R1]; // 0060 REG_MEM R3, R1
	R2 = memory[R2_ADDR]; // 0061 REG_MEM R2, R2
	if(R3 <= R2) // 0062 CMP R3, R2
		goto jmp3; // 0063 JLE to 0066
	memory[R2_ADDR] = R3; // 0064 MEM_REG R2_ADDR, R3
	memory[R3_ADDR] = memory[R1_ADDR]; // 0065 MEM_MEM R3_ADDR, R1_ADDR
	jmp3:
	memory[R1_ADDR] += 1; // 0066 INCR_MEM R1_ADDR
	goto find_max_start; // 0067 JMP 0054
	find_max_end:
	restore_lis_start:
	R1 = memory[R3_ADDR]; // 0068 REG_MEM R1, R3_ADDR
	R2 = memory[MAX_SIZE_ADDR]; // 0069 REG_MEM R2, MAX_SIZE_ADDR
	if(R1 == R2) // 0070 CMP R1, R2
		goto restore_lis_end; // 0071 JEQ 0083
	R1 = memory[lis_length_ADDR];  // 0072 REG_MEM R1, lis_length_ADDR
	R2 = R1 + lis_ADDR; // 0073 ADD_ANOTHER_REG R2, R1, lis_ADDR
	R3 = memory[R3_ADDR]; // 0074 REG_MEM R3, R3
	R3 = R3 + input_ADDR; // 0075 ADD_REG R3, input_ADDR
	R3 = memory[R3]; // 0076 REG_MEM R3, R3
	memory[R2] = R3; // 0077 MEM_REG R2, R3
	memory[lis_length_ADDR] += 1; // 0078 INCR_MEM lis_length_ADDR
	R1 = memory[R3_ADDR]; // 0079 REG_MEM R1, R3_ADDR
	R1 = R1 + prev_ADDR; // 0080 ADD_REG R1, prev_ADDR
	memory[R3_ADDR] = memory[R1]; // 0081 MEM_MEM R3_ADDR, R1
	goto restore_lis_start; // 0082 JMP 0068
	restore_lis_end:

	// Reverse the lis array manually
	memory[R1_ADDR] = 0; // 0083 MEM_XOR R1_ADDR
	R1 = memory[lis_length_ADDR]; // 0084 REG_MEM R1, lis_length_ADDR
	R2 = 1; // 0085 REG_ONE, R2
	R1 = R1 - R2; // 0086 SUB R1, R2
	memory[R2_ADDR] = R1; // 0087 MEM_REG R2_ADDR, R1
	reverse_loop_start:
	R1 = memory[R1_ADDR]; // 0088 REG_MEM R1, R1_ADDR
	R2 = memory[R2_ADDR]; // 0089 REG_MEM R2, R2_ADDR
	if(R1 >= R2) // 0090 CMP R1, R2
		goto reverse_loop_end; // 0091 JGE to 0107
	R1 = memory[R1_ADDR]; // 0092 REG_MEM R1, R1_ADDR
	R1 = R1 + lis_ADDR; // 0093 ADD_REG R1, lis_ADDR
	R3 = memory[R1]; // 0094 REG_MEM R3, R1
	R2 = memory[R2_ADDR]; // 0095 REG_MEM R2, R2_ADDR
	R2 = R2 + lis_ADDR; // 0096 ADD_REG R2, lis_ADDR
	R4 = memory[R2]; // 0097 REG_MEM R4, R2
	R1 = memory[R1_ADDR]; // 0098 REG_MEM R1, R1_ADDR
	R2 = R1 + lis_ADDR; // 0099 ADD_ANOTHER_REG R2, R1, lis_ADDR
	memory[R2] = R4; // 0100 MEM_REG R2, R4
	R2 = memory[R2_ADDR]; // 0101 REG_MEM R2, R2_ADDR
	R2 = R2 + lis_ADDR; // 0102 ADD_REG R2, lis_ADDR
	memory[R2] = R3; // 0103 MEM_REG R2, R3
	memory[R1_ADDR] += 1; // 0104 INCR_MEM lis_length_ADDR 
	memory[R2_ADDR] -= 1; // 0105 DECR_MEM lis_length_ADDR 
	goto reverse_loop_start; // 0106 JMP 0088
	reverse_loop_end:
	// 0107 HALT

	// Вывод результата
	// Выход из программы
	cout << "Longest Increasing Subsequence: ";
	for(int i = 0; i < memory[lis_length_ADDR]; ++i) {
		cout << memory[lis_ADDR + i] << " ";
	}
	cout << endl;

	return 0;
}