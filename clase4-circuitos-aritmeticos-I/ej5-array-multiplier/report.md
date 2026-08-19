# Ejercicio 5 — Array Multiplier 8×8 combinacional

## Motivación

Implementar el mismo producto 8×8 → 16 bits de ej4, pero como una matriz combinacional explícita de
sumadores en vez de reusar un solo sumador N veces. Es el segundo punto de referencia de la serie
ej4/ej5/ej6: cambia ciclos de reloj por área, y sirve de base estructural (celdas HA/FA) para ej6.

## Implementación

Tres módulos:

- **`half_adder.sv`** / **`full_adder.sv`**: celdas de 1 bit reusables (también las va a necesitar ej6
  para sus filas de reducción).
- **`array_mul.sv`**: arquitectura clásica de array multiplier, toda por `generate`:
  1. **Partial products**: `pp[i][j] = a[j] & b[i]`, matriz de 8×8 AND.
  2. **7 filas de reducción carry-save** (`i=1..7`): cada columna combina la PP de esa fila con la suma
     diagonal de la fila anterior (`sum_row[i-1][j+1]`) y el carry directo (`carry_row[i-1][j]`) — full
     adder, salvo la columna más a la derecha (`j=7`), que no tiene entrada diagonal y usa half adder. El
     bit `sum_row[i][0]` de cada fila queda fijo como `product[i]` apenas se calcula.
  3. **Fila final (CPA)**: ripple-carry adder de 8 bits que suma el vector de sumas y el de carries que
     quedaron de la última fila CSA, con acarreo de entrada 0 (por eso su primera celda también es un half
     adder). El resultado son los 8 bits altos del producto; el carry de salida de la última celda es
     estructuralmente siempre 0 (8×8 unsigned nunca desborda 16 bits), así que queda sin conectar.

## Resultados

Testbench (`tb_array_mul.sv`), puramente combinacional (sin `clk`): golden model embebido con el operador
`*` de SystemVerilog (`esperado = a * b`), barrido **exhaustivo** de los 256×256 = 65536 pares posibles.

```
==========================================================
 Ejercicio 5 - Array multiplier combinacional (N=8)
==========================================================
 Barrido exhaustivo: 65536 pares

  pares verificados: 65536

 RESULTADO: OK - sin discrepancias
==========================================================
```

Sin discrepancias en los 65536 casos — esto ya es, en sí mismo, la comparación pedida en la consigna contra
"un multiplicador en RTL con `*`": el golden model del testbench *es* ese multiplicador RTL comportamental
(`a * b`), y la verificación exhaustiva demuestra que `array_mul` (estructura explícita, celda por celda)
es funcionalmente equivalente a delegarle todo al operador `*` y dejar que el sintetizador decida la
estructura interna. No hay sintetizador instalado en este repo, así que el área/delay real de la versión
`*` no se puede medir — solo se puede razonar en abstracto (siguiente sección).

### Tabla de celdas

| Bloque                          | Half adders | Full adders | Total |
|----------------------------------|:-----------:|:-----------:|:-----:|
| 7 filas CSA (1 HA + 7 FA c/u)    | 7           | 49           | 56    |
| Fila final CPA (1 HA + 7 FA)     | 1           | 7            | 8     |
| **Total**                        | **8**       | **56**       | **64**|

Más 64 AND de 2 entradas para las partial products.

### Delay teórico

Camino crítico: desde la PP superior-derecha (`pp[0][7]`) hasta el bit más significativo del producto
(`product[15]`) hay que atravesar las 7 filas CSA en diagonal y luego las 8 celdas de la fila final CPA en
cadena de acarreo — del orden de `2N-1 = 15` retardos de celda (`t_FA`) para N=8. Es la cota clásica de un
array multiplier con CPA final (lineal en N), muy por debajo de N² pero peor que un árbol Wallace/Dadda
(orden `log N`), que es justamente lo que compara ej6.

### Comparativa cuantitativa contra ej4 (secuencial)

| | ej4 (shift-and-add) | ej5 (array) |
|---|---|---|
| Latencia | 8 ciclos de reloj (medido) | 1 paso combinacional (~15·t_FA, teórico) |
| Hardware | 1 sumador de 9 bits + registros de 16+8 bits + FSM de 3 estados | 64 celdas de 1 bit (8 HA + 56 FA) + 64 AND, sin registros |
| Escalado en N | Hardware ≈ constante en N, tiempo ≈ O(N) ciclos | Hardware ≈ O(N²) celdas, tiempo ≈ O(N) retardos de compuerta |
| Throughput | 1 resultado cada 8 ciclos (sin pipeline) | 1 resultado por operación, limitado solo por el período de reloj externo (si se registra la salida) |

ej5 cambia área (O(N²) celdas) por latencia (un solo paso combinacional en vez de N ciclos): mismo
resultado, mismo ancho de operandos, arquitectura opuesta en el trade-off área/tiempo. La comparación
contra ej6 (Booth radix-2, `../ej6-booth-radix2-wallace-dadda/report.md`) muestra que, en forma
combinacional, Booth radix-2 genera la misma cantidad de PPs (8) que este array multiplier — no hay ahorro
de filas a sumar, solo lógica extra de selección/negación por fila; la reducción real de PPs recién aparece
en radix-4 o superior, que es donde un árbol Wallace/Dadda tendría ventaja frente a la matriz lineal de
este ejercicio.
