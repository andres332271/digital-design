# Ejercicio 4 - Multiplicador Shift-and-Add (secuencial)

## Enunciado

Implementar un multiplicador unsigned de 8x8 bits que produzca el resultado completo en 8 ciclos de reloj.

Componentes:

- Adder de 8 bits,
- Registro acumulador de 16 bits,
- Shifter (a la izquierda) en cada ciclo,
- FSM de control con estados, 
- IDLE -> COMPUTE -> DONE

Validar con un testbench que compare contra a*b en el host.

## Datos

- Operandos a, b de 8 bits unsigned
- Producto de 16 bits
- Latencia: 8 ciclos
- FSM con start/done

## Entregables

- Modulo mul_seq.v + control_fsm.v
- Testbench tb_mul_seq.v con 200 vectores
- Conteo de ciclos por operacion
- Analisis area vs throughput

## Tip

- Usar un unico adder de 8 bits
- El shifter desplaza solo el acumulador
- Golden model embebido en testbench verilog.
