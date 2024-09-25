`timescale 1ns / 1ps
// древовидный сумматор
module adder_tree 
#(
    SIZE = 32
)
(
    input clk,
    input [SIZE-1:0] a,
    input [SIZE-1:0] b,
    output [SIZE:0] q 
);

genvar i, j;
generate
begin
    for (i = 0; i < SIZE; i = i + 1)
        begin: add
            reg [SIZE-1-i:0] s;
            reg [SIZE-1-i:0] c;
        end
    
    reg [SIZE-1-2:0] c_grand;
    
    // Итерация по стадиям
    for (i = 0; i < SIZE; i = i + 1)
    begin
        // Итерация по разрядам
        for (j = 0; j < SIZE-i; j = j + 1)
        begin
            if (i == 0)
                always@(posedge clk)
                    { add[i].c[j], add[i].s[j] } <= a[j] + b[j];
            else 
                always@(posedge clk)   
                                                    // перенос от нулевого разряда и сумму от первого
                    { add[i].c[j], add[i].s[j] } <= add[i-1].c[j] + add[i-1].s[j+1];
        end
     end
  
    // Выходная шина
    for (i = 0; i < SIZE; i = i + 1)
    begin
      assign q[i] = add[i].s[0]; // i номер стадии
    end 
    assign q[SIZE] = c_grand[SIZE-2-1];


    // Сумма переносов 
    for (i = 0; i < SIZE-2; i = i + 1)
    begin
        if (i == 0)
            always@(posedge clk)
                c_grand[0] <= add[0].c[SIZE-1] + add[1].c[SIZE-2];
        else         
            always@(posedge clk)
                c_grand[i] <= c_grand[i-1] + add[i+1].c[SIZE-i-1];        
    end
end
endgenerate
  // перевод в доп код создаст восемь carrychain которые будут переносить эту единицу (путь для доп кода)
// 
endmodule
