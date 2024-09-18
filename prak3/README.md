## constrs_4 c.tcl

```tcl
# Создаем сигнал тактовой частоты с именем 'clk' с периодом 3.000 нс и скважностью 50%
create_clock -period 3.000 -waveform {0.000 1.500} [get_ports clk]

# Присваиваем сигналу 'clk' вывод E3 и устанавливаем стандарт I/O как LVCMOS33
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Начальные координаты x и y для первого pblock
set x0 19
set y0 91

# Ширина и высота каждого pblock
set pb_width 2
set pb_height 9

# Начальные координаты для первого pblock
set slice_1_x_0 $x0
set slice_1_y_0 $y0

# Инициализируем переменные для отслеживания координат второй диагональной ячейки
set slice_2_x_0 $x0
set slice_2_y_0 $y0

# Цикл для создания трех pblock-ов с названиями 'pblock_0', 'pblock_1' и 'pblock_2'
for {set i 0} {$i < 3} {incr i} {
    # Получаем ячейки, соответствующие шаблону 'stage[i]*'
    set cell_array [get_cells "stage[${i}]*"]

    # Создаем новый pblock для текущего этапа
    create_pblock "pblock_${i}"
    add_cells_to_pblock [get_pblocks "pblock_${i}"] $cell_array -clear_locs

    # Устанавливаем свойство IS_SOFT в 0 для текущего pblock
    set_property IS_SOFT 0 [get_pblocks "pblock_${i}"]

    # Определяем диагональные координаты для ограничивающего прямоугольника текущего pblock
    set slice_2_x_0 [expr $x0 + $pb_width - 1]
    set slice_2_y_0 [expr $y0 + $pb_height - 1]

    # Создаем строки с координатами ограничивающего прямоугольника для текущего pblock
    set slice_1 "SLICE_X${slice_1_x_0}Y${slice_1_y_0}"
    set slice_2 "SLICE_X${slice_2_x_0}Y${slice_2_y_0}"

    # Ресайзим текущий pblock, чтобы он покрывал заданную область
    resize_pblock [get_pblocks "pblock_${i}"] -add "$slice_1:$slice_2"

    # Обновляем координату x для следующего pblock
    set slice_1_x_0 [expr $x0 + $pb_width]
}
```

### Объяснение
- **Создание тактового сигнала (`create_clock`)**: Определяет тактовый сигнал с именем `clk` с периодом 3.000 нс и скважностью 50%.
- **Назначение вывода (`set_property PACKAGE_PIN`)**: Присваивает тактовый сигнал выводу `E3` со стандартом `LVCMOS33`.
- **Начальные координаты (`set`)**: Устанавливает начальные координаты для первого pblock.
- **Цикл создания PBlock-ов**:
  - **`get_cells`**: Извлекает ячейки, соответствующие шаблону `stage[i]*`.
  - **`create_pblock`**: Создает новый pblock с именем `pblock_i`.
  - **`add_cells_to_pblock`**: Добавляет ячейки в pblock, предварительно очистив существующие локации.
  - **`set_property IS_SOFT`**: Устанавливает свойство `IS_SOFT` в 0, чтобы pblock оставался жестким.
  - **`resize_pblock`**: Изменяет размер pblock, чтобы покрыть заданную область.

## constrs_4 scr.tcl
```tcl
# Создаем сигнал тактовой частоты с именем 'clk' с периодом 3.000 нс и скважностью 50%
create_clock -period 3.000 -waveform {0.000 1.500} [get_ports clk]

# Присваиваем сигналу 'clk' вывод E3 и устанавливаем стандарт I/O как LVCMOS33
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Ширина и высота каждого pblock
set pb_width 4
set pb_height 9

# Начальные координаты x и y для создания pblock
set x0 28
set y0 66

# Начальные координаты для первого pblock
set s_begin_x0 [expr $x0]
set s_begin_y0 [expr $y0]

# Направление движения по оси x
set dir 1

# Цикл для создания шести pblock-ов с именами 'pblock_0', 'pblock_1', ..., 'pblock_5'
for {set i 0} {$i < 6} {incr i} {
    
    # Если достигнут край (каждый пятый pblock) и это не первый блок, меняем направление
    if {([expr $i % 5 == 0]) && ($i != 0)} {
        set s_begin_y0 [expr $s_begin_y0 - $pb_height]  ;# Перемещаемся вниз
        set dir [expr $dir * -1]                        ;# Меняем направление по оси x
    } else {
        set s_begin_x0 [expr $s_begin_x0 + $dir * $pb_width]  ;# Перемещаемся по оси x
    }
    
    # Определяем конечные координаты для текущего pblock
    set s_end_x0 [expr $s_begin_x0 + $pb_width - 1]
    set s_end_y0 [expr $s_begin_y0 + $pb_height - 1]

    # Формируем строку с координатами ограничивающего прямоугольника
    set slice_block "SLICE_X${s_begin_x0}Y${s_begin_y0}:SLICE_X${s_end_x0}Y${s_end_y0}"

    # Создаем pblock с именем 'pblock_i' и задаем ему область
    create_pblock "pblock_${i}"
    resize_pblock [get_pblocks "pblock_${i}"] -add $slice_block

    # Устанавливаем свойство IS_SOFT в FALSE для текущего pblock
    set_property IS_SOFT FALSE [get_pblocks "pblock_${i}"]

    # Добавляем ячейки в текущий pblock, основываясь на имени стадии 'stage[i].*'
    add_cells_to_pblock [get_pblocks "pblock_${i}"] [get_cells "stage[${i}].*"]
}
```

### Объяснение
- **Создание тактового сигнала (`create_clock`)**: Определяет тактовый сигнал с именем `clk` с периодом 3.000 нс и скважностью 50%.
- **Назначение вывода (`set_property PACKAGE_PIN`)**: Присваивает тактовый сигнал выводу `E3` со стандартом `LVCMOS33`.
- **Начальные координаты (`set x0`, `set y0`)**: Устанавливает начальные координаты для первого pblock.
- **Ширина и высота pblock (`set pb_width`, `set pb_height`)**: Определяет размер каждого pblock.
- **Цикл создания pblock-ов**:
  - **`if`**: Проверяет, достигнут ли край (каждый пятый pblock) и меняет направление перемещения по оси x.
  - **`set slice_block`**: Определяет координаты ограничивающего прямоугольника.
  - **`create_pblock`**: Создает новый pblock с заданным именем.
  - **`resize_pblock`**: Изменяет размер pblock, чтобы охватить заданную область.
  - **`set_property IS_SOFT`**: Устанавливает свойство `IS_SOFT` в `FALSE` для жесткой фиксации pblock.
  - **`add_cells_to_pblock`**: Добавляет ячейки в pblock с соответствующим шаблоном имени `stage[i].*`.
