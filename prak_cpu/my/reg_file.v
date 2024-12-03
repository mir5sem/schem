`timescale 1ns / 1ps

module reg_file#(
    DATA_WIDTH = 32,
    REG_FILE_SIZE = 8,
    ADDR_WIDTH = $clog2(REG_FILE_SIZE)
)(
    input  clk, reset, wen,
    input  [DATA_WIDTH - 1 : 0] DATA, 
    input  [ADDR_WIDTH - 1 : 0] AdrWrite, 
    input  [ADDR_WIDTH - 1 : 0] AdrA, 
    input  [ADDR_WIDTH - 1 : 0] AdrB,
    output reg [DATA_WIDTH - 1 : 0] OperandA, 
    output reg [DATA_WIDTH - 1 : 0] OperandB 
    );
    
    reg [DATA_WIDTH - 1 : 0] GPR [0 : REG_FILE_SIZE - 1];
    
    integer i;
    initial
    begin
        for(i = 0; i < REG_FILE_SIZE; i = i + 1)
            GPR[i] = {DATA_WIDTH{1'b0}};        
        OperandA = {DATA_WIDTH{1'b0}};        
        OperandB = {DATA_WIDTH{1'b0}};        
        GPR[1] = {{(DATA_WIDTH-1){1'b0}},1'b1};               
    end
    
    always@(posedge clk)
    begin
        if (reset)
            for(i = 2; i < REG_FILE_SIZE; i = i + 1)
                GPR[i] <= {DATA_WIDTH{1'b0}};
        else
        if(wen && AdrWrite != {ADDR_WIDTH{1'b0}} && AdrWrite != {{(ADDR_WIDTH-1){1'b0}},1'b1})
            GPR[AdrWrite] <=  DATA;
    end
    
    always@(posedge clk)
    begin
        if(reset)
        begin
            OperandA <= {DATA_WIDTH{1'b0}};        
            OperandB <= {DATA_WIDTH{1'b0}};
        end
        else
        begin
            OperandA <= GPR[AdrA];
            OperandB <= GPR[AdrB];
        end
    end
    
    
endmodule
