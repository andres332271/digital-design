# Ejercicio 5 - Array Multiplier 8x8 (combinacional)

## Enunciado

Implementar un multiplicador 8x8 unsigned combinacional basado en una matriz de full adders.

Estructura:

- Generacion de PP con AND-gates
- 7 filas de full adders para reducir
- Una fila final de RCA para el CPA

Medir el delay y comparar contra:

- El multiplicador secuencial del ej4
- Un multiplicador en RTL con "*"

## Datos

- Operandos 8 bits unsigned
- Producto 16 bits
- Matriz de 8x8 PPs
- Sin pipeline (1 ciclo combinacional)

## Entregables

- Modulo array_mul.v
- Testbench tb_array_mul.v exhaustivo (256^2)
- Tabla cantidad de FAs y delay teorico
- Comparativa con secuencial y RTL "*"

## Tip

- La ultima fila debe ser un CPA
- El resto puede ser CSA
- La idea es comparar tiempos con respecto a la estructura secuencial.
- Golden model embebido en testbench verilog.

