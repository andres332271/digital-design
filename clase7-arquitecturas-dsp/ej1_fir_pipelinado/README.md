# Ejercicio: Diseñar un FIR Pipelinado

Fuente: `ref/Modulo_7.pptx`, slide 52 ("Ejercicio Práctico: Diseñar un FIR Pipelinado").

## Enunciado

Diseñar un FIR de 4 taps con coeficientes simétricos {1, 3, 3, 1} pipelinado para f_clk = 200 MHz.

**A. Dibuja el SFG directa.**
Identifica el camino crítico y calcula T_cp en términos de t_mul y t_add.

**B. Aplica retiming.**
Redistribuye los registros para minimizar T_cp. ¿Cuántos registros adicionales se necesitan?

**C. Escribe el Verilog.**
Implementa el FIR pipelinado de 2 etapas. Incluye rst síncrono.

**D. Verifica con iverilog.**
Escribe un testbench de impulso. Corre con iverilog + vvp. Muestra resultados PASS/FAIL.

**E. Sintetiza con Yosys.**
Usa sky130hd.lib. Reporta área (µm²) y número de celdas. ¿Cuántos FFs infirió?

**F. Análisis de trade-offs.**
Completa la tabla: Directa / Pipelinada / Folded L=2 — T_cp, Área, Throughput.
