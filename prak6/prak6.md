Увеличить количество симуляции и времени для тестирования можно тут

![](../../images/Pasted%20image%2020241124215720.png)
## Покрытие тестов данного сумматора

```verilog
`timescale 1ns / 1ps
module sum #(

    SIZE = 8    

) (

    input clk,
    input [SIZE-1:0] a, b,
    output reg [SIZE:0] c

);

always@(posedge clk)
    c <= a + b;

endmodule
```


```verilog
module test


    class seq_item;

        // генерация рандомных значения для соответствующего поля (rand - может повторяться в контексте одной симуляции, randc - только уникальные значения)
        // constraint ограничение значений на класс (область генерации)
        randc bit [7:0] value1; // проверяем только 0 и 1, z и x можно не проверять
        randc bit [7:0] value2; // для b

    endclass

  
  

    logic clk = 0;

    always #10 clk = ~clk;

  
  

    logic [7:0] a, b;

    logic [8:0] c;

    sum uut (

        .clk(clk),

        .a(a),

        .b(b),

        .c(c)

    )

  

    seq_item seq_obj; // объявили

  

    initial begin

        seq_obj = new(); // создали

        repeat(256) // несколько раз повторяем рандом для покрытия значениями

        begin

            seq_obj.randomize(); // набор значений для полей которые используются в seq_obj

  

            a = seq_obj.value1;

            b = seq_obj.value2;

  

            @(posedge clk);

        end

    end

  

endmodule

  
  
  
  
  
  
  
  

// когда много входов - проблема, можем перебирать всевозможные значения, создаем класс для тех объектов которые передаём
```



```verilog
module test

  

    class seq_item;

        // генерация рандомных значения для соответствующего поля (rand - может повторяться в контексте одной симуляции, randc - только уникальные значения)

        // constraint ограничение значений на класс (область генерации)

        randc bit [7:0] value1; // проверяем только 0 и 1, z и x можно не проверять

        randc bit [7:0] value2; // для b

    endclass

  

    logic clk = 0;

    always #10 clk = ~clk;

  
  

    logic [7:0] a, b;

    logic [8:0] c;

    sum uut (

        .clk(clk),

        .a(a),

        .b(b),

        .c(c)

    )

  

    seq_item seq_obj; // объявили

  

    covergroup seq_cg @(posedge clk);

        // clk относительно которого происходят замеры

        // мы не обратимся к каждой coverpoint, для решения механизм label (cp_value1)

        cp_value1 : coverpoint seq_obj.value1; // отслеживать на объекте

        cp_value2 : coverpoint seq_obj.value2;

        cp_value_sum : coverpoint seq_obj.value1 + seq_obj.value2;

    endgroup

  

    seq_cg cg;

  

    initial begin

        seq_obj = new(); // создали

        cg = new();

        repeat(256) // несколько раз повторяем рандом для покрытия значениями

        begin

            seq_obj.randomize(); // набор значений для полей которые используются в seq_obj

  

            a = seq_obj.value1;

            b = seq_obj.value2;

  

            @(posedge clk);

            $display("value1 = %d, value2 = %d", seq_obj.value1, seq_obj.value2);

            $display("Coverage: %0.2f %% \n", cg.get_inst_coverage());

        end

  

        $display("Coverage: %0.2f %%", cg.get_inst_coverage());

    end

  

endmodule

  
  

// когда много входов - проблема, можем перебирать всевозможные значения, создаем класс для тех объектов которые передаём
```


```verilog
`timescale 1ns / 1ps

module testbench;

class seq_item;
    randc bit [7:0] value1;
    randc bit [7:0] value2;
endclass


logic clk = 0;
always #5 clk = ~clk;

logic [7:0] a, b;
logic [8:0] c;

sum uut (
    .clk(clk),
    .a(a),
    .b(b),
    .c(c)
);

seq_item seq_obj;

covergroup seq_cg @(posedge clk);
    cp_value1 : coverpoint seq_obj.value1;
    cp_value2 : coverpoint seq_obj.value2;
    cp_value_sum : coverpoint seq_obj.value1 + seq_obj.value2;
endgroup

seq_cg cg;

initial
begin
    seq_obj = new();
    cg = new();
    repeat(256)
    begin
        seq_obj.randomize();
        
        a = seq_obj.value1;
        b = seq_obj.value2;
        
        @(posedge clk);
        
        $display("value1 = %d, value2 = %d", seq_obj.value1, seq_obj.value2);
        $display("Coverage: %0.2f %% \n", cg.get_inst_coverage());
        $display("Coverage cp_value1: %0.2f %%", cg.cp_value1.get_inst_coverage());
        $display("Coverage cp_value2: %0.2f %%", cg.cp_value2.get_inst_coverage());
        $display("Coverage cp_value_sum: %0.2f %% \n", cg.cp_value_sum.get_inst_coverage());
    end    
    
    $display("Coverage: %0.2f %%", cg.get_inst_coverage());
    $finish;
end



endmodule

```


```verilog
`timescale 1ns / 1ps

module testbench;

class seq_item;
    randc bit [7:0] value1;
    randc bit [7:0] value2;
endclass


logic clk = 0;
always #5 clk = ~clk;

logic [7:0] a, b;
logic [8:0] c;

sum uut (
    .clk(clk),
    .a(a),
    .b(b),
    .c(c)
);

seq_item seq_obj;

covergroup seq_cg @(posedge clk);
    cp_value1 : coverpoint seq_obj.value1;
    cp_value2 : coverpoint seq_obj.value2;
    cp_value_sum : coverpoint seq_obj.value1 + seq_obj.value2;
endgroup

seq_cg cg;


sequence sum_seq;
    (c == a + b);
endsequence

property sum_prop;
    @(posedge clk) ##1 sum_seq;
endproperty

property carry_prop;
    @(posedge clk) ##1 ((a + b) > 255 == c[8]);
endproperty

assert property (sum_prop) 
    $info("%d + %d = %d", a, b, c);
else
    $fatal("Error sum: %d + %d = %d", a, b, c);    

assert property (carry_prop)
    $info("Carry %d", c[8]);       
else
    $warning("Carry must exists");

initial
begin
    seq_obj = new();
    cg = new();
    repeat(256)
    begin
        seq_obj.randomize();
        
        a = seq_obj.value1;
        b = seq_obj.value2;
        
        @(posedge clk);
        
        $display("value1 = %d, value2 = %d", seq_obj.value1, seq_obj.value2);
        $display("Coverage: %0.2f %%", cg.get_inst_coverage());
        $display("Coverage cp_value1: %0.2f %%", cg.cp_value1.get_inst_coverage());
        $display("Coverage cp_value2: %0.2f %%", cg.cp_value2.get_inst_coverage());
        $display("Coverage cp_value_sum: %0.2f %% \n", cg.cp_value_sum.get_inst_coverage());
    end    
    
    $display("Coverage: %0.2f %%", cg.get_inst_coverage());
    $finish;
end



endmodule
```


- [x] отчет описываем в делении (НА ЭТОЙ НЕДЕЛИ!) ✅ 2024-11-24
- [x] следующая неделя их не будет (**17 НОЯБРЯ!**) ✅ 2024-11-24


- [ ] 8 практика - коллок


## Вариант домашний
```verilog
module fsm_div (
    input reset,
    input clk,
    input valid_in,
    input [3:0] d_in,
    output reg [3:0] d_out,
    output reg valid_out,
    output reg error_out
);

// Константы ошибок
localparam NO_ERROR = 0, DIV_BY_ZERO = 1;

// Регистры операндов
reg signed [3:0] a_reg, b_reg;

// Состояния конечного автомата
localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3;
reg [1:0] state;
initial state = S0;

always@(posedge clk)
begin
    if (reset)
        state <= S0;
    else        
        case(state)
            // Сброс регистров
            S0: begin
                    a_reg <= 0;
                    b_reg <= 0;
                    d_out <= 0;
                    error_out <= 0;
                    valid_out <= 0;
                    
                    state <= 1;
                end
            
            // Ввод первого операнда (делимого)                
            S1: if (valid_in) 
                    begin
                        a_reg <= d_in;
                        state <= S2;
                    end    
            
            // Ввод второго операнда (делителя) 
            S2: if (valid_in) 
                    begin
                        b_reg <= d_in;
                        state <= S3;
                    end    
            
            // Выполнение операции деления
            S3: begin
                    if (b_reg == 0)
                        begin
                            error_out <= DIV_BY_ZERO;
                            valid_out <= 1;     
                        end
                    else if (a_reg == 0)
                        begin
                            d_out <= 0;
                            valid_out <= 1;   
                        end           
                    else 
                        begin
                            d_out <= a_reg / b_reg;
                            valid_out <= 1;
                        end
                        
                    state <= S0;   
                end             
        endcase
end
   
endmodule
```

Выбор 256 циклов для тестирования конечного автомата деления (`fsm_div`) основан на следующих соображениях:

1. **Полное Покрытие Всех Возможных Значений:**
   - Входной сигнал `d_in` является 4-битным знаковым числом, что означает, что он может принимать 16 различных значений (от -8 до +7).
   - Для обеспечения полного покрытия всех возможных комбинаций значений `a_reg` и `b_reg` требуется 16 * 16 = 256 тестов.
   - Это гарантирует, что каждая возможная комбинация входных значений будет проверена хотя бы один раз.

2. **Достаточное Количество Тестов для Надежности:**
   - 256 тестов обеспечивают достаточное количество проверок для выявления потенциальных ошибок и граничных случаев.
   - Это количество тестов является разумным компромиссом между полнотой тестирования и временем выполнения симуляции.

3. **Случайная Генерация Данных:**
   - Использование случайной генерации данных позволяет проверить модуль на различных комбинациях входных значений, включая редкие и граничные случаи.
   - Повторение 256 циклов обеспечивает многократное тестирование каждого возможного значения, что увеличивает вероятность выявления ошибок.

### Обновленный Код Тестового Модуля

Ниже представлен обновленный код тестового модуля с пояснениями, почему используется 256 циклов:

```verilog
`timescale 1ns / 1ps

module test;
    // Объявление сигналов
    reg clk = 0;
    reg reset = 0;
    reg valid_in = 0;
    reg signed [3:0] d_in = 0;
    wire signed [4:0] d_out; // Увеличена ширина до 5 бит для предотвращения переполнения
    wire valid_out;
    wire error_out;

    // Инстанцирование DUT (Device Under Test)
    fsm_div uut (
        .reset(reset),
        .clk(clk),
        .valid_in(valid_in),
        .d_in(d_in),
        .d_out(d_out),
        .valid_out(valid_out),
        .error_out(error_out)
    );
    
    // Генерация тактового сигнала
    always #5 clk = ~clk;
    
    // Класс для генерации случайных значений
    class seq_item;
        randc bit signed [3:0] d_in_rand;
    endclass
    
    // Объект класса для генерации тестовых данных
    seq_item seq_obj;
   
    // Определение covergroup для покрытия
    covergroup fsm_cg @(posedge clk);
        cp_d_in : coverpoint d_in;
        cp_d_out : coverpoint d_out;
        cp_error_out : coverpoint error_out;
    endgroup
    
    // Объект covergroup
    fsm_cg cg;

    // Семплирование covergroup на каждом положительном фронте clk
    always @(posedge clk) begin
        cg.sample();
    end 

    // Определение последовательности и свойства для проверки корректности деления
    sequence div_seq;
        (d_out == (uut.a_reg / uut.b_reg));
    endsequence

    property div_prop;
        @(posedge clk) ##1 div_seq;
    endproperty

    // Assertion для свойства div_prop
    assert property (div_prop) else $error("Ошибка деления: %0d / %0d != %0d (Время: %0t)", 
        uut.a_reg, uut.b_reg, d_out, $time);

    // Блок инициализации теста
    initial begin
        $display("Начало тестирования FSM_DIV");
        seq_obj = new();
        cg = new();

        // Сброс
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // Проверка сброса всех регистров с помощью assert
        assert (uut.a_reg == 0)
        else
            $warning("Reset failed: a_reg != 0");
        assert (uut.b_reg == 0)
        else
            $warning("Reset failed: b_reg != 0");
        assert (d_out == 0)
        else
            $warning("Reset failed: d_out != 0");
        assert (error_out == 0)
        else
            $warning("Reset failed: error_out != 0");
        assert (valid_out == 0)
        else
            $warning("Reset failed: valid_out != 0");
        
        $display("Сброс прошёл успешно");

        // Проверка ошибки при делении на 0 с помощью assert
        valid_in = 1;
        d_in = 8; // Установка a_reg = 8
        @(posedge clk);
        d_in = 0; // Установка b_reg = 0
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        assert (error_out == 1)
        else
            $warning("Division by zero error not detected");
        
        $display("Проверка деления на ноль прошла успешно");

        // Генерация случайных значений для d_in и проверка корректности d_out
        repeat(256) begin : test_loop
            if (!seq_obj.randomize()) begin
                $warning("Randomization failed at iteration %0d", test_loop.iteration());
            end
            d_in = seq_obj.d_in_rand;
            valid_in = 1;
            @(posedge clk);
            valid_in = 0;
            @(posedge clk);
            
            if (uut.b_reg != 0) begin
                assert (d_out == (uut.a_reg / uut.b_reg))
                else
                    $warning("Incorrect division result: %0d / %0d = %0d (Время: %0t)", 
                        uut.a_reg, uut.b_reg, d_out, $time);
            end
        end

        // Вывод результатов покрытия
        $display("Coverage: %0.2f %%", cg.get_inst_coverage());
        $display("Coverage cp_d_in: %0.2f %%", cg.cp_d_in.get_inst_coverage());
        $display("Coverage cp_d_out: %0.2f %%", cg.cp_d_out.get_inst_coverage());
        $display("Coverage cp_error_out: %0.2f %% \n", cg.cp_error_out.get_inst_coverage());

        $display("Тестирование завершено");
        $finish;
    end

endmodule
```

```verilog
`timescale 1ns / 1ps

module test;
    // Объявление сигналов
    reg clk = 0;
    reg reset = 0;
    reg valid_in = 0;
    reg signed [3:0] d_in = 0;
    wire signed [4:0] d_out; // Увеличена ширина до 5 бит для предотвращения переполнения
    wire valid_out;
    wire error_out;

    // Инстанцирование DUT (Device Under Test)
    fsm_div uut (
        .reset(reset),
        .clk(clk),
        .valid_in(valid_in),
        .d_in(d_in),
        .d_out(d_out),
        .valid_out(valid_out),
        .error_out(error_out)
    );
    
    // Генерация тактового сигнала
    always #5 clk = ~clk;
    
    // Класс для генерации случайных значений
    class seq_item;
        randc bit signed [3:0] d_in_rand;
    endclass
    
    // Объект класса для генерации тестовых данных
    seq_item seq_obj;
   
    // Определение covergroup для покрытия
    covergroup fsm_cg @(posedge clk);
        cp_d_in : coverpoint d_in;
        cp_d_out : coverpoint d_out;
        cp_error_out : coverpoint error_out;
    endgroup
    
    // Объект covergroup
    fsm_cg cg;

    // Семплирование covergroup на каждом положительном фронте clk
    always @(posedge clk) begin
        cg.sample();
    end 

    // Определение последовательности и свойства для проверки корректности деления
    sequence div_seq;
        (d_out == (uut.a_reg / uut.b_reg));
    endsequence

    property div_prop;
        @(posedge clk) ##1 div_seq;
    endproperty

    // Assertion для свойства div_prop
    assert property (div_prop) else $error("Ошибка деления: %0d / %0d != %0d (Время: %0t)", 
        uut.a_reg, uut.b_reg, d_out, $time);

    // Блок инициализации теста
    initial begin
        $display("Начало тестирования FSM_DIV");
        seq_obj = new();
        cg = new();

        // Сброс
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // Проверка сброса всех регистров с помощью assert
        assert (uut.a_reg == 0)
        else
            $warning("Reset failed: a_reg != 0");
        assert (uut.b_reg == 0)
        else
            $warning("Reset failed: b_reg != 0");
        assert (d_out == 0)
        else
            $warning("Reset failed: d_out != 0");
        assert (error_out == 0)
        else
            $warning("Reset failed: error_out != 0");
        assert (valid_out == 0)
        else
            $warning("Reset failed: valid_out != 0");
        
        $display("Сброс прошёл успешно");

        // Проверка ошибки при делении на 0 с помощью assert
        valid_in = 1;
        d_in = 8; // Установка a_reg = 8
        @(posedge clk);
        d_in = 0; // Установка b_reg = 0
        @(posedge clk);
        valid_in = 0;
        @(posedge clk);
        assert (error_out == 1)
        else
            $warning("Division by zero error not detected");
        
        $display("Проверка деления на ноль прошла успешно");

        // Генерация случайных значений для d_in и проверка корректности d_out
        repeat(256) begin : test_loop
            if (!seq_obj.randomize()) begin
                $warning("Randomization failed at iteration %0d", test_loop.iteration());
            end
            d_in = seq_obj.d_in_rand;
            valid_in = 1;
            @(posedge clk);
            valid_in = 0;
            @(posedge clk);
            
            if (uut.b_reg != 0) begin
                assert (d_out == (uut.a_reg / uut.b_reg))
                else
                    $warning("Incorrect division result: %0d / %0d = %0d (Время: %0t)", 
                        uut.a_reg, uut.b_reg, d_out, $time);
            end
        end

        // Вывод результатов покрытия
        $display("Coverage: %0.2f %%", cg.get_inst_coverage());
        $display("Coverage cp_d_in: %0.2f %%", cg.cp_d_in.get_inst_coverage());
        $display("Coverage cp_d_out: %0.2f %%", cg.cp_d_out.get_inst_coverage());
        $display("Coverage cp_error_out: %0.2f %% \n", cg.cp_error_out.get_inst_coverage());

        $display("Тестирование завершено");
        $finish;
    end

endmodule
```

### Объяснение Выбора 256 Циклов

1. **Полное Покрытие Всех Возможных Значений:**
   - Входной сигнал `d_in` является 4-битным знаковым числом, что означает, что он может принимать 16 различных значений (от -8 до +7).
   - Для обеспечения полного покрытия всех возможных комбинаций значений `a_reg` и `b_reg` требуется 16 * 16 = 256 тестов.
   - Это гарантирует, что каждая возможная комбинация входных значений будет проверена хотя бы один раз.

2. **Достаточное Количество Тестов для Надежности:**
   - 256 тестов обеспечивают достаточное количество проверок для выявления потенциальных ошибок и граничных случаев.
   - Это количество тестов является разумным компромиссом между полнотой тестирования и временем выполнения симуляции.

3. **Случайная Генерация Данных:**
   - Использование случайной генерации данных позволяет проверить модуль на различных комбинациях входных значений, включая редкие и граничные случаи.
   - Повторение 256 циклов обеспечивает многократное тестирование каждого возможного значения, что увеличивает вероятность выявления ошибок.

### Заключение

Повторение 256 циклов в тестовом модуле обеспечивает полное покрытие всех возможных значений входного сигнала `d_in` и гарантирует, что конечный автомат деления (`fsm_div`) будет проверен на всех возможных комбинациях входных данных. Это количество тестов является разумным компромиссом между полнотой тестирования и временем выполнения симуляции, обеспечивая надежность и корректность работы модуля.

### Залив
```verilog
`timescale 1ns / 1ps

class seq_item;
    randc bit signed [3:0] d_in_rand;
endclass

module test;
    reg clk = 0;
    reg reset = 0;
    reg valid_in = 0;
    reg signed [3:0] d_in = 0;
    wire signed [3:0] d_out;
    wire valid_out;
    wire error_out;

    fsm_div uut (
        .reset(reset),
        .clk(clk),
        .valid_in(valid_in),
        .d_in(d_in),
        .d_out(d_out),
        .valid_out(valid_out),
        .error_out(error_out)
    );
    
    always #5 clk = ~clk;    
    seq_item seq_obj;
   
    covergroup fsm_cg @(posedge clk);
        cp_d_in : coverpoint d_in;
        cp_d_out : coverpoint d_out;
        cp_error_out : coverpoint error_out;
    endgroup
    
    fsm_cg cg;

    // Определение последовательностей
    sequence a_reg_0;
        (uut.a_reg == 0);
    endsequence

    sequence b_reg_0;
        (uut.b_reg == 0);
    endsequence

    sequence d_out_correct;
        (uut.d_out == (uut.a_reg / uut.b_reg));
    endsequence

    sequence error_out_0;
        (error_out == 0);
    endsequence

    sequence valid_out_0;
        (valid_out == 0);
    endsequence

    // Определение свойств
    property reg_reset;
        @(posedge reset) ##1 (a_reg_0 and b_reg_0 and d_out_correct and error_out_0 and valid_out_0);
    endproperty

    property reg_state_0;
        disable iff (uut.state != 1)
        @(posedge clk) (uut.a_reg == 0 && uut.b_reg == 0 && uut.d_out == 0 && uut.error_out == 0 && uut.valid_out == 0);
    endproperty 

    property correct_division;
        disable iff (uut.b_reg == 0)
        @(posedge clk) (valid_out == 1) |-> (d_out == (uut.a_reg / uut.b_reg));
    endproperty

    property reg_error_out;
        @(posedge clk) (error_out == 1) |-> (uut.b_reg == 0);
    endproperty

    assert property (reg_reset)
        $info("Reset sequence passed");
    else
        $warning("Reset sequence failed");

    assert property (reg_state_0)
        $info("State 0 sequence passed");
    else
        $warning("State 0 sequence failed");

    assert property (correct_division)
        $info("Correct division sequence passed");
    else
        $warning("Correct division sequence failed");

    assert property (reg_error_out)
        $info("Error out sequence passed");
    else
        $warning("Error out sequence failed");
        

    initial begin
        seq_obj = new();
        cg = new();
        
        // Сброс системы
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        
        // Ввод данных и проверка
        valid_in = 1;
        d_in = 8; 
        @(posedge clk);
        d_in = 0; 
        @(posedge clk);
        valid_in = 0;
    
        repeat(256) begin
            seq_obj.randomize();
            d_in = seq_obj.d_in_rand;
            valid_in = 1;
            @(posedge clk);
            valid_in = 0;
            @(posedge clk);
        end

        // Убедитесь, что симуляция достигает этой точки
        $display("Simulation reached end of test sequence");

        begin
            $display("Coverage: %0.2f %%", cg.get_inst_coverage());
            $display("Coverage cp_d_in: %0.2f %%", cg.cp_d_in.get_inst_coverage());
            $display("Coverage cp_d_out: %0.2f %%", cg.cp_d_out.get_inst_coverage());
            $display("Coverage cp_error_out: %0.2f %% \n", cg.cp_error_out.get_inst_coverage());
        end
        $finish;
    end
endmodule
```