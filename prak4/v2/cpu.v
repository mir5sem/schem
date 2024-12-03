module core (
    input wire clk,
    input wire rst
);

    reg [7:0] pc;
    reg [15:0] ir;

    wire [2:0] op1_addr, op2_addr, res_addr;
    wire [7:0] op1_data, op2_data, literal;
    reg [7:0] alu_result;
    reg [7:0] result;
    reg alu_cond, write_enable;
    wire [15:0] instruction;
    reg [2:0] state, next_state;

    // Компоненты
    reg_file rf (
        .clk(clk),
        .read_addr1(op1_addr),
        .read_addr2(op2_addr),
        .write_addr(res_addr),
        .write_data(result),
        .write_enable(write_enable),
        .read_data1(op1_data),
        .read_data2(op2_data)
    );

    data_memory dm (
        .clk(clk),
        .addr(res_addr),
        .write_data(literal),
        .write_enable(write_enable),
        .read_data()
    );

    instruction_memory im (
        .addr(pc),
        .instruction(instruction)
    );

    // Декодирование инструкции
    assign op1_addr = instruction[10:8];
    assign op2_addr = instruction[7:5];
    assign res_addr = instruction[4:2];
    assign literal = instruction[7:0];

    // ALU (арифметико-логическое устройство)
    always @(*) begin
        case (instruction[15:14])
            2'b00: alu_result = op1_data * op2_data;
            2'b01: alu_result = ~(op1_data ^ op2_data);
            2'b10: alu_result = op2_data;
            2'b11: alu_result = 8'b0;
        endcase
        alu_cond = (alu_result > 0);
    end

    // Машина состояний
    localparam FETCH  = 3'b000,
               DECODE = 3'b001,
               EXEC   = 3'b010,
               WRITE  = 3'b011,
               BRANCH = 3'b100,
               LDI    = 3'b101;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= FETCH;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)
            FETCH: next_state = DECODE;
            DECODE: begin
                case (instruction[15:14])
                    2'b00, 2'b01, 2'b10: next_state = EXEC;
                    2'b11: next_state = BRANCH;
                    2'b100: next_state = LDI;
                endcase
            end
            EXEC: next_state = WRITE;
            WRITE: next_state = FETCH;
            BRANCH: next_state = FETCH;
            LDI: next_state = FETCH;
            default: next_state = FETCH;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 8'b0;
            ir <= 16'b0;
            result <= 8'b0;
        end else begin
            case (state)
                FETCH: begin
                    ir <= instruction;
                    pc <= pc + 1;
                end
                EXEC: begin
                    result <= alu_result;
                end
                WRITE: begin
                    write_enable <= 1;
                end
                BRANCH: begin
                    if (alu_cond)
                        pc <= literal;
                    else
                        pc <= pc + 1;
                end
                LDI: begin
                    write_enable <= 1;
                end
                default: write_enable <= 0;
            endcase
        end
    end
endmodule
