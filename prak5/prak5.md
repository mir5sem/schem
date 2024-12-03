### 11-13_cpu_my_piperline.v
```verilog
// prak 4.2

// передача команд асинхронно
module cpu();
generate
    always@*
        pr_next[0] = cmd_mem[pc];
    for(j = 0; j < 4; j = j + 1) begin
        always@*
            pr_next[j] = pr[j-1];
    end

endgenerate

generate
    for(j = 0; j < 4; j = j + 1) begin
        always@(posedge clk)
            if(reset)
                pr[j] <= 0;
            else
                pr[j] <= pr_next[j]
    end
endgenerate


// факт проверки мипса на каждой стадии (если она есть, будем решать)

    // SUP -> SUB (MIPS)
    // JMP сброс всех стадий (потом можем сделать отложенный переход)
    // LTR -> SUB
    // PTR -> SUB -> JLZ (MIPS) | 3 команды требуют чтение
    // NTR и SUB (обе команду идут) -> SUB (MIPS)
    // SWP (4 стадия) ->  -> -> INCR (1 стадия) ещё конфликт когда на 4 стадии записываем SWP (должны взять данные с алу, но алу уже изменится, мы должны взять конверизирующий результат) resl = alu2 + 1; resh = alu2 (обращайся к результату который уже будет в 64 бит, там старшие или младшие надо посмотреть)
    // mme[res1] = mem[resh]; mem[resh] = mem[res2/alu2]

    // РОН --------- (мультиплексоры 2) ------------- |  | --------- алу ---------- регистр 1 -------- регистр 2
    // фотка есть
    // (вычисление результата на 2 стадии), вычисление операндов на первом, на последней запись обычных, PTR до этого

    // SUB -> SUB
    // берем результат через алу (данные с алу) и передаем 

    // LTR -> SUB (данные с алу, данные которые есть на 1 и 2 стадии)

    // PTR -> SUB -> JLZ (PTR должен отдать значение регистра которые он поменяет на 3 либо на 4 стадии, оба результата берутся с регистра 2 (_вроде бы_))
    // PTR -> SUB: mem от алу1 = mem(alu1), можно будет записать алу1 = алу1, так как алу1 уже будет на мем(алу1), алу2 = mem(res_h)
    //  NTR -> SUB (от 4 стадии, после регистра 1, второй sub передаёт ), второй SUB данные бедутся из результата NTR и первого SUB

    // для функции команду на текущей стадии и номер стадии (или не нужна, но лучше чтобы было)
    // проблема с вытягиванием данных

    // такт 0 (не меняется)
    always@(*)
    begin
        case(cop_next[0])
            INCR, LTM, SUB, PTR:
                AdrA <= addr1_next[0];
            NTR:
                AdrA <= 0;
            default:
                AdrA <= 0;                         
        endcase
    end

    always@(*)
    begin
        case(cop_next[0])
            SUB:
                AdrB <= addr2_next[0];
            NTR:
                AdrB <= 0; 
            INCR:
                AdrB <= 1;  
            SWP:
                AdrB <= addr1_next[0];       
            default:    
                AdrB <= 0;                         
        endcase  
    end

    // такт 1 (не меняется)
    function [] check_MIPS (
        input [GPR_ADDR_WIDTH-1:0] read_addr, // адрес который мы читаем
        ); // адрес который хотим проверить (функцию сделаем так чтобы она знала что проверять)
    begin
        // чтение данных только на 1 (команда для чтения)
        case(cop[1]) // команды которые возникают на 1 стадии
        SUB, // команды которые читают (JLZ нет конфликта, так как на 3 стадии он должен знать, а флаг он знает уже на 2 стадии, так что не рассматриваем)
            // может быть конфликт если перед ней идёт SUB может быть конфликт с JLZ (но такого нет)
            case(cop[2]) // влияние 2 либо 3 стадии (тут 1 и 2) (команда для записи)
                LTR: // команды которые пишут (ВТОРОЙ SUB, NTR не на 2 стадии, а на предпоследней 3, последняя 4)
                    check_MIPS = read_addr == addr1[2]; // проверка на совпадение адресов (когда возникает проблема)
                SUB: // (другой адрес уже, вроде бы двухадресный)
                    check_MIPS = read_addr == SUB_RES; // 3 адрес (SUB_RES) = результат
                PTR:
                    check_MIPS = read_addr == addr2[2]; // 2 конфликта: требование только одного и обоих операндов (два адреса если это плохо, рассматриваем только наш конфликт и тогда нужен один адрес, два раза применить функцию и проверим выдаст ли кто-то из них конфликт, тогда мы поймём что требуется оба адреса, и данного условия будет уже достаточно чтобы работать с данным конфликтом)
                default:
                    case(cop[3])
                        NTR:
                            check_MIPS = read_addr == addr1[3]; // если единственный адрес NTR будет равен реад аддр
                        default:
                            check_MIPS = 0;
                    endcase
            endcase
        default:
            check_MIPS = 0;

    end

    endfuction

    reg [DATA_WIDTH-1:0] alu1, alu1_next,
                         alu2, alu2_next;
    always@(posedge clk)
    begin
        if (reset)  
            begin 
                alu1 <= 0;
                alu2 <= 0;
            end    
        else
            begin
                alu1 <= alu1_next;
                alu2 <= alu2_next;
            end
    end 

    // тут уже меняется где stage_counter == 1
    // 1 операнд (алу1)
    always@*
    begin
        case(cop[1])
            INCR, LTM, PTR, NTR: // меняется только SUB, INCR конфликт если не переделаем SWP, но его переделаем (изменим и при вычислении результата и при записи)
                alu1_next <= OperandA; // почему ???????????
            SUB: // совпадение адреса 1 с каким-то из адресов
                if(check_MIPS(addr1[1])) // для 1 операнда требуется брать по 2 адресу (у нас такой ситуации нет)
                    if(cop[2] == PTR) // что мы должны подать на регистр 1 (в 1 случае 1 и 2 с реза, в 3 с реза, в четвертой 1 операнд mem[alu1], 2 операнд ??? SUB -> PTR - res)
                        alu1_next <= mem[alu1]
                    else if (cop[3] == NTR)
                        alu1_next <= res2_next // если cop[3] NTR с res2 берём на алу1 (пропишем и в 1 случае и во 2)
                    else
                        alu1_next <= res_next; // конверизирующий результат res (1 конверизирующий регистр), res2 (2 регистр без названия)
                else
                    alu1_next <= alu1;
            default:
                alu1_next <= alu1;
        endcase
    end

    // 2 операнд (алу2)
    always@*
    begin
        case(cop[1])
            INCR, LTM, PTR, NTRL
                alu2_next <= OperandB;
            SUB: // совпадение адреса 1 с каким-то из адресов
                if(check_MIPS(addr2[1])) // для 1 операнда требуется брать по 2 адресу (у нас такой ситуации нет)
                    if(cop[2] == PTR) // что мы должны подать на регистр 1 (в 1 случае 1 и 2 с реза, в 3 с реза, в четвертой 1 операнд mem[alu1], 2 операнд ??? SUB -> PTR - res)
                        alu2_next <= mem[res_next[63:32]]
                    else
                        alu2_next <= res_next[31:0]; // конверизирующий результат res (1 конверизирующий регистр), res2 (2 регистр без названия)
                else
                    alu2_next <= alu1;
            PTR:
                alu2_next <= addr2[1];
            default:
                alu2_next <= alu2;
        endcase
    end
    
    // PTR -> SUB -> JLZ -> SWP (на 3 такте PTR в 3 стадии оно требует алушки для записи, пишем в регистровый файл, но SUB изменило алушки, но в SUB писали мемки, то в алушке будет то что требуется в PTR, у нас в алу1 уже есть, без mem, напрямую)
    // не изменятся ли алушки на 4 стадии? на 4 стадии нужна алу2 (можно добавить ещё регистры, но это глупо). 

    // такт 2 (меняется)
    always@*
    begin
        
    end   

    // такт 3

endmodule

```

### 11-13_cpu_my_piperline_done.v
```verilog
`timescale 1ns / 1ps

module cpu_pipeline(
    input clk, reset,
    output stage_counter
    );

integer i;

localparam SUB_RES = 4;
    
localparam NOP = 0, INCR = 1, LTR = 2, NTR= 3, LTM= 4, SUB = 5, JLZ = 6, PTR = 7, SWP = 8, JMP = 9;

localparam CMD_WIDTH = 39;
localparam CMD_ADDR_WIDTH = 6;
reg [CMD_WIDTH-1 : 0] cmd [0 : 2**CMD_ADDR_WIDTH-1];

initial
begin
    //cmd[0] <= {7'b0001_010, 32'd0}; 
    $readmemb("mem.mem", cmd);
end

localparam DATA_WIDTH = 32;
localparam MEM_ADDR_WIDTH = 6;
reg [DATA_WIDTH-1 : 0] mem [0 : 2**MEM_ADDR_WIDTH-1];

localparam GPR_FILE_SIZE = 8;
localparam GPR_ADDR_WIDTH = $clog2(GPR_FILE_SIZE);
reg [GPR_ADDR_WIDTH-1:0] AdrA, AdrB, AdrWrite;
wire [DATA_WIDTH-1:0] OperandA, OperandB;
reg wen;
reg [DATA_WIDTH-1:0] DATA;
reg_file GPR (
 .clk(clk), 
 .reset(reset), 
 .wen(wen),
 .DATA(DATA), 
 .AdrWrite(AdrWrite), 
 .AdrA(AdrA), 
 .AdrB(AdrB),
 .OperandA(OperandA), 
 .OperandB(OperandB) 
);

reg [CMD_ADDR_WIDTH-1 : 0] pc;

// Регистры команд
localparam COP_WIDTH = 4;
reg [CMD_WIDTH-1 : 0] pr [0:4];
reg [CMD_WIDTH-1 : 0] pr_next [0:4];

wire [     COP_WIDTH-1 : 0]   cop [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr1 [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr2 [0:4];
wire [CMD_ADDR_WIDTH-1 : 0]    ja [0:4];
wire [    DATA_WIDTH-1 : 0]   lit [0:4]; 

wire [COP_WIDTH-1 : 0] cop_next [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr1_next [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr2_next [0:4];

genvar j;
generate 
begin
    for (j = 0; j < 5; j = j + 1)
        begin
            assign cop[j] = pr[j][CMD_WIDTH-1 -: COP_WIDTH];
            assign addr1[j] = pr[j][CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH];
            assign addr2[j] = pr[j][CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH];
            assign ja[j] = pr[j][CMD_WIDTH-1-COP_WIDTH -: CMD_ADDR_WIDTH];
            assign lit[j] = pr[j][DATA_WIDTH-1 -: DATA_WIDTH];
            
            assign cop_next[j] = pr_next[j][CMD_WIDTH-1 -: COP_WIDTH];
            assign addr1_next[j] = pr_next[j][CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH];
            assign addr2_next[j] = pr_next[j][CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH];
        end
end
endgenerate


generate
    always@(*)
        pr_next[0] = cmd[pc]; 
    
    for (j = 1; j < 4; j = j + 1)
        begin
            always@(*)
                pr_next[j] = pr[j-1];
        end   
endgenerate


generate
    for (j = 0; j < 4; j = j + 1)
        begin
            always@(posedge clk)
                if (reset)
                    pr[j] <= 0;
                else
                    pr[j] <= pr_next[j];   
        end
endgenerate


//Такт 0
always@(*)
begin
    case(cop_next[0])
        INCR, LTM, SUB, PTR:
            AdrA <= addr1_next[0];
        NTR:
            AdrA <= 0;
        default:
            AdrA <= 0;                         
    endcase
end

always@(*)
begin
    case(cop_next[0])
        SUB:
            AdrB <= addr2_next[0];
        NTR:
            AdrB <= 0; 
        INCR:
            AdrB <= 1;  
         SWP:
            AdrB <= addr1_next[0];       
        default:    
            AdrB <= 0;                         
    endcase  
end

//Такт 1
function check_MIPS (
    input [GPR_ADDR_WIDTH-1:0] read_addr
);
begin  
    // Команда чтения данных (1-я стадия)  
    case(cop[1])
        SUB:
            // Команда записи данных (2-я стадия)
            case(cop[2])
                LTR: 
                    check_MIPS = read_addr == addr1[2];       
                SUB:
                    check_MIPS = read_addr == SUB_RES;      
                PTR:
                    check_MIPS = read_addr == addr2[2];
                default: 
                    case(cop[3])
                        NTR:
                            check_MIPS = read_addr == addr1[3]; 
                        default:
                            check_MIPS = 0;
                    endcase               
            endcase             
        default:
            check_MIPS = 0;
    endcase
end
endfunction


reg [DATA_WIDTH-1:0] alu1, alu1_next, 
                     alu2, alu2_next;
always@(posedge clk)
begin
    if (reset)  
        begin 
            alu1 <= 0;
            alu2 <= 0;
        end    
    else
        begin
            alu1 <= alu1_next;
            alu2 <= alu2_next;
        end
end 


always@(*)
begin
    case(cop[1])
        INCR, LTM, PTR, NTR:
            alu1_next <= OperandA;
        SUB:
            if (check_MIPS(addr1[1]))
                if (cop[2] == PTR)
                    alu1_next <= mem[alu1];    
                else if (cop[3] == NTR)
                    alu1_next <= res2_next;
                else    
                    alu1_next <= res_next;            
            else
                alu1_next <= alu1;    
        default: 
            alu1_next <= alu1;
    endcase                   
end


always@(*)
begin
    case(cop[1])
        INCR, SWP, NTR:
            alu2_next <= OperandB;  
        SUB:
            if (check_MIPS(addr2[1]))
                if (cop[2] == PTR)
                    alu2_next <= mem[res_next[63:32]];    
                else    
                    alu2_next <= res_next[31:0];            
            else
                alu2_next <= alu2;       
        PTR:
            alu2_next <= addr2[1];
        default:
            alu2_next <= alu2;           
    endcase
end




//Такт 2


//Такт 3


//Такт 4



endmodule

```

### 11-15_cpu_my_piperline.v
```verilog
`timescale 1ns / 1ps

module cpu_pipeline(
    input clk, reset,
    output stage_counter
    );

integer i;

localparam SUB_RES = 4;
    
localparam NOP = 0, INCR = 1, LTR = 2, NTR= 3, LTM= 4, SUB = 5, JLZ = 6, PTR = 7, SWP = 8, JMP = 9;

localparam CMD_WIDTH = 39;
localparam CMD_ADDR_WIDTH = 6;
reg [CMD_WIDTH-1 : 0] cmd [0 : 2**CMD_ADDR_WIDTH-1];

initial
begin
    //cmd[0] <= {7'b0001_010, 32'd0}; 
    $readmemb("mem.mem", cmd);
end

localparam DATA_WIDTH = 32;
localparam MEM_ADDR_WIDTH = 6;
reg [DATA_WIDTH-1 : 0] mem [0 : 2**MEM_ADDR_WIDTH-1];

localparam GPR_FILE_SIZE = 8;
localparam GPR_ADDR_WIDTH = $clog2(GPR_FILE_SIZE);
reg [GPR_ADDR_WIDTH-1:0] AdrA, AdrB, AdrWrite;
wire [DATA_WIDTH-1:0] OperandA, OperandB;
reg wen;
reg [DATA_WIDTH-1:0] DATA;
reg_file GPR (
 .clk(clk), 
 .reset(reset), 
 .wen(wen),
 .DATA(DATA), 
 .AdrWrite(AdrWrite), 
 .AdrA(AdrA), 
 .AdrB(AdrB),
 .OperandA(OperandA), 
 .OperandB(OperandB) 
);

reg [CMD_ADDR_WIDTH-1 : 0] pc;

// �������� ������
localparam COP_WIDTH = 4;
reg [CMD_WIDTH-1 : 0] pr [0:4];
reg [CMD_WIDTH-1 : 0] pr_next [0:4];

wire [     COP_WIDTH-1 : 0]   cop [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr1 [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr2 [0:4];
wire [CMD_ADDR_WIDTH-1 : 0]    ja [0:4];
wire [    DATA_WIDTH-1 : 0]   lit [0:4]; 

wire [COP_WIDTH-1 : 0] cop_next [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr1_next [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr2_next [0:4];

genvar j;
generate 
begin
    for (j = 0; j < 5; j = j + 1)
        begin
            assign cop[j] = pr[j][CMD_WIDTH-1 -: COP_WIDTH];
            assign addr1[j] = pr[j][CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH];
            assign addr2[j] = pr[j][CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH];
            assign ja[j] = pr[j][CMD_WIDTH-1-COP_WIDTH -: CMD_ADDR_WIDTH];
            assign lit[j] = pr[j][DATA_WIDTH-1 -: DATA_WIDTH];
            
            assign cop_next[j] = pr_next[j][CMD_WIDTH-1 -: COP_WIDTH];
            assign addr1_next[j] = pr_next[j][CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH];
            assign addr2_next[j] = pr_next[j][CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH];
        end
end
endgenerate


generate
    always@(*)
        pr_next[0] = cmd[pc]; 
    
    for (j = 1; j < 4; j = j + 1)
        begin
            always@(*)
                pr_next[j] = pr[j-1];
        end   
endgenerate


generate
    for (j = 0; j < 4; j = j + 1)
        begin
            always@(posedge clk)
                if (reset)
                    pr[j] <= 0;
                else
                    pr[j] <= pr_next[j];   
        end
endgenerate


//���� 0
always@(*)
begin
    case(cop_next[0])
        INCR, LTM, SUB, PTR:
            AdrA <= addr1_next[0];
        NTR:
            AdrA <= 0;
        default:
            AdrA <= 0;                         
    endcase
end

always@(*)
begin
    case(cop_next[0])
        SUB:
            AdrB <= addr2_next[0];
        NTR:
            AdrB <= 0; 
        INCR:
            AdrB <= 1;  
         SWP:
            AdrB <= addr1_next[0];       
        default:    
            AdrB <= 0;                         
    endcase  
end

// *** ���� 1 ***
function check_MIPS (
    input [GPR_ADDR_WIDTH-1:0] read_addr
);
begin  
    // ������� ������ ������ (1-� ������)  
    case(cop[1])
        SUB:
            // ������� ������ ������ (2-� ������)
            case(cop[2])
                LTR: 
                    check_MIPS = read_addr == addr1[2];       
                SUB:
                    check_MIPS = read_addr == SUB_RES;      
                PTR:
                    check_MIPS = read_addr == addr2[2];
                default: 
                    case(cop[3])
                        NTR:
                            check_MIPS = read_addr == addr1[3]; 
                        default:
                            check_MIPS = 0;
                    endcase               
            endcase             
        default:
            check_MIPS = 0;
    endcase
end
endfunction


reg [DATA_WIDTH-1:0] alu1, alu1_next, 
                     alu2, alu2_next;
always@(posedge clk)
begin
    if (reset)  
        begin 
            alu1 <= 0;
            alu2 <= 0;
        end    
    else
        begin
            alu1 <= alu1_next;
            alu2 <= alu2_next;
        end
end 


always@(*)
begin
    case(cop[1])
        INCR, LTM, PTR, NTR:
            alu1_next <= OperandA;
        SUB:
            if (check_MIPS(addr1[1]))
                if (cop[2] == PTR)
                    alu1_next <= mem[alu1];    
                else if (cop[3] == NTR)
                    alu1_next <= res2_next;
                else    
                    alu1_next <= res_next;            
            else
                alu1_next <= alu1;    
        default: 
            alu1_next <= alu1;
    endcase                   
end


always@(*)
begin
    case(cop[1])
        INCR, SWP, NTR:
            alu2_next <= OperandB;  
        SUB:
            if (check_MIPS(addr2[1]))
                if (cop[2] == PTR)
                    alu2_next <= mem[res_next[63:32]];    
                else    
                    alu2_next <= res_next[31:0];            
            else
                alu2_next <= alu2;       
        PTR:
            alu2_next <= addr2[1];
        default:
            alu2_next <= alu2;           
    endcase
end

// 1 такт почти доделали
// проблему отложенного перехода не решали

//���� 2
reg [2*DATA_WIDTH-1:0] res, res_next;  
always@(posedge clk)
    if (reset)
    begin
        res <= 0;
        res2 <= 0;
    end
    else
        res <= res_next;
        res2 <= res_next;

// res_next
always@(*)
begin
    if (stage_counter == 2)
        begin
            case(cop[2])
                INCR:
                    res_next <= alu1 + alu2; 
                NTR, LTM:
                    res_next <= alu1;
                SUB:
                    res_next <= alu1 - alu2;  
                PTR:
                    res_next <= { alu1 + 1, alu2 + 1 };
                SWP:
                    res_next <= alu2 + 1;
            default:   
                    res_next <= res;                    
            endcase
        end
    else
        res_next <= res;    
end


// lz_next    
always@(*)
begin
    if (stage_counter == 2)
        case(cop[2])
            SUB:
                lz_next <= res_next[63];
        default:   
                lz_next <= lz;
        endcase
    else               
        lz_next <= lz;                
end
// поменяли res2 на res предположили что будем брать данные из res1 (res2 мы просто убрали, записалось на вход АЛУ, В РОН не сформировался результат и в начале следующего записан на res...???? а с него можно записать результат только ещё через один такт)
// 1         2         3           4 (стадии)
// C0 C1 C2 C3
//         C0 C1 C2 C3 
// C2
// на сколько тактов откладываем результат (на 1 или на 2 такта если берем из РОН), 

always@(*)
    case(cop[2])
        // регистр результата на 2 стадии настраиваем регистр результата
        // надо брать из первого регистра результат (res1)



    endcase

//стадия 3
reg [2*DATA_WIDTH] res2, res2_next
// на res2 будет всегда подаваться ??????

always@(*)
begin
    case(stage_counter)
        3:  begin
                case(cop[3])
                    PTR: 
                        begin
                            if (check_MIPS == ) // проверка только на 3 стадии, чек мипс дал положительный результат и теперь зная что у нас там был конфликт мы можем взять оттуда данные в стадиях до 3 стадии
                            // на 3 стадии нам нужны алушки
                            // берём данные только в том случае если возникт конфликт
                            // 
                            wen <= 1;
                            AdrWrite <= addr2;
                            DATA <= mem[alu1];
                            // должны писать из мемов, а не из АЛУшек, а по адресу addr_write - addr2, res_l - alu2
                        
                        end
                default: 
                        begin
                            wen <= 0;
                            AdrWrite <= alu2;
                            DATA <= mem[alu2];
                        end   
                endcase             
            end
    default: // если не 3 стадия, то выполняем 4, тогда надо разводить логику так как нужно будет делать 2 порта на запись, но сделаем специфичное ядро 
        // NTR на 4 (cop[4] не выполнится), PTR на 3 (cop[3] выполнится) 
        case(cop[4]) begin
                case(cop[4])
                    INCR, NTR:
                        begin
                            wen <= 1; 
                            AdrWrite <= addr1[4];   
                            DATA <= res[31:0];   
                        end 
                    LTR:
                        begin
                            wen <= 1; 
                            AdrWrite <= addr1[4];   
                            DATA <= lit[4];
                        end     
                    SUB:
                        begin
                            wen <= 1; 
                            AdrWrite <= 4;   
                            DATA <= res[31:0];
                        end
                    PTR:
                    // если PTR на 4, SUB на 3 стадии, тогда проблема с резами будет на 4 стадии в PTR, резы изменятся но они здесь нужны ещё не изменённые
                    // можем назвать res от PTR
                        begin
                            wen <= 1; 
                            AdrWrite <= res2[31:0];   // ЗДЕСЬ RES2!!!!!! В ЧЕМ ПРОБЛЕМА??!!!!
                            DATA <= mem[res2[63:32]];
                        end
                 default:
                        begin
                            wen <= 0;
                            AdrWrite <= addr1[4];   
                            DATA <= lit[4];
                        end  
                endcase end endcase
        endcase                            
        end
    


always@(posedge clk)
begin
    if (stage_counter == 4)
        case(cop[4])
            SWP:
                begin
                    mem[res2[65:32]] <= mem[res2[31:0]]; // где у нас формируются резы, res_next = alu2 + 1, и тогда вмето alu2 будет res[]
                    mem[res2[31:0]] <= mem[res2[65:32]]; // обмен значениями происходит здесь видимо
                end
            LTM:
                begin
                    mem[res2] <= lit[4]; // идет не res, а res2. Везде где будет запись в регистровый файл на 4 стадии надо менять на res2
                    // но на 4 стадиии, надо протягивать всё через несколько стадий чтобы конфликтов не было

                    // меняем на 4 стадии везде на res2 (это 100%)
                end    
        endcase            
end
// остаются переходы (отложенные или нет хз), всё чистить когда заходит на 3 стадию при перезаписи, тогда для каждого регистра определить логику перехода и если будет пробелма - то сбрасываем
// меняем эту фигню (по отдельности)
always@(posedge clk)
begin
    if (reset)
        for(i = 0; i < 5; i = i + 1)
            pr[i] <= 0;   
    else
        for(i = 0; i < 5; i = i + 1)
            pr[i] <= pr_next[i]; 
end
// если cop[3] == JMP, cop[3] == JLZ, lz == 0
pr_next[0] = 0;
pr_next[0] = cmd[pc];

// в 4 jmp заходит, в 0 уже нужная команда приходит, тогда счётчик меняем (или сбрасываем) на 3
// 1 стадия
pr_next[1] = 0;
pr_next[1] = pr[0]

// 2 стадия
[2], [2]

// 3 стадии
[3] = 0, [3] = pr[2] // со 2 придет не сброшенная команда, поменяется счётчик, будем писать в 0 стадию ja и одновременно поменяем счётчик 

//4 стадия получать из 3

// дальше счётчик

reg [CMD_ADDR_WIDTH-1:0], pc, pc_next // pc меняет снихрннно, а все остальное комбинационно

case(cop[3])
JMP, JLZ.......
// добавляем if, тогда да pc_next будем писать ja[3], иначе pc_next <= pc + 1

endmodule/*  */
```

### 11-15_cpu_piperline_them_done
```verilog
`timescale 1ns / 1ps

module cpu_pipeline(
    input clk, reset,
    output pc
);

integer i;

localparam SUB_RES = 4;
    
localparam NOP = 0, INCR = 1, LTR = 2, NTR= 3, LTM= 4, SUB = 5, JLZ = 6, PTR = 7, SWP = 8, JMP = 9;

localparam CMD_WIDTH = 39;
localparam CMD_ADDR_WIDTH = 6;
reg [CMD_WIDTH-1 : 0] cmd [0 : 2**CMD_ADDR_WIDTH-1];

initial
begin
    //cmd[0] <= {7'b0001_010, 32'd0}; 
    $readmemb("mem.mem", cmd);
end

localparam DATA_WIDTH = 32;
localparam MEM_ADDR_WIDTH = 6;
reg [DATA_WIDTH-1 : 0] mem [0 : 2**MEM_ADDR_WIDTH-1];

localparam GPR_FILE_SIZE = 8;
localparam GPR_ADDR_WIDTH = $clog2(GPR_FILE_SIZE);
reg [GPR_ADDR_WIDTH-1:0] AdrA, AdrB, AdrWrite;
wire [DATA_WIDTH-1:0] OperandA, OperandB;
reg wen;
reg [DATA_WIDTH-1:0] DATA;
reg_file GPR (
 .clk(clk), 
 .reset(reset), 
 .wen(wen),
 .DATA(DATA), 
 .AdrWrite(AdrWrite), 
 .AdrA(AdrA), 
 .AdrB(AdrB),
 .OperandA(OperandA), 
 .OperandB(OperandB) 
);

reg [CMD_ADDR_WIDTH-1 : 0] pc;

// Регистры команд
localparam COP_WIDTH = 4;
reg [CMD_WIDTH-1 : 0] pr [0:4];
reg [CMD_WIDTH-1 : 0] pr_next [0:4];

wire [     COP_WIDTH-1 : 0]   cop [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr1 [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr2 [0:4];
wire [CMD_ADDR_WIDTH-1 : 0]    ja [0:4];
wire [    DATA_WIDTH-1 : 0]   lit [0:4]; 

wire [COP_WIDTH-1 : 0] cop_next [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr1_next [0:4];
wire [GPR_ADDR_WIDTH-1 : 0] addr2_next [0:4];

genvar j;
generate 
begin
    for (j = 0; j < 5; j = j + 1)
        begin
            assign cop[j] = pr[j][CMD_WIDTH-1 -: COP_WIDTH];
            assign addr1[j] = pr[j][CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH];
            assign addr2[j] = pr[j][CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH];
            assign ja[j] = pr[j][CMD_WIDTH-1-COP_WIDTH -: CMD_ADDR_WIDTH];
            assign lit[j] = pr[j][DATA_WIDTH-1 -: DATA_WIDTH];
            
            assign cop_next[j] = pr_next[j][CMD_WIDTH-1 -: COP_WIDTH];
            assign addr1_next[j] = pr_next[j][CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH];
            assign addr2_next[j] = pr_next[j][CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH];
        end
end
endgenerate


generate
    for (j = 0; j < 5; j = j + 1)
        begin
            always@(posedge clk)
                if (reset)
                    pr[j] <= 0;
                else
                    pr[j] <= pr_next[j];   
        end
endgenerate


reg lz, lz_next;
always@(posedge clk)
    if (reset)
        lz <= 0;
    else
        lz <= lz_next;




// *** Стадия 0 ***


always@(*)
    if ( cop[3] == JMP 
      || cop[3] == JLZ && lz == 0
    )  
        pr_next[0] = cmd[ja[3]];
    else     
        pr_next[0] = cmd[pc]; 
    

for (j = 1; j < 4; j = j + 1)
    begin
        always@(*)
            pr_next[j] = pr[j-1];
    end   


always@(*)
begin
    case(cop_next[0])
        INCR, LTM, SUB, PTR:
            AdrA <= addr1_next[0];
        NTR:
            AdrA <= 0;
        default:
            AdrA <= 0;                         
    endcase
end

always@(*)
begin
    case(cop_next[0])
        SUB:
            AdrB <= addr2_next[0];
        NTR:
            AdrB <= 0; 
        INCR:
            AdrB <= 1;  
         SWP:
            AdrB <= addr1_next[0];       
        default:    
            AdrB <= 0;                         
    endcase  
end



// *** Стадия 1 ***

always@(*)
    if ( cop[3] == JMP 
      || cop[3] == JLZ && lz == 0
    )  
        pr_next[1] = 0;
    else     
        pr_next[1] = pr[0]; 


function check_MIPS (
    input [GPR_ADDR_WIDTH-1:0] read_addr
);
begin  
    // Команда чтения данных (1-я стадия)  
    case(cop[1])
        SUB:
            // Команда записи данных (2-я стадия)
            case(cop[2])
                LTR: 
                    check_MIPS = read_addr == addr1[2];       
                SUB:
                    check_MIPS = read_addr == SUB_RES;      
                PTR:
                    check_MIPS = read_addr == addr2[2];
                default: 
                    case(cop[3])
                        NTR:
                            check_MIPS = read_addr == addr1[3]; 
                        default:
                            check_MIPS = 0;
                    endcase               
            endcase             
        default:
            check_MIPS = 0;
    endcase
end
endfunction


reg [DATA_WIDTH-1:0] alu1, alu1_next, 
                     alu2, alu2_next;
reg [2*DATA_WIDTH-1:0] res, res_next;
reg [DATA_WIDTH-1:0] res2, res2_next; 
always@(posedge clk)
begin
    if (reset)  
        begin 
            alu1 <= 0;
            alu2 <= 0;
        end    
    else
        begin
            alu1 <= alu1_next;
            alu2 <= alu2_next;
        end
end 


always@(*)
begin
    case(cop[1])
        INCR, LTM, PTR, NTR:
            alu1_next <= OperandA;
        SUB:
            if (check_MIPS(addr1[1]))
                if (cop[2] == PTR)
                    alu1_next <= mem[alu1];    
                else if (cop[3] == NTR)
                    alu1_next <= res;
                else    
                    alu1_next <= res_next[31:0];            
            else
                alu1_next <= alu1;    
        default: 
            alu1_next <= alu1;
    endcase                   
end


always@(*)
begin
    case(cop[1])
        INCR, SWP, NTR:
            alu2_next <= OperandB;  
        SUB:
            if (check_MIPS(addr2[1]))
                if (cop[2] == PTR)
                    alu2_next <= mem[res_next[63:32]];    
                else    
                    alu2_next <= res_next[31:0];            
            else
                alu2_next <= alu2;       
        PTR:
            alu2_next <= addr2[1];
        default:
            alu2_next <= alu2;           
    endcase
end


// *** Стадия 2 ***

always@(*)
    if ( cop[3] == JMP 
      || cop[3] == JLZ && lz == 0
    )  
        pr_next[2] = 0;
    else     
        pr_next[2] = pr[1]; 

// res
always@(posedge clk)
    if (reset)
        begin
            res  <= 0;
            res2 <= 0;
        end    
    else
        begin
            res <= res_next;
            res2 <= res2_next;
        end

// res_next
always@(*)
    case(cop[2])
        INCR:
            res_next <= alu1 + alu2; 
        NTR, LTM:
            res_next <= alu1;
        SUB:
            res_next <= alu1 - alu2;  
        PTR:
            res_next <= { alu1 + 1, alu2 + 1 };
        SWP:
            res_next <= { alu2, alu2 + 1 };
    default:   
            res_next <= res;                    
    endcase 
    
// lz          
always@(*)
    case(cop[2])
        SUB:
            lz_next <= res_next[63];
        default:   
            lz_next <= lz;
    endcase             




// *** Стадия 3 и 4 ***

always@(*)
    if ( cop[3] == JMP 
      || cop[3] == JLZ && lz == 0
    )  
        pr_next[3] = 0;
    else     
        pr_next[3] = pr[2]; 

always@(*)   
    pr_next[4] = pr[3]; 
        

reg [2*DATA_WIDTH-1:0] res2, res2_next;  
always@(posedge clk)
    if (reset)
        res2 <= 0;
    else
        res2 <= res2_next;

always@(*) res2_next <= res;


always@(*)
begin
    case(cop[3])
        PTR: 
            begin
                wen <= 1;
                AdrWrite <= addr2[3];
                DATA <= mem[alu1];
            end
        default:  
            begin          
                case(cop[4])
                    INCR, NTR:
                        begin
                            wen <= 1; 
                            AdrWrite <= addr1[4];   
                            DATA <= res2[31:0];   
                        end 
                    LTR:
                        begin
                            wen <= 1; 
                            AdrWrite <= addr1[4];   
                            DATA <= lit[4];
                        end     
                    SUB:
                        begin
                            wen <= 1; 
                            AdrWrite <= 4;   
                            DATA <= res2[31:0];
                        end
                    PTR:
                        begin
                            wen <= 1; 
                            AdrWrite <= res2[31:0];   
                            DATA <= mem[res2[63:32]];
                        end
                 default:
                        begin
                            wen <= 0;
                            AdrWrite <= addr1[4];   
                            DATA <= lit[4];
                        end  
                 endcase
            end                     
    endcase
end


always@(posedge clk)
begin
    case(cop[4])
        SWP:
            begin
                mem[res2[63:32]] <= mem[res2[31:0]];
                mem[res2[31:0]] <= mem[res2[63:32]];
            end
        LTM:
            begin
                mem[res2] <= lit[4];
            end    
    endcase            
end

reg [CMD_ADDR_WIDTH-1 : 0] pc, pc_next;

always@(posedge clk)
    if (reset)
        pc <= 0;
    else
        pc <= pc_next;


always@(*)
begin
    if ( cop[3] == JMP 
      || cop[3] == JLZ && lz == 0
    )  
        pc_next <= ja[3];
    else
        pc_next <= pc + 1;       
end



endmodule

```