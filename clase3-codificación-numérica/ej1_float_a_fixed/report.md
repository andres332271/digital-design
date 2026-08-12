# Ejercicio 1 - Conversión Float - Fixed

Contamos un número (x = 9.625) y exploramos dos formas distintas de representarlo en binario.

## Representación IEEE 754 simple precisión

Esta representación es del tipo punto flotante y tiene 3 partes: signo, mantisa y exponente. El formato de simple precisión consiste de 32 bits donde:

- `b[0]` (el MSB) es el signo, siendo 0 positivo.
- `b[1:9]` es el exponente.
- `b[10:31]` es la mantisa.

### Paso 1: Determinar el signo

x es positivo, por lo que `b[0]` es '0'.

### Paso 2: Convertir a binario

Se trabaja la parte entera y fraccionaria por separado

- `int` = 9 = '1001'
- `frac` = 0.625 = '0.101'

Luego, combinando las dos partes tenemos:

```
9.625 = '1001.101'
```

### Paso 3: Normalizar

Se debe separar mantisa de exponente y esto se hace corriendo la coma hasta que el MSB sea '1'.

```
9.625 =
        '1.001101' x 2^3
```

Luego, completamos con ceros (padding) a la derecha para obtener la mantisa.

```
mantisa_sin_pad = '001101' (el MSB siempre es 1 por lo que está implícito).

mantisa = '00110100000000000000000'

```

### Paso 4: Calcular el exponente con bias

Dado que el exponente puede ser positivo o negativo el estandar IEEE 754 utiliza un bias para dividir exponentes negativos y positivos. Para simple precisión el bias es 127 (2^7-1). Para calcular el exponente sumamos el bias al exponente en representación decimal.

```
exponente = 127 + 3
            130
            '10000010'
```

### Paso final: Combinar los resultados

Habiendo calculado signo, mantisa y exponente, tenemos la representación completa:

```
x = 9.625
    '0 10000010 00110100000000000000000'
```

## Representación en punto fijo S(NB, NBF).

La representación en punto fijo puede utilizar un número variable de bits para representar la parte entera y la decimal.

- NB es la cantidad total de bits
- NBF es la cantidad de bits de la parte decimal

### Paso 1: Elegir signado o no signado

El número a representar (9.625) entra dentro del rango de S(8, 3) (que es `[-16, 15.875]`) por lo que no es necesario usar la representación no signada.

### Paso 2: Dividir x entre los pesos de la representación

Dado el vector de pesos de nuestra representación:

```
w = 2 ^ [4, 3, 2, 1, 0, -1, -2, -3]
  = [16, 8, 4, 2, 1, 0.5, 0.25, 0.125]
```

Armamos un vector dividiendo x (9.625) entre cada valor del vector de pesos, redondeando al entero menor (función floor, o `//` en python).

```
q = x // w
  = [0, 1, 2, 4, 9, 19, 38, 77]
```

### Paso 3: Tomar el resto de la división por 2

Para obtener la representación en binario tomamos el resto de la división por 2 del vector de cocientes del paso 2.

```
b = q % 2
  = [0, 1, 0, 0, 1, 1, 0, 1]
```

### Consideraciones adicionales

El mismo algoritmo sirve para obtener la representación signada (complemento a 2) como la no signada. La diferencia está solamente a la interpretación que se hace de los valores cuyo MSB es 1. En el caso de la no signada siguen siendo valores positivos mientras que en el caso de la signada representan valores negativos.

## Error de cuantización

En punto fijo el error de cuantización es a lo sumo 1 LSB. Esto es $2^{-3}=0.125$ para S(8, 3). Esto es un error absoluto, pero el error relativo es variable y depende del valor representado. En punto flotante en cambio, el error de cuantización es siempre relativo (es un error de a lo sumo 1 LSB de la mantisa). Dado que la mantisa ocupa 23 bits en simple precisión, el error relativo es $2^{-23}=1.19 10^{-7}$.

## Script de python

El script ej1.py contiene funciones que automatizan tanto la obtención de la representación en punto fijo como la de punto flotante. Es más, la función que obtiene punto flotante hace uso de la de punto fijo para obtener mantisa y exponente.

Las funciones no implementan verificación de rango, por lo que depende del usuario elegir valores dentro del rango para que la representación obtenida sea válida.

