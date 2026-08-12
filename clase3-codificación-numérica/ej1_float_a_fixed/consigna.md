# Ejercicio 1 - Conversión Float - Fixed

## Enunciado

Dado el número x = +9.625 en decimal:

- Representar x en IEEE 754 simple precisión (32 bits) con signo mantisa y exponente.
- Representar x en punto fijo S(8, 3) (unsigned: U(8, 3) si conviene).
- Calcular el error de cuantización al pasar de float a fixed.

## Datos

- x = 9.625
- Formato float: IEEE 754 (S=1, E=8, M=23)
- Formato fixed S(8, 3)

## Entregables

- Pasos de cada conversión
- Bits explícitos en ambos formatos
- Cálculo del error de cuantización en LSB y en su valor absoluto

## Tip

Normalizar primero el binario; recordar el sesgo 127 del exponente.
