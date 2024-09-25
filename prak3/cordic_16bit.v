module CORDIC 
(
    input clk,
    input [31:0] angle,
    input [15:0] Xin, Yin,
    output [16:0] COS_OUT, SIN_OUT
);

wire [31:0] atan_table [0:30];
`include "atan_table.vh" 

reg signed [31:0] X [0:31];
reg signed [31:0] Y [0:31];
reg signed [31:0] RES_ACC [0:31];
reg signed [16:0] RES_ACC_add [0:31];

wire [1:0] quadrant = angle[31:30];


genvar i;
generate
    for(i = 0; i < 31; i = i + 1)
    begin: stage
        
        if (i == 0)
            always@(posedge clk)
            begin
                case(quadrant)
                    2'b00, 2'b11:
                    begin
                        RES_ACC[0] <= angle;
                        X[0] <= Xin;
                        Y[0] <= Yin;
                    end
                    2'b01:
                    begin
                        X[0] <= -Yin;
                        Y[0] <= Xin;
                        RES_ACC[0] <= {2'b00, angle[29:0]};
                    end
                    2'b10:
                    begin
                        X[0] <= Yin;
                        Y[0] <= -Xin;
                        RES_ACC[0] <= {2'b11, angle[29:0]};
                    end
                endcase
            end
        
        wire rotation_sign = RES_ACC[i][31];
        wire signed [16:0] X_shift = X[i] >>> i;
        wire signed [16:0] Y_shift = Y[i] >>> i;
        
        wire [31:0] atan = rotation_sign ? atan_table[i] : -atan_table[i]; // перевод в доп. код при дроблении на нескольких частей теряем знак
        /*
        always@(posedge clk)
        begin
            X[i+1] <= rotation_sign ? X[i] + Y_shift: X[i] - Y_shift;
            Y[i+1] <= rotation_sign ? Y[i] - X_shift: Y[i] + X_shift;
            
            //RES_ACC[i+1] <= rotation_sign ? RES_ACC[i] + atan_table[i] : RES_ACC[i] - atan_table[i]; 
            // младшие регистры суммирование разрядов между carrychain
            RES_ACC_add[i] <= RES_ACC[i][15:0] + atan[15:0];           
            
            // сложение старших разрядов (последовательный перенос - сложил младшие - отправил в старшие - сложил старшие)
            // разбили 32 бита на 2 пары по 16 разрядов (2 части числа)
            RES_ACC[i+1] <= {RES_ACC[i][31:16] + atan[31:16] + RES_ACC_add[i][16], RES_ACC_add[i][15:0]};      
        end
        */
        
        wire [31:0] RES_ACC_result;
        wire [31:0] atan = rotation_sign ? atan_table[i] : -atan_table[i];
        adder_tree RES_ACC_add ( // добавление сумматора
            .clk(clk),
            .a(RES_ACC[i]),
            .b(atan[i]),
            .q(RES_ACC_result)
        );
        always@(posedge clk) RES_ACC[i+1] <= RES_ACC_result;
        wire [16:0] X_result;   
        wire [16:0] X_shift_ = rotation_sign ? -X_shift :  X_shift;
        wire [16:0] Y_result;  
        wire [16:0] Y_shift_ = rotation_sign ?  Y_shift : -Y_shift;  
        
        adder_tree #(16) X_add (.clk(clk), .a(X[i]), .b(X_shift_), .q(X_result));                                 
        always@(posedge clk) X[i+1] <= X_result;
        
    
        adder_tree #(16) Y_add (.clk(clk), .a(Y[i]), .b(Y_shift_), .q(Y_result));                                 
        always@(posedge clk) Y[i+1] <= Y_result;
    end

endgenerate

assign SIN_OUT = Y[31];
assign COS_OUT = X[31];

endmodule
 
