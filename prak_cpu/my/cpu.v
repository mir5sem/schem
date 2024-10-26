`timescale 1ns / 1ps

module cpu(
    input clk, reset,
    output stage_counter
    );
    
localparam NOP = 0, INCR = 1, LTR = 2, NTR= 3, LTM= 4, SUB = 5, JLZ = 6, PTR = 7, SWP = 8, JMP = 9;

localparam CMD_WIDTH = 39;
localparam CMD_ADDR_WIDTH = 6;
reg [CMD_WIDTH-1 : 0] cmd [0 : 2**CMD_ADDR_WIDTH-1];

initial
begin
    //cmd[0] <= {7'b0001_010, 32'd0}; 
    stage_counter = 0;
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

localparam COP_WIDTH = 4;
reg [CMD_WIDTH-1 : 0] pr, pr_next;

reg [2:0] stage_counter;

always@(posedge clk)
begin
    if (reset || stage_counter == 4)
        stage_counter <= 0;
    else
        stage_counter <= stage_counter + 1;        
end


always@(posedge clk)
begin
    if (reset)
        pc <= 0;
    else
        if (stage_counter == 4)
            case(cop)
                JMP: pc <= ja;
                JLZ: if (~lz)
                        pc <= ja;
                     else
                        pc <= pc + 1;   
                default: pc <= pc + 1;                
            endcase        
end


always@(posedge clk)
begin
    if (reset)
        pr <= 0;
    else
        pr <= pr_next; 
end

always@*
begin
    if (stage_counter == 0)
        pr_next <= cmd[pc];
    else 
        pr_next <= pr;    
end

reg [DATA_WIDTH-1:0] alu1, alu1_next, alu2, alu2_next;
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

wire [COP_WIDTH-1 : 0] cop = pr[CMD_WIDTH-1 -: COP_WIDTH];
wire [GPR_ADDR_WIDTH-1 : 0] addr1 = pr[CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH];
wire [GPR_ADDR_WIDTH-1 : 0] addr2 = pr[CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH];
wire [CMD_ADDR_WIDTH-1 : 0]    ja = pr[CMD_WIDTH-1-COP_WIDTH -: CMD_ADDR_WIDTH];
wire [COP_WIDTH-1 : 0] cop_next = pr_next[CMD_WIDTH-1 -: COP_WIDTH];
wire [GPR_ADDR_WIDTH-1 : 0] addr1_next = pr_next[CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH];
wire [GPR_ADDR_WIDTH-1 : 0] addr2_next = pr_next[CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH];
always@(*)
begin
    if (stage_counter == 1)
        begin
            case(cop)   
                INCR, LTM, SUB, PTR, NTR:
                    begin
                        alu1_next <= OperandA;     
                    end
                default:
                    alu1_next <= alu1;        
            endcase 
        end
    else
        alu1_next <= alu1;        
end             


always@(*)
begin
    if (stage_counter == 1)
        begin
            case(cop)   
                INCR, SUB, SWP, NTR:
                    alu2_next <= OperandB;     
                PTR:
                    alu2_next <= addr2;
                default:
                    alu2_next <= alu2;        
            endcase 
        end
    else
        alu2_next <= alu2;        
end 


always@(*)
begin
    if (stage_counter == 0)
        begin
            case(cop_next)
                INCR, LTM, SUB, PTR:
                    AdrA <= addr1_next;
                NTR:
                    AdrA <= 0;  
            default:    
                    AdrA <= 0;                         
            endcase
        end
    else
        AdrA <= 0;    
end

always@(*)
begin
    if (stage_counter == 0)
        begin
            case(cop_next)
                SUB:
                    AdrB <= addr2_next;
                NTR:
                    AdrB <= 0; 
                INCR:
                    AdrB <= 1;  
                 SWP:
                    AdrB <= addr1_next;       
            default:    
                    AdrB <= 0;                         
            endcase
        end
    else
        AdrB <= 0;    
end  

reg [2*DATA_WIDTH-1:0] res, res_next;  
always@(posedge clk)
    if (reset)
        res <= 0;
    else
        res <= res_next;

always@(*)
begin
    if (stage_counter == 2)
        begin
            case(cop)
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


reg lz, lz_next;
always@(posedge clk)
    if (reset)
        lz <= 0;
    else
        lz <= lz_next;
                   
always@(*)
begin
    if (stage_counter == 2)
        case(cop)
            SUB:
                lz_next <= res_next[63];
        default:   
                lz_next <= lz;
        endcase
    else               
        lz_next <= lz;                
end

wire [DATA_WIDTH-1 : 0] lit = pr[DATA_WIDTH-1 -: DATA_WIDTH];
always@(*)
begin
    case(stage_counter)
        3:  begin
                case(cop)
                    PTR: 
                        begin
                            wen <= 1;
                            AdrWrite <= alu2;
                            DATA <= mem[alu1];
                        end
                default: 
                        begin
                            wen <= 0;
                            AdrWrite <= alu2;
                            DATA <= mem[alu2];
                        end   
                endcase             
            end
        4:  begin
                case(cop)
                    INCR, NTR:
                        begin
                            wen <= 1; 
                            AdrWrite <= addr1;   
                            DATA <= res[31:0];   
                        end 
                    LTR:
                        begin
                            wen <= 1; 
                            AdrWrite <= addr1;   
                            DATA <= lit;
                        end     
                    SUB:
                        begin
                            wen <= 1; 
                            AdrWrite <= 4;   
                            DATA <= res[31:0];
                        end
                    PTR:
                        begin
                            wen <= 1; 
                            AdrWrite <= res[31:0];   
                            DATA <= mem[res[63:32]];
                        end
                 default:
                        begin
                            wen <= 0;
                            AdrWrite <= addr1;   
                            DATA <= lit;
                        end  
                 endcase                            
            end
        default:
            begin
                wen <= 0;
                AdrWrite <= addr1;   
                DATA <= lit;
            end 
        endcase      
end

       
always@(posedge clk)
begin
    if (stage_counter == 4)
        case(cop)
            SWP:
                begin
                    mem[alu2] <= mem[res];
                    mem[res] <= mem[alu2];
                end
            LTM:
                begin
                    mem[res] <= lit;
                end    
        endcase            
end
                    

    
endmodule
