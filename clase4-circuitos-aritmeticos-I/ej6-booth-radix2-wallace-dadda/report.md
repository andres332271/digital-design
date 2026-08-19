# Ejercicio 6 — Booth radix-2 signado combinacional

## Motivación

Cerrar la serie ej4/ej5/ej6 con un multiplicador Booth radix-2, signado, combinacional: mismo producto
8×8 → 16 bits que ej4 y ej5, pero generando partial products con signo (0 / +A / -A) en vez de las AND
crudas de ej5. El objetivo declarado de la consigna es comparar contra las dos arquitecturas anteriores, no
optimizar Booth en el vacío.

## Implementación

Un solo módulo, `booth_r2.sv`, combinacional:

- Por cada bit `i` de `b` (con `b[-1]=0` asumido), el par `{b[i], b[i-1]}` decide la partial product según
  la tabla de la consigna: `00`/`11` → `0`, `01` → `+A`, `10` → `-A`.
- Cada PP se sign-extiende a 16 bits (`a_ext`) y se desplaza `i` posiciones a la izquierda; la suma final
  se hace con aritmética de complemento a 2 de 16 bits (`product = pp[0] + ... + pp[7]`), que da el
  resultado correcto por aritmética modular aunque una PP individual "se salga" del rango representable,
  porque el producto final de 8×8 signado siempre entra en 16 bits.
- No se usa el atajo clásico de "vector de corrección" (CV) que sugiere el tip del enunciado para ahorrar
  hardware a nivel de compuertas — se sign-extiende cada fila por completo. Esa optimización de compuertas
  es justamente terreno de un árbol Wallace/Dadda a nivel gate, no del módulo base.
- La suma se hace con `+` de SystemVerilog, igual criterio que usó `mul_seq.sv` (ej4) para su sumador:
  ningún entregable de ej6 pide una matriz de full adders para la suma base (a diferencia de ej5, donde sí
  era un requisito explícito) — esa exigencia estructural solo aparece, y de forma opcional/conceptual, en
  la comparación Wallace vs Dadda.

**Cantidad de PPs generados: 8** — igual que ej4 (shift-and-add, 8 sumas condicionales) e igual que ej5 (8
filas de partial products). Radix-2 no reduce la cantidad de filas a sumar respecto de esas dos
arquitecturas; esa reducción solo aparece en radix-4 o superior (ver discusión más abajo).

## Resultados

Testbench (`tb_booth_r2.sv`), combinacional, golden model embebido con `$signed(a) * $signed(b)`, barrido
exhaustivo de los 256×256 = 65536 pares signados (-128..127 cada operando):

```
==========================================================
 Ejercicio 6 - Booth radix-2 signado combinacional (N=8)
==========================================================
 PPs generados por operacion: 8
 Barrido exhaustivo: 65536 pares

  pares verificados: 65536

 RESULTADO: OK - sin discrepancias
==========================================================
```

Sin discrepancias en los 65536 casos, incluyendo los bordes de signo (`a=-128`, donde `-a` necesita el
ancho extendido a 16 bits para no desbordar, y `a=b=-128`, producto máximo 16384, que entra en 16 bits con
margen).

### Tabla comparativa Wallace vs Dadda (análisis conceptual)

La consigna marca esta comparación como "avanzada (opcional)" y permite resolverla a nivel conceptual, sin
construir las dos redes de reducción en RTL. Para 8 partial products de entrada, la secuencia estándar de
alturas de un árbol de compresores 3:2/2:2 es la misma para ambos esquemas (Wallace y Dadda solo difieren
en *cuándo* comprimen dentro de cada etapa, no en cuántas etapas hacen falta):

| Etapa | Altura antes | Altura después | Regla |
|:-----:|:------------:|:---------------:|-------|
| 1 | 8 | 6 | ⌈8·2/3⌉ |
| 2 | 6 | 4 | ⌈6·2/3⌉ |
| 3 | 4 | 3 | ⌈4·2/3⌉ |
| 4 | 3 | 2 | ⌈3·2/3⌉ |

4 etapas de reducción en ambos casos, terminando en 2 filas listas para un sumador final (CPA, como el de
ej5). La diferencia real está en la cantidad de celdas:

| | Wallace | Dadda |
|---|---|---|
| Criterio de reducción | Comprime tan pronto como puede en cada etapa (máximo paralelismo) | Comprime lo mínimo necesario para llegar a la altura objetivo de la próxima etapa |
| Half adders usados | Más (aparecen temprano, para "parejas sueltas" de cada etapa) | Menos (se posterga su uso todo lo posible) |
| Full adders usados | Similar orden de magnitud | Similar orden de magnitud, algo menos en total |
| Ancho del sumador final | Suele quedar más angosto | Puede quedar algo más ancho, absorbe más bits sin reducir |

Conclusión conceptual: a igual cantidad de filas de entrada, ambos árboles necesitan el mismo número de
etapas (mismo retardo asintótico, `O(log N)` frente a las `O(N)` de un array/CSA lineal como ej5), pero
Dadda tiende a usar menos celdas totales — sobre todo menos half adders — a costa de un sumador final
ligeramente más ancho. Esta tabla es un análisis de libro (fórmulas estándar de reducción de matrices de
puntos), no una medición sobre una implementación RTL propia: ningún entregable de este ejercicio pide
construir ambas redes.

### Discusión: ¿cuándo Booth no ayuda?

Con los tres ejercicios de esta clase ya implementados y medidos, la comparación es concreta:

- **Cantidad de PPs**: ej4 hace 8 sumas condicionales secuenciales, ej5 genera 8 filas de PP combinacional,
  y este ejercicio (Booth radix-2) también genera **8** PPs. Recodificar de a pares de bits en radix-2 no
  reduce la cantidad de filas a sumar frente a no recodificar — solo cambia el valor de cada fila (0/+A/-A
  en vez de 0/A) y agrega la lógica de selección/negación en complemento a 2 por fila. En forma
  combinacional, eso es hardware extra sin ninguna reducción de sumandos a cambio.
- **Dónde sí ayuda Booth radix-2**: en la versión **secuencial**, donde cada PP corresponde a un ciclo de
  reloj — ahí, si una implementación detecta corridas largas de bits iguales (`00...0` o `11...1`) y salta
  esos ciclos sin sumar, Booth reduce la cantidad de ciclos reales por debajo del caso peor. El shift-and-add
  de ej4 no hace ese salto (es de 8 ciclos fijos siempre), así que no lo demuestra; existe una referencia
  Booth radix-2 secuencial en `clase3-codificación-numérica/ej5_booth_radix2/` que sí itera 1 PP por ciclo
  y sería el punto de comparación natural si se quisiera medir ese ahorro en ciclos.
- **Dónde Booth ayuda de verdad en combinacional**: recién en radix-4 (o superior), donde se examinan
  tríos de bits en vez de pares y la cantidad de PPs se reduce a la mitad (4 filas en vez de 8 para N=8) —
  ahí sí hay menos filas para sumar, y un árbol Wallace/Dadda sobre esas 4 filas necesita menos etapas que
  sobre las 8 originales. Radix-2 combinacional, en cambio, es estrictamente más caro que el array
  multiplier de ej5 para el mismo trabajo: mismas 8 filas, más lógica por fila, mismo tipo de sumador final.
