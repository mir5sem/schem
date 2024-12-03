module reg_file (
    input wire clk,
    input wire [2:0] read_addr1,
    input wire [2:0] read_addr2,
    input wire [2:0] write_addr,
    input wire [7:0] write_data,
    input wire write_enable,
    output reg [7:0] read_data1,
    output reg [7:0] read_data2
);

    reg [7:0] registers [7:0];
    initial begin
        registers[0] = 8'b0;
        registers[1] = 8'b0;
        registers[2] = 8'b0;
        registers[3] = 8'b0;
        registers[4] = 8'b0;
        registers[5] = 8'b0;
        registers[6] = 8'b0;
        registers[7] = 8'b0;
        registers[8] = 8'b0;
    end
    
    always @(posedge clk) begin
        if (write_enable)
            registers[write_addr] <= write_data;
    end

    always @(*) begin
        read_data1 = registers[read_addr1];
        read_data2 = registers[read_addr2];
    end
endmodule
