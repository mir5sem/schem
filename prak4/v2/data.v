module data_memory (
    input wire clk,
    input wire [7:0] addr,
    input wire [7:0] write_data,
    input wire write_enable,
    output reg [7:0] read_data
);

    reg [7:0] memory [255:0];

    always @(posedge clk) begin
        if (write_enable)
            memory[addr] <= write_data;
    end

    always @(*) begin
        read_data = memory[addr];
    end
endmodule
