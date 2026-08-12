# Ejercicio 3 - Truncado, Redondeo y Saturación

## Enunciado

Se tiene x = 5.5625 en formato S(10, 6).

- Recortar x a S(7, 3) por truncado y por redondeo. ¿Cuál es el error en cada caso?

- Se tiene y = 8.75 en S(11, 6). Recortarlo a S(5, 3) usando wrap-around y saturación. ¿Cuál es el resultado en cada caso?

## Datos

- x = 5.5625 en S(10, 6).
- y = 8.75 en S(10, 6).

- Destino x: S(7, 3).
- Destino y: S(5, 3).

## Entregables

- Bits y valores recortados.
- Errores: trunc vs recortados.
- Resultado: wrap vs saturación.

## Tip

Rango de S(5, 3): [-2, 1.875]. Si y > 1.875 hay overflow.
