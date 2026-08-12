# Ejercicio 2 - Suma en punto fijo

## Enunciado

Dadas dos señales en formato signado:

A = S(6, 4), valor: -1.75 (bits: 100100)
B = S(8, 5), valor: +0.9375 (bits: 00011110)

- Determinar el formato S(NB_out, NBF_out) del resultado A + B.
- Calcular la suma binaria alineada y verificar el resultado decimal.

## Datos

A: S(6, 4) = "110010"
B: S(8, 5) = "00011110"
Reglas: NBF_out = max, NBI_out = max + 1

## Entregables

- Bits de A y B alineados a la coma
- Suma en complemento a 2
- Verificación del valor decimal

## Tip

Antes de sumar, extender signo y rellenar con ceros para alinear NBF.
