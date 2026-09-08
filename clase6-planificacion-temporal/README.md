# Consignas de los Ejercicios

Todos los ejercicios parten del mismo filtro FIR de 4 coeficientes en forma directa (fijado en
el ej1) y comparten latencias de referencia (`t_mul = 2 tu`, `t_add = 1 tu`); el ej6 lo
convierte a un IIR de 1er orden recién sobre el final. Los informes completos, con diagramas,
tablas, RTL y verificación contra fuentes externas, están en **[`docs/`](docs/index.md)**
(empezar por el índice).

## Ejercicio 1: Construir el DFG

Dibujar el DFG (Data Flow Diagram) de un filtro FIR de 4 coeficientes en forma directa. Identificar nodos, aristas y registros ($z^{-1}$).

Documento puro (sin RTL): fija el DFG en forma de **árbol de sumas** (no cadena) para minimizar
el camino crítico, y calcula ese crítico en `tu` (4 tu) — el número que el ej4 va a intentar
bajar. → [`docs/ej1_dfg_fir4.md`](docs/ej1_dfg_fir4.md)

## Ejercicio 2: Aplicar ASAP y ALAP

Asiganr cada nodo a un ciclo bajo recursos ilimitados. Calcular la movilidad de cada operacion.

Sobre el DFG del ej1, da **movilidad 0 en los 7 nodos** — consecuencia directa del árbol
balanceado, no un error de cálculo (verificado con un scheduler ASAP/ALAP propio en Python).
Anticipa por qué la versión iterativa del ej3 no puede lograr los 3 ciclos del ASAP ideal.
→ [`docs/ej2_asap_alap.md`](docs/ej2_asap_alap.md)

## Ejercicio 3: Version Iterativa

Reescribir con 1 cumador y 1 multiplicador compartidos. Disenar la FSM de control y estimar latencia y throughput.

Implementado en RTL real (`ej3_iterativo/`) y medido con testbench, no solo estimado: 1
multiplicador + 1 sumador compartidos (folding, `N=4`), FSM de 3 estados, **4 ciclos de
latencia** y **6 ciclos/muestra de throughput** medidos en simulación.
→ [`docs/ej3_iterativo.md`](docs/ej3_iterativo.md)

## Ejercicio 4: Version pipeline

Aplicar un cut-set feed-forward para insertar 2 etapas de pipeline. Calcular el nuevo camino critico y comparar fmax.

Aplica el cut-set literal (2 cortes, 3 etapas) y además retiming, que llega al mismo fmax con
menos registros y menos latencia (2 etapas en vez de 3) — esa es la versión que se implementa en
RTL (`ej4_pipeline/`), se sintetiza con Yosys, y se verifica con un testbench cruzado contra el
ej3 para confirmar que ambas arquitecturas calculan exactamente la misma secuencia.
→ [`docs/ej4_pipeline.md`](docs/ej4_pipeline.md)

## Ejercicio 5: Comparar PPA

Tabular latencia, Throughput, area (estimada en celdas) y consumo relativo entre las dos versiones.

Compara ej3 (iterativo) vs. ej4 (pipeline) con área real de síntesis (Yosys, DSP48E1/CARRY4/FF/LUT)
en vez de una estimación a mano, y con la aritmética de la tabla recomputada por script:
~2.4× más área para el pipeline, pero ~7.5× más throughput — no es un trade-off 1 a 1.
→ [`docs/ej5_ppa.md`](docs/ej5_ppa.md)

## Ejercicio 6: Identificar IPB

Convertir el FIR a un IIR de 1er orden y calcular IPB. Discutir como bajarlo con Shannon o C-Slow.

El lazo de realimentación del IIR impone un piso de `IPB = 3 tu` que ningún pipeline ni retiming
externo puede franquear. Discute por qué Shannon no tiene sobre qué pivotear acá, cuándo C-Slow
sirve de verdad (multicanal) y por qué look-ahead es la herramienta real para un solo canal —
con la identidad algebraica del look-ahead verificada aparte con aritmética exacta.
→ [`docs/ej6_ipb.md`](docs/ej6_ipb.md)
