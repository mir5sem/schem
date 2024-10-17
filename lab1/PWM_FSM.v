`timescale 1ns / 1ps
module PWM_FSM #(UDW = 4) (
    input CLK,
    input RST,
    input RE,
    input CE,
    input [UDW-1:0] PWM_IN,
    output reg PWM_P,
    output wire PWM_N
);
    
reg [UDW-1:0] PWM_REG, FSM_STATE;
assign PWM_N = ~PWM_P;
always @ (posedge CLK, posedge RST)
    if (RST)
        //«действия по асинхронному сбросу»
        begin
            PWM_P <= 0;
            FSM_STATE <= 0;
            PWM_REG <= 0;
        end
    else if (RE)
        //«действия по синхронному сбросу»
        begin
            FSM_STATE <= 0;
            PWM_P <= 0;
        end
    else if (CE)
        case(FSM_STATE)
            0:
                begin
                    PWM_P <= 0;
                    FSM_STATE <= {UDW{1'b1}}-1;
                end
                {UDW{1'b1}}-1:
                begin
                    if (PWM_REG > {UDW{1'b1}}-1)
                        PWM_P <= 1;
                    else
                        PWM_P <= 0;
                    FSM_STATE <= {UDW{1'b1}};
                end
                {UDW{1'b1}}:
                begin
                    if (PWM_REG == 0)
                        PWM_P <= 0;
                    else if (PWM_REG != 0)
                        PWM_P <= 1;
                    FSM_STATE <= 1;
                end
                default:
                begin
                    if (PWM_REG > FSM_STATE)
                        PWM_P <= 1;
                    else
                        PWM_P <= 0;
                        FSM_STATE <= FSM_STATE + 1;
                end
        endcase

// Поведение входного регистра PWM_REG
always @(posedge CLK, posedge RST)
    if (RST)
        PWM_REG <= 0;
    else
        if (FSM_STATE == {UDW{1'b1}}-1 & CE)
            PWM_REG <= PWM_IN;
endmodule
