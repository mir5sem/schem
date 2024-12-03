### PWM_FSM.v
```verilog
`timescale 1ns / 1ps

module PWM_FSM #(UDW = 4) (
    input CLK,              // Тактовый сигнал
    input RST,              // Асинхронный сигнал сброса
    input RE,               // Синхронный сигнал сброса
    input CE,               // Сигнал разрешения (enable)
    input [UDW-1:0] PWM_IN, // Входное значение ширины импульса
    output reg PWM_P,       // Основной выходной сигнал ШИМ
    output wire PWM_N       // Инверсный сигнал ШИМ
);

    reg [UDW-1:0] PWM_REG, FSM_STATE; // Регистры для хранения текущего значения импульса и состояния автомата
    assign PWM_N = ~PWM_P;            // Инверсный выходной сигнал

    // Процедура для управления состоянием автомата и выходным сигналом
    always @ (posedge CLK, posedge RST) begin
        if (RST) begin
            // Действия при асинхронном сбросе
            PWM_P <= 0;               // Сброс выходного сигнала
            FSM_STATE <= 0;           // Сброс состояния автомата
            PWM_REG <= 0;             // Сброс регистра значения импульса
        end else if (RE) begin
            // Действия при синхронном сбросе
            FSM_STATE <= 0;           // Сброс состояния автомата
            PWM_P <= 0;               // Сброс выходного сигнала
        end else if (CE) begin
            // Действия при активном сигнале разрешения (enable)
            case(FSM_STATE)
                0: begin
                    // Начальное состояние
                    PWM_P <= 0;       // Установка выходного сигнала в 0
                    FSM_STATE <= {UDW{1'b1}}-1; // Переход в предпоследнее состояние
                end
                {UDW{1'b1}}-1: begin
                    // Предпоследнее состояние
                    if (PWM_REG > {UDW{1'b1}}-1) // Если значение ширины импульса больше максимального
                        PWM_P <= 1;              // Установить выходной сигнал в 1
                    else
                        PWM_P <= 0;              // Иначе установить в 0
                    FSM_STATE <= {UDW{1'b1}};    // Переход в максимальное состояние
                end
                {UDW{1'b1}}: begin
                    // Максимальное состояние
                    if (PWM_REG == 0)            // Если ширина импульса равна 0
                        PWM_P <= 0;              // Установить выходной сигнал в 0
                    else if (PWM_REG != 0)       // Если ширина импульса не равна 0
                        PWM_P <= 1;              // Установить выходной сигнал в 1
                    FSM_STATE <= 1;              // Переход в первое состояние
                end
                default: begin
                    // Все остальные состояния
                    if (PWM_REG > FSM_STATE)     // Сравнение значения ширины импульса с текущим состоянием
                        PWM_P <= 1;              // Установить выходной сигнал в 1
                    else
                        PWM_P <= 0;              // Иначе установить в 0
                    FSM_STATE <= FSM_STATE + 1;  // Переход в следующее состояние
                end
            endcase
        end
    end

    // Поведение входного регистра PWM_REG
    always @(posedge CLK, posedge RST) begin
        if (RST)
            PWM_REG <= 0; // Сброс регистра при асинхронном сбросе
        else if (FSM_STATE == {UDW{1'b1}}-1 & CE)
            PWM_REG <= PWM_IN; // Обновление регистра значением PWM_IN в конце периода
    end

endmodule
```

### top_module.v
```verilog
`timescale 1ns / 1ps

module top_module (
    input clk,
    input reset,
    input ps2_clk,
    input ps2_data,
    output pwm_out_R,
    output pwm_out_G,
    output pwm_out_B
);

// Параметры для управления цветами
reg [7:0] duty_cycle_R = 255;
reg [7:0] duty_cycle_G = 0;
reg [7:0] duty_cycle_B = 0;
reg [15:0] pwm_freq = 1000; // Частота PWM для светодиодов

// Контроллеры ШИМ для каждого цвета
dynamic_pwm_controller pwm_ctrl_R (
    .clk(clk),
    .reset(reset),
    .duty_cycle_input(duty_cycle_R),
    .frequency_input(pwm_freq),
    .pwm_out(pwm_out_R)
);

dynamic_pwm_controller pwm_ctrl_G (
    .clk(clk),
    .reset(reset),
    .duty_cycle_input(duty_cycle_G),
    .frequency_input(pwm_freq),
    .pwm_out(pwm_out_G)
);

dynamic_pwm_controller pwm_ctrl_B (
    .clk(clk),
    .reset(reset),
    .duty_cycle_input(duty_cycle_B),
    .frequency_input(pwm_freq),
    .pwm_out(pwm_out_B)
);

// Подключение модуля для чтения клавиатуры
wire [7:0] kb_data;
wire kb_ready;

ps2_keyboard kb (
    .clk(clk),
    .reset(reset),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .data(kb_data),
    .ready(kb_ready)
);

// Машина состояний и таймеры для автоматического переливания цветов
reg [23:0] color_timer = 0;
reg [3:0] state = 0;
reg [15:0] color_transition_rate = 50000; // Таймер для перехода между цветами
reg [7:0] brightness_change_rate = 5; // Скорость изменения яркости

always @(posedge clk) begin
    if (reset) begin
        duty_cycle_R <= 255;
        duty_cycle_G <= 0;
        duty_cycle_B <= 0;
        state <= 0;
        color_timer <= 0;
        color_transition_rate <= 50000;
        brightness_change_rate <= 5;
    end else begin
        // Обработка ввода с клавиатуры
        if (kb_ready) begin
            case (kb_data)
                8'h1D: begin // Клавиша 'a'
                    if (color_transition_rate < 1000000) color_transition_rate <= color_transition_rate + 10000;
                end
                8'h23: begin // Клавиша 'd'
                    if (color_transition_rate > 10000) color_transition_rate <= color_transition_rate - 10000;
                end
                8'h1A: begin // Клавиша 'w'
                    if (brightness_change_rate < 50) brightness_change_rate <= brightness_change_rate + 1;
                end
                8'h1B: begin // Клавиша 's'
                    if (brightness_change_rate > 1) brightness_change_rate <= brightness_change_rate - 1;
                end
                default: begin
                end
            endcase
        end

        // Автоматическое изменение цветов с учетом color_transition_rate
        color_timer <= color_timer + 1;
        if (color_timer >= color_transition_rate) begin
            color_timer <= 0;
            case (state)
                0: begin
                    // Красный -> Желтый
                    if (duty_cycle_G < 255) duty_cycle_G <= duty_cycle_G + brightness_change_rate;
                    else state <= 1;
                end
                1: begin
                    // Желтый -> Зеленый
                    if (duty_cycle_R > 0) duty_cycle_R <= duty_cycle_R - brightness_change_rate;
                    else state <= 2;
                end
                2: begin
                    // Зеленый -> Голубой
                    if (duty_cycle_B < 255) duty_cycle_B <= duty_cycle_B + brightness_change_rate;
                    else state <= 3;
                end
                3: begin
                    // Голубой -> Синий
                    if (duty_cycle_G > 0) duty_cycle_G <= duty_cycle_G - brightness_change_rate;
                    else state <= 4;
                end
                4: begin
                    // Синий -> Фиолетовый
                    if (duty_cycle_R < 255) duty_cycle_R <= duty_cycle_R + brightness_change_rate;
                    else state <= 5;
                end
                5: begin
                    // Фиолетовый -> Красный
                    if (duty_cycle_B > 0) duty_cycle_B <= duty_cycle_B - brightness_change_rate;
                    else state <= 0;
                end
                default: state <= 0;
            endcase
        end
    end
end

endmodule

```