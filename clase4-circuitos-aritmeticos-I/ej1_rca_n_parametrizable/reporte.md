# Informe Ejercicio 1 - RCA parametrizable

## Motivación

Sumar dos números binarios es trivial bit a bit; el problema es que el acarreo de la posición `i` depende del de la `i−1`. Esa dependencia convierte a un circuito conceptualmente combinacional en una cadena secuencial, y es el cuello de botella a considerar. El Ripple Carry Adder es la arquitectura que **no** intenta resolverlo: encadena N full adders y espera a que el acarreo recorra la cadena. El objetivo es implementarlo de forma parametrizable, verificarlo y **medir** su delay para confirmar que crece linealmente con N.

## Implementación

### Módulo

Un módulo por archivo: `full_adder.sv` es la celda y `rca.sv` la encadena.

La decisión de diseño central es describir el full adder con **compuertas primitivas con retardo explícito** (`xor #(TG)`, `and #(TG)`, `or #(TG)`) en lugar de un `assign` aritmético. El enunciado pide full adders estructurales, pero la razón de fondo es que sin retardos toda la simulación ocurre en tiempo cero y el delay no sería observable. Con `TG` = un nivel de lógica, el tiempo que tarda la salida en estabilizarse es proporcional a la profundidad lógica real.

Los caminos de propagación del FA quedan explícitos: `a,b → cout` son 3 TG (XOR, AND, OR) pero **`cin → cout` son solo 2 TG** (AND, OR), y ese es el que se repite N veces. De ahí que el delay del RCA sea ≈ 2N.

Un detalle que vale notar: la señal `p = a XOR b` se reutiliza para la suma y para el acarreo. Esa es exactamente la señal *propagate* del CLA — **el full adder ya contiene la lógica generate/propagate**, solo que la usa localmente en vez de exponerla. El ejercicio 2 se limita a sacarla afuera.

El encadenado usa `generate-for` sobre un vector interno `c[N:0]` donde `c[0] = cin` y `c[N] = cout`.

### Test Bench

Cubre lo que pide el enunciado: borde inferior (0+0), borde superior (max+max), un caso con carry-out = 1, y 500 vectores aleatorios, contra la suma nativa del simulador extendida a N+1 bits para capturar el acarreo en el mismo valor.

La medición de delay usa el estímulo de peor caso: `a = todos unos`, `b = 0`, `cin: 0 → 1`. Ese patrón hace que **todas** las posiciones propaguen (`p_i = 1` para todo `i`) sin que ninguna genere, forzando al acarreo a recorrer la cadena completa.

Como el ancho es un parámetro de elaboración y no puede barrerse desde un lazo de simulación, se instancian cinco RCA de anchos distintos en paralelo y se registra el instante en que conmuta el `cout` de cada uno.

Verifiqué que el chequeo es real desconectando la cadena de acarreo (`.cin(1'b0)` en cada FA): el testbench falla desde el primer caso de borde.

## Resultados

```
--- Casos de borde ---
  PASS borde inferior : 0 + 0 + 0 = 0  (cout=0)
  PASS borde superior : 255 + 255 + 0 = 510  (cout=1)
  PASS carry-out = 1  : 255 + 1 + 0 = 256  (cout=1)
--- 500 casos aleatorios ---
  500 casos aleatorios sin discrepancias
 RESULTADO: PASS - 505 casos sin discrepancias
```

Delay medido en función de N, con `TG` = 1 nivel de lógica:

| N | Full adders | Compuertas | Delay medido | Niveles / bit |
|---|---|---|---|---|
| 4 | 4 | 20 | 8 TG | 2 |
| 8 | 8 | 40 | 16 TG | 2 |
| 16 | 16 | 80 | 32 TG | 2 |
| 32 | 32 | 160 | 64 TG | 2 |
| 64 | 64 | 320 | 128 TG | 2 |

La relación es **exactamente `delay = 2N`**, lineal y sin término independiente en este camino: cada bit adicional agrega dos niveles de lógica (el AND y el OR del camino `cin → cout`). Graficado, es una recta de pendiente 2.

### Camino crítico observado

El camino crítico es la cadena de acarreo completa, desde `cin` hasta `cout`, atravesando el par AND-OR de cada full adder. Los XOR de suma **no** están en el camino crítico: cuelgan de él, y cada `s_i` se estabiliza un nivel después de que llega su `c_i`.

Dos consecuencias prácticas:

- **Fmax cae con N.** Con 64 bits el sumador necesita 128 niveles de lógica; a un delay típico de celda, eso limita la frecuencia a un valor inaceptable para DSP. Es la razón por la que existen el resto de las arquitecturas del módulo.
- **Glitching.** Mientras el acarreo se propaga, cada etapa conmuta con datos intermedios que después se corrigen. En una cadena larga, un mismo bit de suma puede conmutar varias veces antes de estabilizarse, y cada transición espuria consume energía. El RCA es el sumador de menor área pero **no** el de menor consumo dinámico cuando N crece.