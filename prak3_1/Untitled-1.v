// процессорное ядро

module cpu(
  input clk,
  output 
);


localparam INCR = 0, LTR = 1, NTR = 2, LTM = 3, SUB = 4, JLZ = 5, PTR = 6, SWP = 7, JMP = 8;

localparam CMD_WIDTH = 39;
localparam CMD_ADDR_WIDTH = 6;
reg [CMD_WIDTH-1:0] cmd [0: 2**CMD_ADDR_WIDTH] // память команд

localparam DATA_WIDTH = 32;
localparam MEM_ADDR_WIDTH = 6;
reg [DATA_WIDTH-1:0] cmd [0:2**MEM_ADDR_WIDTH-1]; // память данных 

localparam GPR_FILE_SIZE = 8;
localparam GPR_ADDR_WIDTH = $clog2(GPR_FILE_SIZE); // параметр логарифма по основанию 2 от 
reg [GPR_ADDR_WIDTH-1:0] AdrA, AdrB, AdrWrite; // для чтения
wire [DATA_WIDTH-1:0] OperandA, OperandB;
reg wen;
reg [DATA_WIDTH-1:0] DATA;

reg_file GPR(
  .clk(clk),
  .reset(reset),
  .wen(wen),
  .DATA(DATA), // запись
  .AdrWrite(AdrWrite), // запись
  .AdrA(AdrA), 
  .AdrB(AdrB),
  .OperandA(OperandA), 
  output reg [DATA_WIDTH - 1 : 0] OperandB 
);

reg [CMD_ADDR_WIDTH-1:0] pc; // регистр

reg [2:0] stage_counter;

always@(posedge clk)
begin
    if(reset || stage_counter == 4)
        stage_counter <= 0;
    else
        stage_counter <= stage_counter + 1;
end

always@(posedge clk)
begin
	if(reset)
    	pc <= 0;
	else
		if(stage_counter == 4)
			pc <= pc + 1;
end

always@(posedge clk)
begin
	if(reset)
    	pr <= 0;
	else
		if(stage_counter == 0)
			pr <= cmd[pc];
end

// алу 1 и алу 2
reg [DATA_WIDTH-1:0] alu1, alu1_next, alu2, alu2_next;
reg [2*MEM_DATA_WIDTH-1:0] res, res_next;

// алу 1
always@(posedge clk)
begin
	if(reset)
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

localparam COP_WIDTH = 4;
reg [CMD_ADDR_WIDTH-1:0] pr;
wire [COP_WIDTH-1:0] cop = pr[CMD_WIDTH-1 -:COP_WIDTH]
wire [COP_WIDTH-1:0] addr1 = pr[CMD_WIDTH-1-COP_WIDTH -: GPR_ADDR_WIDTH]
wire [COP_WIDTH-1:0] addr2 = pr[CMD_WIDTH-1-COP_WIDTH-GPR_ADDR_WIDTH -: GPR_ADDR_WIDTH]

always@(*)
begin
	if(stage_counter == 1) // команда на 1 стадия
	begin
		case(cop)
			INCR, LTM, SUB, PTR, SWP, NTR:
				begin
					alu1_next <= OperandA;
				end
			default: // защелки не будет
				alu1_next <= alu1;
		endcase
	end
	else
		alu2_next <= alu1;
end

always@(*)
begin
	if(stage_counter == 1) // команда на 1 стадия
	begin
		case(cop)
			INCR, SUB, SWP, NTR:
				begin
					alu2_next <= OperandB;
				end
			PTR:
				alu2_next <= addr2;
				// adr2 напрямую из команды
			default: // защелки не будет
				alu2_next <= alu2; // ничего не делать
		endcase
	end
	else
		alu2_next <= alu2;
end

// адреса adr1
always@(*)
begin
	if(stage_counter == 0) // для получения синхронных данных заранее готовим их на 0 стадии, чтобы записать его на 1 такте
	begin
		case(cop)
			INCR, LTM, SUB, PTR: // адрес 1
				begin
					AdrA <= addr1;
				end
			NTR:
				AdrA <= 0;
			default:
				AdrA <= 0; // без разницы
		endcase
	end
	else
		AdrA <= 0;
end

// adrb
always@(*)
begin
	if(stage_counter == 0) // для получения синхронных данных заранее готовим их на 0 стадии, чтобы записать его на 1 такте
	begin
		case(cop)
			SUB: // адрес 2
				begin
					AdrB <= addr2;
				end
			NTR:
				AdrB <= 0;
			INCR:
				AdrB <= 1;
			SWP:
				AdrB <= addr1;
			// PTR напрямую можно не делать
			default:
				AdrB <= 0; // без разницы
		endcase
	end
	else
		AdrB <= 0;
end

///////////////////// 2 стадия
// регистр результата, 
reg lz, lz_next;
always@(*)
begin
	if(stage_counter == 2)
		begin
			case(cop)
				INCR:
					res_next <= alu1 + alu2;
				NTR, LTM:
					res_next <= alu1;
				SUB:
					res_next <= alu1 - alu2;
				PTR:
					res_next <= {alu1 + 1, alu2 + 1}
				SWP:
					res_next <= alu2 + 1;
				default:
					res_next <= res;
			endcase
		end
	else
		res_next <= res;
end

always@(posedge clk)
	if (reset)
		lz <= 0;
	else
		lz <= lz_next;
end

always@(posedge clk)
	if (reset)
		res <= 0;
	else
		res <= res_next;
end

always@(*)
begin
	if(stage_counter == 2)
		begin
			case(cop)
				SUB:
					lz_next <= res_next[63]; // увеличили его в 2 раза потому что 
				default:
					lz_next <= lz;
			// определить на предыдущем такте res_next и записать его
		end
	else
		lz_next <= lz;
end

// логика adr2, wen 
wire [DATA_WIDTH-1:0] lit = pr[DATA_WIDTH-1 -: DATA_WIDTH]

always@(*)
begin
	case(stage_counter)
		3:	begin // менять на входах регистрового файла они проводы и будет мультиплексор который решает что записывать
			case(cop)
				PTR: begin
					wen <= 1;
					AdrWrite <= alu2;
					DATA <= mem[alu2];
				end
				default:
					begin
					wen <= 0; // записи не будет
					AdrWrite <= alu2; // защелку сделает
					DATA <= mem[alu2];					
				end
		4: begin // 4 стадия
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
					// любую
					AdrWrite <= addr1;
					DATA <= res[31:0];
				end
		end
		default:
			begin
				wen <= 0;
				AdrWrite <= alu2;
				DATA <= mem[alu2];	
			end
end

/// запись в MEM

always@(*)
begin
	if(stage_counter == 4) // не блочная память, перенаправление регистра
		case(cop)
		SWP:
			begin
				mem[alu2] <= mem[res];
				mem[res] <= mem[alu2];
			end
		end
		LTM:
			begin
				mem[res] <= lit;
			end
		// JLZ, JMP, программа под ядро заполнение памяти команд (readmem файл точка mem,  каждая строка команда в бинарном коде)
		// и программа
		// протестировать
		default: 
		mem[]
end

endmodule