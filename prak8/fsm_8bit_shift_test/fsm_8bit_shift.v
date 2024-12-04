module fsm_8bit_shift (
    input clk,
    input reset,
    input data_in1_valid,
    input data_in2_valid,
    input [7:0] data_in1,
    input [7:0] data_in2,
    output reg [15:0] data_out,
    output reg output_valid
);

    reg [1:0] state, next_state;

    localparam IDLE = 2'b00, SHIFT = 2'b01, COMBINE = 2'b10;

    reg [7:0] data_buffer1, data_buffer2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            data_out <= 16'b0;
            output_valid <= 0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    output_valid <= 0;
                    if (data_in1_valid && data_in2_valid) begin
                        data_buffer1 <= data_in1;
                        data_buffer2 <= data_in2;
                    end
                end
                SHIFT: begin
                    data_out <= data_buffer1 << 2;
                end
                COMBINE: begin
                    data_out <= {data_buffer1, data_buffer2};
                    output_valid <= 1;
                end
            endcase
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (data_in1_valid && data_in2_valid)
                    next_state = SHIFT;
                else
                    next_state = IDLE;
            end
            SHIFT: next_state = COMBINE;
            COMBINE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

endmodule