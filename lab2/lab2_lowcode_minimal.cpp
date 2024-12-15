#include <iostream>
using namespace std;

int main() {
	int MAX_SIZE = 100;
    int dp[MAX_SIZE];
    int prev[MAX_SIZE];
	int lis[MAX_SIZE];
	
    int input[] = {3, 10, 2, 11, 1, 20, 15, 30, 25, 28};
    
    int N = 10;
	int lis_length = 0;
    int R1, R2, R3, R4;

    // Initialize dp and prev
    R1 = 0; // 0000 XOR R1
    init_loop_start:
    if (R1 >= N) // 0001 CMP R1, N
        goto init_loop_end; // 0002 JGE 0007 >=
    dp[R1] = 1; // 0003 MOV dp[R1], 1
    prev[R1] = MAX_SIZE; // 0004 MOV prev[R1], MAX_SIZE
    R1 = R1 + 1; // 0005 INCR R1
    goto init_loop_start; // 0006 JMP 0001
    init_loop_end:

    // Fill dp and prev
    R1 = 1; // 0007 MOV R1, 1
    outer_loop_start:
    if (R1 >= N) // 0008 CMP R1, N
        goto outer_loop_end; // 0009 JGE 0018
    R2 = 0; // 0010 XOR R2
    inner_loop_start:
    if (R2 >= R1) // 0011 CMP R2, R1
        goto inner_loop_end; // 0012 JGE 0016
	if (input[R2] < input[R1]) { // 0013 CMP input[R2], input[R1]
	    if (dp[R1] < dp[R2] + 1) { // 0015 CMP dp[R1], dp[R2] + 1
	        dp[R1] = dp[R2] + 1; // 0017 MOV dp[R1], dp[R2] + 1
	        prev[R1] = R2; // 0018 MOV prev[R1], R2
	    }
	}
    R2 = R2 + 1; // 0019 INCR R2
    goto inner_loop_start; // 0020 JMP 0011
    inner_loop_end:
    R1 = R1 + 1; // 0021 INCR R1
    goto outer_loop_start; // 0022 JMP 0008
    outer_loop_end:

    // Find the index of the maximum element in dp
    R1 = 0; // 0023 XOR R1
    R2 = 0; // 0024 XOR R2
    R3 = MAX_SIZE; // 0025 MOV R3, MAX_SIZE
    find_max_start:
    if (R1 >= N) // 0026 CMP R1, N
        goto find_max_end; // 0027 JGE 0032
    if (dp[R1] > R2) { // 0028 CMP dp[R1], R2
        R2 = dp[R1]; // 0030 MOV R2, dp[R1]
        R3 = R1; // 0031 MOV R3, R1
    }
    R1 = R1 + 1; // 0032 INCR R1
    goto find_max_start; // 0033 JMP 0026
    find_max_end:

    // Restore LIS from dp and prev
    restore_lis_start:
    if (R3 == MAX_SIZE) // 0034 CMP R3, MAX_SIZE
        goto restore_lis_end; // 0035 JEQ 0040
    lis[lis_length] = input[R3]; // 0036 MOV lis[lis_length], input[R3]
    lis_length = lis_length + 1; // 0037 INCR lis_length
    R3 = prev[R3]; // 0038 MOV R3, prev[R3]
    goto restore_lis_start; // 0039 JMP 0034
    restore_lis_end:

    // Reverse the lis array manually
    R1 = 0; // 0040 XOR R1
    R2 = lis_length - 1; // 0041 SUB R2, lis_length - 1
    reverse_loop_start:
    if (R1 >= R2) // 0042 CMP R1, R2
        goto reverse_loop_end; // 0043 JGE 0050
    R3 = lis[R1]; // 0044 MOV R3, lis[R1]
    R4 = lis[R2]; // 0045 MOV R4, lis[R2]
    lis[R1] = R4; // 0046 MOV lis[R1], R4
    lis[R2] = R3; // 0047 MOV lis[R2], R3
    R1 = R1 + 1; // 0048 INCR R1
    R2 = R2 - 1; // 0049 DECR R2
    goto reverse_loop_start; // 0050 JMP 0042
    reverse_loop_end:
    
    output_loop_end: // 0051 HALT

	for(int i = 0; i < lis_length; i = i + 1)
		cout << result[i] << endl;
	return 0;
}