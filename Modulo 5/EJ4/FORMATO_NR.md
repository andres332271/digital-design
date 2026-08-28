# Newton-Raphson: formatos de punto fijo

## Convencion elegida

La entrada normalizada `a` usa **U(16,16)**, mientras que la LUT, el
datapath y el resultado usan **U(16,15)**.

| Señal | Formato | Rango aproximado |
|---|---|---:|
| `a` externa | U(16,16) | 0 a 0.9999847 |
| `a_q15` interna | U(16,15) | 0 a 1.9999695 |
| `y0`, `y_reg`, `result` | U(16,15) | 0 a 1.9999695 |

La entrada requerida está en `[0.5, 1.0)`. Se convierte al formato interno
mediante `a_q15 = a >> 1`.

En U(16,15):

```text
valor real = codigo / 2^15
0.5        = 16'h4000
1.0        = 16'h8000
1.5        = 16'hC000
maximo     = 16'hFFFF = 1.9999695
```

El inverso de `a=0.5` es exactamente `2.0`, valor que no entra en U(16,15).
Para ese extremo se satura el resultado a `16'hFFFF`, con un error de un LSB.

## Aritmetica

La iteracion implementada es:

```text
p      = a * y
e      = 2 - p
y_next = y * e
```

Un producto de dos operandos U(16,15) produce 32 bits con 30 bits
fraccionarios. Para regresar a U(16,15), se desplaza 15 posiciones. La
implementacion usa truncamiento:

```text
q15 = producto >> 15
```

La constante `2.0` se representa temporalmente con 17 bits como
`17'h10000`. El resultado de la resta vuelve a entrar en 16 bits para las
entradas normalizadas y las semillas elegidas.

## LUT inicial

El intervalo `[0.5,1.0)` se divide en ocho partes iguales. El indice se toma
de `a_reg[14:12]` y cada semilla es el inverso del punto medio del intervalo.
El archivo `gen_lut.py` reproduce las constantes usadas por `nr_lut.sv`.

## Control

La FSM ejecuta la secuencia:

```text
IDLE -> INIT -> ITER (N_ITER veces) -> DONE -> IDLE
```

En `INIT`, `y_reg` carga la semilla `y0`. En cada ciclo `ITER`, registra un
nuevo valor de Newton-Raphson. `done` permanece activo durante un ciclo y
`result` conserva la ultima aproximacion calculada.

## Error observado versus iteraciones

El testbench `tb_nr.sv` prueba los limites y puntos medios de los ocho
intervalos, cuatro valores adicionales y el mayor codigo de entrada. En esa
prueba se obtuvieron los siguientes maximos:

| Iteraciones | Error absoluto maximo | Error relativo maximo |
|---:|---:|---:|
| 0 | 0.117645264 | 0.058822632 |
| 1 | 0.006896973 | 0.003448486 |
| 2 | 0.000037299 | 0.000028610 |
| 3 | 0.000041728 | 0.000029210 |
| 4 | 0.000045776 | 0.000045775 |

La convergencia ideal es cuadratica, pero deja de observarse cuando el error
alcanza unos pocos LSB. A partir de ese punto, la conversion de la entrada a
U(16,15), el truncamiento de productos y la saturacion dominan el resultado.
Por eso, en algunos casos `N=3` o `N=4` no mejora a `N=2`.

El script `run.sh` vuelve a ejecutar la prueba y genera `error_vs_n.csv` con
los resultados detallados de cada caso y `sim_nr.vcd` con las ondas.
