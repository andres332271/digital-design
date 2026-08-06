# Ejercicio 6 - Debugging

## Enunciado

El siguiente código tiene un BUG sutil que la síntesis convierte en latch:

```
always_comb begin
  case(op)
    2'b00: y = a + b;
    2'b01: y = a - b;
    2'b10: y = a & b;
  endcase
end
```

Tareas:

- Identificar el bug y por qué se infiere latch
- Proponer DOS fixes (default vs pre-asignación)
- Implementar ambas versiones y verificar equivalencia
- Inspeccionar con yosys que no quedan latches

## Datos

- y, a, b: signed [7:0]
- op: 2 bits - solo 3 valores definidos
- con op = 2'b11 sin asignar la herramienta infiere latch para mantener valor previo

## Entregar

- alu_bad.v, alu_fix1.v, alu_fix2.v
- tb_alu.v compara las 3 versiones con 256 vectores
- report.md con análisis del bug y comparativa
- yosys script para verificar (opcional)

## Tip

Regla de oro: en always_comb, TODA salida debe ser asignada en TODO camino. Si no, queda implícito "mantener valor previo" = latch.
