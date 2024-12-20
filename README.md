
| №                                | Отчёт | Защита |
| -------------------------------- | ----- | ------ |
| [prak1](prak1/prak1.md)          | ✅     | ✅      |
| [prak2](prak2/prak2.md)          |       |        |
| [prak3](prak3/prak3.md)          | ✅     | ✅      |
| [prak4](prak4/prak4.md) (коллок) | ✅     | ✅      |
| [prak5](prak5/prak5.md)          |       |        |
| [prak6](prak6/prak6.md)          | ✅     | ✅      |
| [prak7](prak7/prak7.md)          | ✅     | ✅      |
| [prak8](prak8/prak8.md) (коллок) | ✅     |        |

| №                    | Отчёт | Защита |
| -------------------- | ----- | ------ |
| [lab1](lab1/lab1.md) | ✅     |        |
| [lab2](lab2/lab2.md) |       |        |



ДИСЦИЛИНА Схемотехника устройств компьютерных систем
ИНСТИТУТ ИТ
КАФЕДРА вычислительной техники
ВИД УЧЕБНОГО (^) **Материал к практическим занятиям**
МАТЕРИАЛА
ПРЕПОДАВАТЕЛЬ (^) **Тарасов И.Е.**
СЕМЕСТР 5


_Цель работы_ : проектирование различных вычислительных устройств на
уровне регистровых передач (RTL) для синтеза сигналов трансцендентных
функций.
_Постановка задачи:_ применяя методы и алгоритмы расчёта значений
трансцендентных функций, а также язык описания аппаратуры Verilog,
разработать RTL-модели вычислительных устройств для синтеза сигналов
трансцендентных функций.
_Текущий контроль в процессе практических занятий_ : проверка хода
выполнения студентами задания с целью выявления возможных ошибок при
проектировании RTL-моделей вычислительных устройств; защита работы в
формате теоретико-практического опроса.
_Результат выполнения работы:_ код модулей на Verilog HDL,
временные диаграммы, отражающие корректность работы спроектированных
модулей.

_Задание_ 1.
Разработать RTL-модель устройства на Verilog HDL для синтеза
функций sin(x) и cos(x) табличным способом, произвести верификацию
устройства.

_Задание_ 2.
Разработать RTL-модель устройства на Verilog HDL для синтеза
функций sin(x) и cos(x) с помощью рядов Тейлора, произвести верификацию
устройства.

_Задание 3._
Разработать RTL-модель устройства на Verilog HDL для синтеза
функций sin(x) и cos(x) с помощью алгоритмов CORDIC, произвести
верификацию устройства.


_Цель работы_ : оптимизация RTL-модели устройства с целью улучшения
временных показателей его работы.
_Постановка задачи:_ произвести оптимизацию RTL-модели
вычислительного устройства с целью улучшения временных показателей его
работы.
_Текущий контроль в процессе практических занятий_ : проверка хода
выполнения студентами задания с целью выявления возможных ошибок при
оптимизации RTL-модели; защита работы в формате теоретико-практического
опроса.
_Результат выполнения работы:_ описание внесённых изменений;
сгенерированные с помощью САПР отчёты о временных показателях работы
устройства до и после внесённых изменений; сравнительный анализ
полученных значений показателей.

_Задание_ 1.
Произвести оптимизацию RTL-модели устройства, производящего
умножение двух чисел в формате с плавающей точкой.


_Цель работы:_ разработка программы на языке TCL для создания
проекта в САПР Vivado.
_Постановка задачи:_ разработать программу автоматического создания
проекта в САПР Vivado в соответствии с заданным набором свойств на
скриптовом языке высокого уровня TCL.
_Текущий контроль в процессе практических занятий_ : проверка хода
выполнения студентами задания с целью выявления возможных ошибок на
этапе разработки программы на языке TCL; защита работы в формате
теоретико-практического опроса.
_Результат выполнения работы:_ программа на языке TCL, результат
выполнения программы.

_Задание_ 1.
Разработать программу автоматического создания проекта в САПР
Vivado на языке TCL. Для проекта необходимо задать следующий набор
свойств:

- Модель ПЛИС: xc7a100tcsg324- 1 ;
- Язык проектирования: Verilog HDL.
В проекте должно быть создано два модуля для описания дизайна
устройства (Design Sources): “mux.v” и “main.v”, а также один модуль для
описания тестового окружения (Simulation Sources): “test.v”.

![[Практические занятия.pdf]]