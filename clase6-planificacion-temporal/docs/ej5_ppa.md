# Informe Ejercicio 5 - Comparación PPA: iterativo (ej3) vs. pipeline (ej4)

## Motivación

Las "dos versiones" del enunciado son la iterativa de ej3 (1 mult + 1 add compartidos, FSM) y
la pipeline retimeada de ej4 (2 etapas, streaming, sin FSM). Ambas están implementadas en RTL,
verificadas con testbench propio, y **sintetizadas con Yosys** (`synth_xilinx -family xc7`,
mismo flujo que `Modulo 5/EJ2/synth.ys`) — así que el área de esta tabla es la que reporta
`stat`, no una estimación a mano. Lo que sigue siendo analítico (no hay P&R ni timing
sign-off, igual que en Modulo 5) es el camino crítico en `tu` para fmax.

## Cómo se obtuvieron estos números

Ningún valor de esta tabla se inventó a mano — cada fila tiene un origen distinto y conviene
saber cuál, porque no todos tienen el mismo nivel de certeza.

### Latencia y throughput → salida de `run.sh` (simulación, Icarus)

Salen de los `$display` finales de `ej3_iterativo/tb_fir_iter.sv` (ej3) y
`ej4_pipeline/tb_fir_pipeline.sv` (ej4), no de un cálculo — correr `ej3_iterativo/run.sh` o
`ej4_pipeline/run.sh` los reproduce.

- **ej3**: la línea `LATENCIA: OK - 4 ciclos constantes en las 205 muestras` sale de contar,
  en el propio testbench, los ciclos en que `dut.busy` está en alto entre un `load` y el
  siguiente (señal `ciclos_op`, incrementada en `always_ff @(posedge clk)` — es un contador de
  ciclos de simulación, no un tiempo físico). La línea `THROUGHPUT: 6.00 ciclos/muestra` sale de
  medir `$time` antes y después del bloque de 200 muestras aleatorias y dividir por
  `PERIODO` (10 ns) y por la cantidad de muestras — es tiempo de simulación real entre el primer
  y el último `start`, no una cuenta manual de estados de la FSM. Por eso no da exactamente el
  mínimo teórico de la FSM (`N+1=5` ciclos): incluye el margen que le agrega el *driver* del
  testbench al mantener `start` en alto un período completo (explicado en
  `docs/ej3_iterativo.md`).
- **ej4**: `LATENCIA: 2 ciclos` es un hecho de construcción (2 registros entre `valid_in` y
  `valid_out`, contable directamente del RTL), no algo medido — pero el testbench lo ejercita
  igual. `THROUGHPUT: ... 200 muestras en 200 ciclos back-to-back` sí es medido: cuenta cuántos
  ciclos de clock pasaron entre aplicar la primera y la última de 200 muestras con `valid_in=1`
  sostenido, y da exactamente 1 ciclo/muestra porque el pipeline nunca tiene que esperar (no
  comparte hardware entre muestras).
- Las filas en `tu` (`1/15 tu⁻¹`, `1/2 tu⁻¹`, etc.) combinan el dato medido en ciclos con el
  `T_clk` analítico de la sección siguiente — son ciclos × tu/ciclo, no una medición directa.

### Área → `yosys.log` de cada carpeta, comando `stat` dentro de `synth.ys`

`ej3_iterativo/synth.ys` y `ej4_pipeline/synth.ys` corren
`read_verilog -sv <archivos> ; synth_xilinx -family xc7 -top <modulo> ; stat`. `run.sh` guarda
la salida completa en `yosys.log` (`yosys -s synth.ys > yosys.log`). Ese archivo tiene varios
bloques de conteo (uno por cada pasada interna de optimización); el que hay que leer es el
**último**, justo antes de `Warnings: ...` al final del archivo — los anteriores son estados
intermedios de la síntesis, no el resultado final:

- **ej3**: como `ej3_iterativo/fir_iter.sv` instancia `control_fsm` como submódulo separado, el bloque final
  relevante es `=== design hierarchy === / Count including submodules` (el que sí suma las
  celdas de la FSM al total). Ahí es de donde salen los 183 celdas / 1 DSP48E1 / 1 CARRY4 / 56
  FF / 36 LUT de la tabla.
- **ej4**: `ej4_pipeline/fir_pipeline.sv` es un único módulo plano (sin submódulos propios), así que el
  bloque final `=== fir_pipeline === / Local Count, excluding submodules` ya es el total
  completo: 326 celdas / 4 DSP48E1 / 5 CARRY4 / 98 FF / 67 LUT.

**Cómo leer cada primitiva** (todas son primitivas físicas de la familia Xilinx XC7, no
lógica genérica):

| Primitiva | Qué es |
|---|---|
| `DSP48E1` | Bloque de multiplicación/MAC dedicado (hardware fijo, no consume LUTs) |
| `CARRY4` | Cadena de acarreo rápido de 4 bits — lo que arma un sumador en LUTs sin usarlas para el acarreo |
| `FDCE` / `FDPE` | Flip-flop de 1 bit con *clock enable* (`FDCE`) o *set* asíncrono (`FDPE`) — un registro real por instancia |
| `LUT2`..`LUT6` | Look-up table combinacional de 2 a 6 entradas — la unidad básica de lógica programable |
| `MUXF7` | Mux dedicado que combina la salida de dos `LUT6` para armar lógica de 7 entradas |
| `IBUF`/`OBUF`/`BUFG` | Buffers de entrada/salida y de reloj — cuentan como celdas pero no son "lógica de diseño", son E/S |
| `Estimated number of LCs` | Heurística propia de `synth_xilinx` (logic cells equivalentes a un FPGA de 6-LUT) — orientativa, no viene de `stat` sino de un paso previo del flujo |

Importante: esto es **mapeo lógico**, no post-P&R — no hay `place_and_route` ni STA (mismo
límite que `Modulo 5/EJ2`, ver comentario en los `.ys`). Los números de celdas son reales y
reproducibles; no hay un número de área en mm² ni un fmax en MHz reales acá.

### fmax / T_clk en `tu` → analítico, NO sale de la síntesis

`T_clk = 3 tu` (ej3) y `2 tu` (ej4) son el camino crítico calculado a mano en
`docs/ej1_dfg_fir4.md` y `docs/ej4_pipeline.md`, usando las latencias de referencia
supuestas `t_mul=2tu`, `t_add=1tu` fijadas en ej1. Yosys no tiene un modelo de retardo para el
`DSP48E1` sin un `place_and_route` real (probado con `ltp`: el camino que reporta ignora el
retardo interno del DSP, que queda como caja negra), así que no hay forma honesta de sacar un
fmax en ns de este flujo — por eso esta fila sigue siendo la estimación simbólica, igual que en
ej1/ej4, y se lo marca explícitamente como "analítico" en la tabla de abajo para no confundirlo
con los datos medidos/sintetizados.

### La aritmética que combina todo esto → recomputada con un script, no solo a mano

Los tres orígenes de arriba (ciclos medidos en sim., `T_clk` analítico, y las divisiones que los
combinan en `tu`⁻¹ y en el "throughput relativo ≈7.5×") se mezclan en varias cuentas encadenadas
— el tipo de aritmética donde un error de tipeo en el denominador pasa desapercibido si solo se
revisa releyendo el markdown. `ej5_ppa/verify_ppa_numbers.py` las recalcula todas juntas a
partir de las mismas constantes de esta página (`T_MUL=2`, `T_ADD=1`, `LAT_CICLOS_ITER=4`, etc.,
cada una con su origen — medida o analítica — marcado en el propio script) y compara contra los
valores ya publicados. Usa `fractions.Fraction` en vez de `float` específicamente para el
throughput relativo: da `15/2` exacto, no un `7.5` que podría estar escondiendo un redondeo.
Corre con `cd ej5_ppa && python3 verify_ppa_numbers.py`: imprime cada cuenta junto al valor del
report y termina con `RESULTADO: OK` — ninguna de las divisiones encadenadas tenía un error.

## Período de clock de cada arquitectura (analítico, en `tu`)

- **ej3 (iterativo)**: `acc <= acc + coef(idx)*taps[idx]` encadena mult y add **dentro del
  mismo ciclo** (sin registro entre `prod` y `acc`). Camino crítico = `t_mul + t_add` = **3 tu**.
- **ej4 (pipeline retimeado)**: 2 etapas balanceadas a `max(t_mul, t_add+t_add)` = **2 tu**
  cada una (`docs/ej4_pipeline.md`).

## Área — síntesis real (Yosys, XC7)

| Recurso | ej3 — Iterativo | ej4 — Pipeline |
|---|---:|---:|
| DSP48E1 (multiplicadores) | 1 | 4 |
| CARRY4 (sumadores/acarreo) | 1 | 5 |
| FF (FDCE + FDPE) | 56 | 98 |
| LUT (LUT2..LUT6) | 36 | 67 |
| MUXF7 | 0 | 23 |
| LCs estimados (`synth_xilinx`) | ~32 | ~60 |

Con coeficientes genéricos (`{17,-23,41,-5}`, ninguno potencia de 2 ni ±1 — ver nota en
`docs/ej4_pipeline.md` sobre por qué eso importa) el conteo de DSP48E1 confirma
**exactamente** la arquitectura de cada uno: 1 multiplicador compartido en tiempo (ej3) vs. 4
multiplicadores físicos en paralelo (ej4). Los FF también reflejan lo esperado: ej4 tiene ~1.75×
más registros (4 productos de 16 bit + salida de 18 bit, contra la línea de retardo + acumulador
+ FSM de ej3), y ~1.7× más LCs en total — pero la brecha de área es **mucho menor** que si el
multiplicador se contara como lógica programable (como en el estimado a mano de una versión
anterior de este informe): en un FPGA real, el multiplicador casi no cuesta LUTs porque va a un
bloque DSP dedicado. La estimación por "celdas" al estilo `clase4/ej5-array-multiplier` (pensada
para ASIC, sin macros de multiplicación) hubiese exagerado la diferencia de área entre estas dos
arquitecturas para este target.

## Tabla PPA

| Métrica | ej3 — Iterativo | ej4 — Pipeline (retimeado) |
|---|---|---|
| Período de clock (T_clk, analítico) | 3 tu | 2 tu |
| fmax (1/T_clk) | 1/3 tu⁻¹ | 1/2 tu⁻¹ (**1.5×**) |
| Latencia | 4 ciclos = 12 tu (medida en sim.) | 2 ciclos = 4 tu (medida en sim.) |
| Throughput | 1 muestra / 5 ciclos = 1/15 tu⁻¹ (mínimo FSM); 1/18 tu⁻¹ medido con overhead de TB | 1 muestra / 1 ciclo = 1/2 tu⁻¹ (medido, streaming back-to-back) |
| Throughput relativo | 1× (referencia) | **≈7.5×** (teórico) |
| DSP48E1 / CARRY4 / FF / LUT (sintetizado) | 1 / 1 / 56 / 36 | 4 / 5 / 98 / 67 |
| Consumo relativo | Menor: 1 DSP + 1 acumulador activos por ciclo | Mayor: 4 DSP conmutando cada ciclo + ~1.75× más FF activos |

## Discusión

El resultado es el trade-off de libro (slides 38-39): **folding** (ej3) gana área y consumo,
pierde throughput y necesita una FSM de control; **pipelining** (ej4) gana fmax y throughput a
costa de replicar hardware (4× DSP) y no necesita FSM — el control se reduce a un `valid` que
viaja con los datos por 2 registros.

El punto que vale remarcar, ahora con números de síntesis reales y no estimados: la ganancia de
throughput (~7.5×) es **mayor** que la de área (4× en DSP, pero solo ~1.7× en LCs totales, y
mucho menos si se pesa por celda de silicio real ya que el DSP48E1 es un bloque fijo, no LUTs).
Esto pasa porque ej3 paga dos penalidades simultáneas por compartir hardware: el folding en sí
(4 operaciones en 4 ciclos en vez de en paralelo) *y* un clock más lento (3 tu vs 2 tu, porque
el MAC encadena mult+add sin registro intermedio). Si ej3 pipelineara internamente su propio MAC
(registrar `prod` antes de sumarlo), bajaría su `T_clk` a 2tu al costo de 1 ciclo más de latencia
por muestra — quedaría más cerca en fmax pero seguiría muy por detrás en throughput, porque el
cuello de botella real es la reutilización de 1 solo DSP para 4 operaciones, no el período de
clock.

## Contraste con fuentes externas

Dos afirmaciones de metodología de este informe se contrastaron contra material externo:

1. **El DSP48E1 no cuesta LUTs porque es silicio dedicado, no lógica programable.** AMD UG1387
   no tiene la frase literal "0 LUTs" pero confirma la idea de fondo (*"Xilinx recommends
   inferring DSP resources"*, describe los DSP48 como *"highly pipelined blocks"*). Una fuente
   más directa (glosario de FPGARelated) sí lo dice explícito: *"Unlike soft logic built from
   lookup tables (LUTs), DSP slices offer […] dramatically lower LUT consumption"* y *"a
   dedicated hard-logic block […] in a single fixed silicon structure"*. Es exactamente el
   argumento de por qué la brecha de área ej3-vs-ej4 es menor de lo que da un estimado ASIC por
   celdas.
2. **`synth_xilinx` es mapeo lógico puro, sin P&R ni timing.** En vez de la doc web de Yosys
   (404 en la URL vieja), la fuente más autoritativa es la propia herramienta instalada:
   `yosys -p "help synth_xilinx"` lista los pasos internos — `map_memory` → `map_ffram` →
   `fine` → `map_cells` → `map_ffs` → `map_luts` (`abc -luts …`) → `finalize` → `check`. **No
   hay ningún paso `place`, `route` ni análisis de timing con retardos físicos** en toda la
   lista. Confirma, desde el binario que generó los `yosys.log`, que el fmax en `tu` de este
   informe sigue siendo el analítico y no sale de la síntesis.

**Conclusión**: ambas afirmaciones se sostienen — una con una fuente externa directa (LUT
consumption del DSP48), la otra con la fuente más autoritativa posible para esa pregunta (el
propio `yosys` instalado).
