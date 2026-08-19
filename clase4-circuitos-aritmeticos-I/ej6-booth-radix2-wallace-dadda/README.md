# Ejercicio 6 - Booth radix-2 y reduccion Wallace/Dadda

## Enunciado

Implementar Booth radix-2 para un multiplicador signado 8x8 bits.

Para cada par (b[i], b[i-1]) generar:

- 0 si "00" o "11"
- +A si "01"
- -A si "10"

Sumar los PPs con sign-extension adecuada.

Avanzado (opcional): comparar la reduccion Wallace vs Dadda en cantidad de HAs/FAs (a nivel conceptual o RTL con CSAs explicitos).

## Datos

- Operandos 8 bits signados (C2)
- Producto 16 bits signado
- b[-1] = 0 (asumido)
- verificacion contra a*b en host

## Entregables

- Modulo booth-r2.v + tb_booth.v
- Cantidad de PPs generados
- Tabla comparativa Wallace/Dadda
- Discusion: cuando Booth no ayuda o deja de dar una ventaja?

## Tip

- El objetivo es comparar contra las arquitecturas anteriores.
- Para signados, las filas internas se extienden con el MSB: el ultimo PP usa CV.
- La implementación mínima es combinacional. Se puede hacer secuencial, aunque es un poco más complejo de desarrollar.
- Golden model embebido en testbench verilog.
