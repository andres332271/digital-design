# Informe Ejercicio 2 - ASAP y ALAP sobre el DFG del FIR

## Motivación

Con el DFG de ej1 fijado, el objetivo acá es asignar cada nodo a un ciclo de clock bajo
recursos ilimitados y ver dónde hay margen (movilidad) para, más adelante, compartir hardware
sin penalizar la latencia. Este resultado es justamente el que va a explicar por qué el ej3
(1 mult + 1 add compartidos) no puede lograr los mismos 3 ciclos que acá.

**Modelo de ciclos usado:** cada operación (`×` o `+`) ocupa exactamente 1 ciclo de clock —
es el modelo estándar de scheduling HLS (grano unitario por operador), distinto de las
latencias en `tu` de ej1/ej4, que miden retardo de compuertas *dentro* de un ciclo cuando varias
operaciones comparten etapa sin registro intermedio. Acá cada arista entre nodos de distinto
ciclo implica un registro.

## ASAP (recursos ilimitados)

Cada nodo se agenda en el primer ciclo en que **todas** sus entradas están listas:

| Nodo | Depende de | Ciclo ASAP |
|---|---|---|
| `m0` | `h0`, `x[n]` (entradas primarias) | 1 |
| `m1` | `h1`, `x[n-1]` (entradas primarias) | 1 |
| `m2` | `h2`, `x[n-2]` (entradas primarias) | 1 |
| `m3` | `h3`, `x[n-3]` (entradas primarias) | 1 |
| `a1` | `m0`, `m1` | 2 |
| `a2` | `m2`, `m3` | 2 |
| `a3` | `a1`, `a2` | 3 |

**Latencia ASAP = 3 ciclos.** Requiere 4 multiplicadores en el ciclo 1 y 2 sumadores en el
ciclo 2 simultáneamente (recursos ilimitados, por definición de ASAP).

## ALAP (misma latencia total, 3 ciclos)

Se recorre desde la salida hacia atrás: `a3` queda fija en el último ciclo (3), y cada
predecesor se agenda lo más tarde posible sin retrasar a su sucesor.

| Nodo | Sucesor que lo restringe | Ciclo ALAP |
|---|---|---|
| `a3` | — (salida) | 3 |
| `a1` | `a3` | 2 |
| `a2` | `a3` | 2 |
| `m0` | `a1` | 1 |
| `m1` | `a1` | 1 |
| `m2` | `a2` | 1 |
| `m3` | `a2` | 1 |

## Movilidad

| Nodo | ASAP | ALAP | Movilidad |
|---|---|---|---|
| `m0` | 1 | 1 | 0 |
| `m1` | 1 | 1 | 0 |
| `m2` | 1 | 1 | 0 |
| `m3` | 1 | 1 | 0 |
| `a1` | 2 | 2 | 0 |
| `a2` | 2 | 2 | 0 |
| `a3` | 3 | 3 | 0 |

## Discusión

**Movilidad = 0 en los 7 nodos.** No es un error de cálculo: es consecuencia directa de haber
elegido en ej1 un árbol de sumas *balanceado*. En un árbol balanceado, todo camino desde una
entrada primaria hasta la salida tiene exactamente la misma longitud (2 saltos: un `×` y dos
`+`), así que **todo nodo está en algún camino de longitud máxima** — la definición misma de
pertenecer al camino crítico. No hay ninguna rama "más corta" que otra de la cual robar slack.

Esto tiene una consecuencia directa para ej3: como no hay movilidad, no hay ciclos ociosos que
aprovechar para multiplexar 4 multiplicaciones y 3 sumas sobre 1 multiplicador y 1 sumador
compartidos sin agregar ciclos. La versión iterativa **va a necesitar más de 3 ciclos** —
la movilidad 0 aquí es la prueba, no una suposición, de que compartir hardware en este DFG tiene
un costo de latencia insalvable con esta topología.

Si el DFG hubiese sido la cadena de sumas descartada en ej1 (`a1=m0+m1`, `a2=a1+m2`,
`a3=a2+m3`), sí aparecería movilidad (`m2` tendría movilidad 1, `m3` movilidad 2) a costa de un
camino crítico más largo (4 ciclos en vez de 3) — el trade-off clásico: menos camino crítico
(árbol) implica menos flexibilidad para compartir recursos más adelante.

## Verificación

Las tres tablas de arriba se armaron a mano recorriendo el DFG — fácil de calcular mal en un
nodo y no darse cuenta, sobre todo en ALAP (recorrer hacia atrás es más propenso a error que
hacia adelante). `ej2_asap_alap/verify_asap_alap.py` recomputa lo mismo con un scheduler
genérico en Python: recibe el DFG como un dict `nodo -> [predecesores]` (sin hardcodear los
ciclos de ningún nodo) y calcula ASAP con recursión simple (`ciclo(n) = 1 + max(ciclo(p))` sobre
los predecesores) y ALAP recorriendo el grafo invertido desde la salida (`ciclo(n) = min(ciclo(s))
- 1` sobre los sucesores, con los sumideros fijados en la latencia total). No asume de antemano
que la movilidad va a dar 0 en ningún lado — ese resultado sale solo de correr el algoritmo sobre
la topología en árbol.

```
nodo ASAP ALAP  mov
m0      1    1    0
...
a3      3    3    0
Latencia ASAP (script) = 3 ciclos (report dice 3)
RESULTADO: OK - coincide exactamente con la tabla de docs/ej2_asap_alap.md
```

Corre con `cd ej2_asap_alap && python3 verify_asap_alap.py` — coincide nodo por nodo con las
tablas de arriba.

## Contraste con fuentes externas

Fuente primaria leída completa: *"Scheduling Algorithms For High-Level Synthesis"* (TU Delft
OCW, §2.2, §4.1, §4.2, §5.1) — `WebFetch` bajó el PDF y se leyó directo con `Read`, no un
*snippet*.

1. **ASAP** (p.6): *"starts with the highest nodes (that have no parents) […] assigns time
   steps in increasing order […] a successor node can execute only after its parent has
   executed […] it schedules in least number of control steps"*. Coincide con la tabla ASAP de
   arriba (cada nodo en el primer ciclo en que sus entradas están listas, latencia 3).
2. **ALAP** (p.6): *"works exactly in the same way as the ASAP algorithm except that it starts
   at the bottom of the DFG and proceeds upwards […] gives the slowest possible schedule"*.
   Coincide con el recorrido hacia atrás desde `a3` fijado en el último ciclo.
3. **Modelo de 1 ciclo por operación** (p.3, §2.2): *"each operation is executed in one time
   step"*. Confirma textualmente que el grano unitario por operador es el estándar de HLS, no
   una simplificación propia de este informe.
4. **Movilidad**: el paper define el *mobility range* como `[Eₖ, Lₖ]` (valores ASAP y ALAP) y
   afirma *"smaller the mobility higher the urgency for scheduling"*. No aparece la ecuación
   literal `movilidad = ALAP − ASAP` (usa el rango, equivalente) ni el enunciado
   "movilidad 0 ⇔ camino crítico" — este último es corolario matemático directo de las
   definiciones de ASAP/ALAP que sí están confirmadas.

Parhi (`ref/pahri-slides/chap2.pdf`, `chap4.pdf`) **no** cubre ASAP/ALAP/scheduling (está en
otro capítulo del libro que no se agregó), así que el contraste de ej2 se apoya enteramente en
el paper de TU Delft.

**Conclusión**: 3 de 4 afirmaciones confirmadas *textualmente* contra la fuente primaria
completa; la cuarta (movilidad 0 ⇔ crítico) es corolario directo, no necesita cita aparte.
