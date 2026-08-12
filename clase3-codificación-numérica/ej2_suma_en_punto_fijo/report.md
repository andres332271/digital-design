# Informe Ejercicio 2 - Suma en punto fijo

## Motivación

Se suman dos señales signadas con distinto formato: A = S(6,4) y B = S(8,5). Al tener distinta cantidad de bits fraccionarios (NBF), no se pueden sumar directamente los bits: hay que alinear la coma. La regla usada es NBF_out = max(NBFA, NBFB) y NBI_out = max(NBIA, NBIB) + 1, dando como resultado S(9,5). El bit extra en NBI_out es el que absorbe el posible acarreo de la suma sin overflow.

## Implementación

### Módulo

`sumador_punto_fijo.sv` extiende el signo de A y B al ancho final (9 bits) y luego alinea la coma corriendo cada operando `<<< (NBF_out - NBF_operando)` (en este caso solo B se desplaza, porque NBFB=5 ya es el máximo). Con ambos operandos en el mismo formato S(9,5), la suma es una resta/suma binaria común.

### Test Bench

`tb_sumador_punto_fijo.sv` es self-checking y compara contra una referencia generada en Python, no contra valores hardcodeados. `gen_vectors.py` usa fxpmath para modelar A, B y la suma esperada en sus formatos exactos, y escribe los patrones de bits (dos complemento) en `a.hex`, `b.hex` y `expected.hex`. El testbench carga esos archivos con `$readmemh` en memorias sobredimensionadas (para no fijar la cantidad de vectores en dos lugares) y usa `$isunknown` para detectar dónde termina el archivo real (las posiciones no cargadas quedan en `X`). Por cada vector: aplica A y B, espera 1 unidad de tiempo, compara la suma del DUT contra el valor esperado y acumula errores.

Por defecto genera 1000 vectores (casos borde de A y B combinados + el ejemplo de la consigna + aleatorios); se puede ajustar con `N_VECTORS=<n> ./run.sh`.

## Resultados

```
S(6,4) + S(8,5) -> S(9,5)  |  1000 vectores
RESULTADO: OK - 1000 vectores sin discrepancias
```

Se verificó además que el testbench detecta fallas reales: reemplazando la suma por una resta en el DUT, reporta 990/1000 discrepancias en lugar de pasar silenciosamente.
