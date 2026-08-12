# Informe Ejercicio 3 - Truncado, redondeo y saturación

## Motivación

Recortar un número en punto fijo a menos bits implica dos decisiones independientes: qué hacer con los bits fraccionarios que sobran (truncar o redondear) y qué hacer si el valor no entra en el rango del formato destino (wrap o saturar). El ejercicio las separa en dos casos: x = 5.5625 en S(10,6) → S(7,3) sin overflow (NBI se mantiene, solo se pierde fracción) para comparar truncado vs redondeo; y = 8.75 en S(11,6) → S(5,3) con overflow real (se achica también NBI) para comparar wrap vs saturación.

## Implementación

### Módulo

`recorte_punto_fijo.sv` hace el recorte en dos pasos:

1. **Fracción** (si `ROUND_EN=0`): trunca hacia cero (se descarta la magnitud sobrante, no el piso — importante para negativos). Si `ROUND_EN=1`: redondeo half-to-even (guard/sticky/LSB), el mismo criterio que usa `numpy`/fxpmath en `rounding='around'`.
2. **Rango** (si `SAT_EN=0`): wrap, se queda con los bits bajos del resultado. Si `SAT_EN=1`: satura contra el mínimo/máximo representable en el formato de salida.

El resultado intermedio se calcula con un bit extra de margen (`W_MID = W_IN+1`) para no perder el acarreo que puede generar el redondeo antes de aplicar wrap/saturación.

Un detalle no trivial: intenté implementar el modo con parámetros `string` (`"TRUNC"`/`"ROUND"`, `"WRAP"`/`"SATURATE"`), pero Icarus Verilog crashea al comparar `parameter string` de distinta longitud dentro de un `generate if` (bug conocido de esta versión). Se resolvió usando parámetros `bit` (`ROUND_EN`, `SAT_EN`) en su lugar.

### Test Bench

`tb_recorte_punto_fijo.sv` instancia 4 variantes del DUT (x_trunc, x_round, y_wrap, y_sat) y compara cada una contra su propio archivo de referencia. `gen_vectors.py` genera los casos con fxpmath (incluyendo los valores exactos de la consigna) y escribe `x.hex`/`y.hex` más los `expected_*.hex`, que el testbench carga con `$readmemh` y contrasta contra la salida del DUT.

Antes de aceptar el resultado, verifiqué que el chequeo es real: rompiendo a propósito el redondeo en el DUT (quitando el `+round_up`), el testbench reporta 434/2000 discrepancias en vez de pasar.

## Resultados

```
x: S(4,6) -> S(4,3)  trunc vs round | 1000 vectores
y: S(5,6) -> S(2,3)  wrap  vs sat   | 1000 vectores
RESULTADO: OK - 2000 vectores sin discrepancias
```

Para los valores puntuales de la consigna: x=5.5625 trunca y redondea a 5.5 (el bit descartado cae en un empate exacto que redondea al par, coincide con el LSB ya en 0); y=8.75 con wrap da 0.75 (pierde los bits altos) y con saturación da 1.875 (el máximo de S(5,3), como anticipa el tip).
