# Informe Ejercicio 4 - Versión pipeline (cut-set feed-forward)

## Motivación

El DFG de ej1 es puramente combinacional: `y[n]` sale 4 tu después de que llegan los operandos
(1 mult + 2 add en cadena, camino crítico calculado en ej1), sin ningún registro interno que
lo parta. Eso fija el período de clock mínimo en 4 tu. Este ejercicio corta ese camino con
registros de pipeline (feed-forward cut-set) para subir fmax, y compara el resultado literal
del enunciado con lo que da aplicar además retiming — que resulta ser mejor con menos hardware.

Latencias de referencia (las mismas de ej1/ej3): `t_mul = 2 tu`, `t_add = 1 tu`.

## Paso 1 — Original (sin pipeline)

```
m0 m1 m2 m3     (× × × ×, 2 tu cada uno, en paralelo)
 \ /   \ /
  a1    a2       (+ +, 1 tu cada uno, en paralelo)
   \   /
    a3            (+, 1 tu) → y[n]
```

Camino crítico: `m_i → a1|a2 → a3` = **2 + 1 + 1 = 4 tu**. `fmax = 1 / 4tu`. 0 registros
internos — todo el filtro es una nube combinacional entre el registro de entrada (la línea de
retardo `x[n-k]`) y el de salida.

## Paso 2 — Cut-set feed-forward, 2 etapas insertadas (literal del enunciado)

El DFG tiene 3 niveles lógicos (mults → add nivel 1 → add nivel 2). Insertar 2 etapas de
pipeline significa cortar en **las 2 fronteras entre niveles**: todas las aristas van en la
misma dirección en cada corte (feed-forward, sin bucles), así que ambos son cut-sets válidos.

- **Cut-set A**: entre `m0..m3` y `a1,a2` → 4 registros (uno por producto).
- **Cut-set B**: entre `a1,a2` y `a3` → 2 registros (uno por suma parcial).

```
Etapa 1 (registros tras m0..m3)     Etapa 2 (registros tras a1,a2)     Etapa 3
[m0 m1 m2 m3] -- reg×4 -->  [a1 a2] -- reg×2 -->  [a3] -- reg → y[n]
   2 tu                        1 tu                   1 tu
```

Camino crítico por etapa: `max(2, 1, 1) = 2 tu` → **fmax = 1 / 2tu**, el doble que la versión
original. Límite: la etapa del multiplicador (2 tu) — ningún cut-set entre operadores completos
puede bajar el crítico por debajo del operador más lento sin partir ESE operador por dentro
(pipelinear el multiplicador mismo), que queda fuera del alcance de este DFG a nivel de
operadores.

**Latencia**: 3 etapas × período 2 tu = **6 tu** (vs. 4 tu original) — sube, como predice el
slide 17 ("warm-up"). **Throughput** en régimen permanente: 1 resultado cada 2 tu (vs. 1 cada
4 tu) — se duplica.

## Retiming: la misma fmax con menos etapas

Nivel `a1,a2` y nivel `a3` son ambos sumadores de 1 tu — juntos sólo suman 2 tu, exactamente lo
mismo que la etapa del multiplicador. El **Cut-set B es redundante para fmax**: no hace falta
partir la cadena de sumas en dos etapas separadas, porque combinadas (2 tu) ya empatan con la
etapa más lenta (el multiplicador, 2 tu). Aplicando el teorema de transferencia nodal para
retirar el Cut-set B y dejar solo el Cut-set A:

```
Etapa 1 (registros tras m0..m3)          Etapa 2
[m0 m1 m2 m3] -- reg×4 -->      [a1 a2 → a3] → y[n]
      2 tu                            1+1 = 2 tu
```

Mismo `fmax = 1/2tu` (el crítico sigue acotado por el multiplicador), pero con **2 etapas en
vez de 3** → latencia = 2 × 2tu = **4 tu**, igual a la versión sin pipeline, y con la mitad de
los registros de pipeline (solo el Cut-set A: 4 registros, contra 6 de la versión de 3 etapas).
Esto es exactamente el patrón del PASO 3 del ejemplo de 3 coeficientes de la presentación
(slide 26): el cut-set inicial sube fmax, el retiming después **minimiza los registros sin
tocar la función de transferencia ni el fmax ya ganado**.

## Comparación fmax

| Versión | Camino crítico | fmax | Latencia | Registros de pipeline |
|---|---|---|---|---|
| Original (ej1) | 4 tu | 1/4tu | 4 tu (0 ciclos) | 0 |
| Cut-set literal (2 cortes, 3 etapas) | 2 tu | 1/2tu (×2) | 6 tu (3 ciclos) | 6 |
| Cut-set + retiming (1 corte, 2 etapas) | 2 tu | 1/2tu (×2) | 4 tu (2 ciclos) | 4 |

La versión con retiming es la que conviene llevar al ej5 (comparación PPA): mismo fmax que la
versión de 3 etapas, con menos área de registros y menos latencia — estrictamente mejor, no un
trade-off distinto. Por eso es la que se implementa en RTL abajo, no la de 3 etapas.

## Implementación RTL (versión retimeada, 2 etapas)

A diferencia de ej1/ej2 (documentos puros), acá conviene bajar a RTL real: permite verificar
funcionalmente el resultado del retiming y, sobre todo, **sintetizarlo** para comparar área
contra ej3 con números reales en vez de una estimación a mano (ver discusión en ej5).

- `ej4_pipeline/fir_pipeline.sv`: streaming puro, sin FSM — el control es un `valid` que viaja
  junto con los datos por las 2 etapas (`always_ff` sin lógica de estados). Etapa 1: 4
  multiplicadores en paralelo, registrados (Cut-set A). Etapa 2: `a1`, `a2`, `a3`
  combinacionales (sin registro entre ellas, la simplificación de retiming de arriba), salida
  registrada.
- `ej4_pipeline/tb_fir_pipeline.sv`: golden model con una cola FIFO de valores esperados (el
  pipeline es in-order): aplica 200 muestras *back-to-back* (`valid_in=1` todos los ciclos, el
  caso de régimen permanente) y compara cada `valid_out` contra el frente de la cola.

**Coeficientes**: se usaron `{17, -23, 41, -5}` a propósito, ninguno potencia de 2 ni ±1. Con
los coeficientes originales (`{3,-2,5,1}`, elegidos sin pensar en la síntesis) Yosys optimiza
`×1` a un cable y `×(-2)` a un shift-and-negate, así que sólo 2 de los 4 "multiplicadores"
terminaban usando un DSP real — falseaba justo la comparación de recursos que se busca en ej5
(1 mult compartido vs. 4 en paralelo). Con coeficientes genéricos, cada multiplicación es real.

```
RESULTADO: OK - sin discrepancias, pipeline totalmente drenado
LATENCIA: 2 ciclos (valid_in -> valid_out), fija por construccion (streaming)
THROUGHPUT: 1 muestra/ciclo en regimen permanente (200 muestras en 200 ciclos back-to-back)
```

## Síntesis (Yosys, `synth_xilinx -family xc7`)

Mismo flujo que `Modulo 5/EJ2/synth.ys` (mapeo lógico a primitivas XC7, sin place&route ni
timing sign-off — por eso el fmax de la sección anterior sigue siendo el analítico en `tu`, acá
solo se compara **área real**):

| Recurso | ej3 (iterativo) | ej4 (pipeline, este archivo) |
|---|---:|---:|
| DSP48E1 (multiplicadores) | 1 | 4 |
| CARRY4 (sumadores) | 1 | 5 |
| FF (FDCE/FDPE) | 56 | 98 |
| LUT (total LUT2..LUT6) | 36 | 67 |
| MUXF7 | 0 | 23 |
| LCs estimados (heurística de `synth_xilinx`) | ~32 | ~60 |

El multiplicador de ej3 sale exactamente **1 DSP48E1** (coeficiente variable en tiempo de
ejecución vía `coef(idx)`, Yosys no puede constant-fold un valor que depende de una señal), y el
de ej4 sale exactamente **4 DSP48E1** — la síntesis confirma al pie de la letra el "1 mult
compartido vs. N mults en paralelo" que motivó todo el ejercicio, sin necesidad de estimarlo a
mano. Detalle completo en `docs/ej5_ppa.md`.

## Verificación cruzada: ¿de verdad calculan lo mismo?

Todo lo de arriba asume que el retiming preservó la función de transferencia — es el teorema de
transferencia nodal, no debería hacer falta comprobarlo, pero cada testbench
(`ej3_iterativo/tb_fir_iter.sv`, `ej4_pipeline/tb_fir_pipeline.sv`) compara contra su **propio**
golden model, nunca uno contra el otro. `ej5_ppa/tb_cross_check.sv` cierra ese hueco: instancia
`fir_iter` y `fir_pipeline` juntos, les da la misma secuencia de 100 muestras (cada uno a su
propio ritmo — start/done vs. streaming) y compara las dos salidas elemento a elemento.
Resultado: **100/100 coinciden exactamente** (`ej5_ppa/run_cross.sh`) — no solo el álgebra dice
que son el mismo filtro, la simulación también.

## Contraste con fuentes externas

Fuente primaria: Parhi, *VLSI Digital Signal Processing Systems*
(`ref/pahri-slides/chap4.pdf`, 12 páginas, leído completo — el capítulo de retiming).

1. **Retiming preserva la función y no cambia registros por ciclo** (p.2-4, citas exactas):
   *"Retiming: Moving around existing delays. Does not alter the latency of the system.
   Reduces the critical path"* y *"Retiming does not change the number of delays in a cycle"*.
   Confirma que mover el Cut-set B con el teorema de transferencia nodal no cambia lo que
   calcula el filtro.
2. **Los dos objetivos del retiming son los de este ejercicio** (p.4): *"Retiming is done to
   meet the following: Clock period minimization, Register minimization"* — es literalmente la
   estructura de la sección "Retiming: la misma fmax con menos etapas" (primero baja el
   crítico con Cut-set A+B, después retira el Cut-set B redundante sin perder el fmax ganado).
3. **Folding es capítulo aparte** (p.12): *"Retiming for Folding (Chapter 6)"* — re-confirma
   que folding no está en chap2/chap4.
4. **"Feed-forward cutset" con ese nombre exacto no aparece**: lo que sí está (p.2) es
   *"Cutset Retiming"* en general y la fórmula por nodo `ω' = ω + r(V) − r(U)` — mismo concepto
   de fondo, pero sin el requisito explícito "todas las aristas en la misma dirección" que sí
   está en `ref/Modulo_6.pptx` (slide 19). Esa parte viene de la síntesis del profesor, no la
   puedo confirmar contra Parhi.

**Hallazgo colateral** (p.8-9, K-slow / 2-slow): reemplazar cada registro por `k` registros es
válido y correcto **incluso con 1 solo stream** — no requiere streams independientes para ser
correcto, solo para aprovechar el hardware al 100% (*"Hardware Utilization = 50%"* con 1
stream). Aplica directo a ej6.

**Conclusión**: 3 de 4 afirmaciones confirmadas contra el texto primario completo; la cuarta
("feed-forward" específicamente) viene de las slides de la clase, no es incorrecta pero no
tiene respaldo directo en este capítulo.
