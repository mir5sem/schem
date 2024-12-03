## Описание модулей 
В лабе 5 описывается двухступенчатый конвейер, содержащий набор команд для решения задачи: «Даны два числа m и n. Необходимо найти все числа, меньшие n, квадрат суммы цифр которого равен m». Чтобы упростить себе задачу, будем думать, что необходимо посчитать квадрат суммы цифр числа в ШЕСТНАДЦАТЕРИЧНОМ формате. 

### 1. Модуль конвейера (CPU) 
Двухступенчатый конвейер со следующим набором команд: 

![image](https://github.com/user-attachments/assets/e0afefc7-8cf2-4cce-b18f-0984d222f9d6)

Первая ступень конвейера: выборка операндов; вторая ступень:  выполнение операции и запись результата. 

Процессор построен по гарвардской архитектуре, то есть имеет раздельную память команд и данных. 

### 2. Память программы (Program) 
Файл, содержащий последовательный набор инструкций для решения задачи. Подробнее программа описана в Excel-файле.