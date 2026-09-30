# Resumen de estudio — Módulo 9: Timing, STA y CDC

**Fuente:** `Modulo_9.pptx`, 74 diapositivas. Las diapositivas 1–68 desarrollan la teoría y las 69–74 presentan cinco ejercicios. Las imágenes de este resumen se extrajeron de la presentación original. Los números de diapositiva permiten volver a la explicación visual cuando haga falta.

## Mapa del módulo

1. **Timing:** un circuito puede calcular la función correcta y, aun así, entregar un dato demasiado tarde o cambiarlo demasiado pronto.
2. **STA (Static Timing Analysis):** calcula los tiempos de llegada y requeridos de los caminos del circuito, bajo constraints y condiciones de proceso, tensión y temperatura (PVT).
3. **CDC (Clock Domain Crossing):** protege las señales que pasan entre relojes sin una relación de fase garantizada.
4. **RDC (Reset Domain Crossing):** controla los cruces y la liberación de resets.
5. **Sign-off:** combina las verificaciones de timing, CDC, RDC y las verificaciones físicas que correspondan.

La secuencia de trabajo es `RTL → síntesis → implementación física → STA`, junto con simulación funcional y análisis CDC/RDC. La síntesis estima retardos con información limitada de interconexión. Después de placement, clock tree synthesis (CTS) y routing, STA usa estimaciones cada vez más precisas y finalmente parásitos RC extraídos (diap. 4–8, 29).

## 1. Fundamentos de timing

Una compuerta y sus cables tienen retardo. Además, un flip-flop (FF) necesita que su entrada `D` esté estable durante una ventana alrededor del flanco activo de su reloj:

- **Setup (`Tsetup`):** tiempo mínimo de estabilidad **antes** del flanco de captura.
- **Hold (`Thold`):** tiempo mínimo de estabilidad **después** del flanco de captura.
- **Clock-to-Q (`Tcq`):** tiempo desde el flanco de lanzamiento hasta que cambia la salida `Q` del FF.
- **Skew:** diferencia entre las llegadas del reloj al FF de captura y al FF de lanzamiento.
- **Jitter:** variación temporal de los flancos del reloj.

Una violación de setup o hold puede producir un dato erróneo o metaestabilidad. En una ruta síncrona larga suele preocupar **setup**; en una ruta demasiado corta, **hold**. Reducir la frecuencia puede ayudar a setup, pero no arregla por sí solo una violación de hold (diap. 11–19).

![Camino entre dos flip-flops y ventanas de setup y hold, diapositiva 11](Resumen_Modulo_9_assets/timing_path.png)

### Cuatro tipos de caminos que analiza STA

| Camino | Desde | Hasta | Constraint clave |
| --- | --- | --- | --- |
| I2O | Puerto de entrada | Puerto de salida | Delays de entrada y salida |
| I2R | Puerto de entrada | FF interno | Input delay y clock de captura |
| R2R | FF de lanzamiento | FF de captura | Período de clock y setup/hold |
| R2O | FF interno | Puerto de salida | Output delay y clock de lanzamiento |

El camino **crítico de setup** es el que tiene menos slack de setup, normalmente por lógica combinacional profunda, cargas o interconexión. El **camino crítico de hold** puede ser muy corto. No conviene asumir que ambos son el mismo camino (diap. 9–11, 20).

![Clases de caminos de STA, diapositiva 9](Resumen_Modulo_9_assets/tipos_de_paths.png)

### Ecuaciones que hay que poder usar

Para dos FF del mismo dominio y una transferencia de un ciclo, una aproximación sin skew es:

```text
Setup: Tclk ≥ Tcq,max + Tcomb,max + Tsetup + incertidumbre
Hold:  Tcq,min + Tcomb,min ≥ Thold + margen de hold
Fmax ≈ 1 / Tclk,mín
```

Si se define `skew = llegada_clk_captura − llegada_clk_lanzamiento`, un skew positivo **relaja setup** y **dificulta hold**. Las herramientas aplican además latencias y márgenes según el escenario exacto. Estas ecuaciones son una guía para razonar; el reporte STA es la referencia para el path concreto.

### Arrival, required y slack

```text
Slack de setup = tiempo requerido − tiempo de llegada
Slack ≥ 0: cumple el requisito
Slack < 0: violación
```

En el reporte de la diapositiva 14, el dato llega a `2,41 ns` y se requiere a `1,88 ns`: `slack = 1,88 − 2,41 = −0,53 ns`. Hace falta recuperar **al menos 0,53 ns**, más cualquier margen adicional deseado. Para hold, la herramienta también reporta slack, pero compara el dato más temprano con el instante mínimo permitido; no se debe aplicar mecánicamente la misma resta de setup.

**Cómo leer un reporte:** identificar startpoint y endpoint; comprobar sus clocks; recorrer `Tcq`, celdas y cables; ver el tiempo de llegada; revisar el tiempo requerido, setup e incertidumbre; finalmente mirar el slack. Antes de modificar RTL, confirmar que los constraints del path representan el entorno real.

## 2. Constraints SDC

STA necesita saber a qué tiempo debe operar el diseño. SDC (Synopsys Design Constraints) describe clocks, delays de E/S, incertidumbre y excepciones (diap. 23–27).

```tcl
# Período de 2 ns: objetivo de 500 MHz.
create_clock -name clk -period 2.0 [get_ports clk]

# Dato externo que llega 0,5 ns después de la referencia de clock.
set_input_delay 0.5 -clock clk [get_ports data_in]

# Margen temporal que necesita el receptor externo.
set_output_delay 0.7 -clock clk [get_ports data_out]

# Margen para variaciones del clock, según el flujo utilizado.
set_clock_uncertainty 0.1 [get_clocks clk]
```

Un clock generado, por ejemplo uno dividido, debe declararse con `create_generated_clock` y su relación real con el clock fuente. Clocks con igual frecuencia **no** son automáticamente síncronos: importa que su relación de fase sea conocida y esté garantizada. Los input/output delays modelan al sistema que rodea al bloque; ponerlos en cero sin justificación puede esconder una violación.

### Excepciones

- **Multicycle path:** el diseño *realmente* permite más de un ciclo entre lanzamiento y captura. Para un caso de dos ciclos, la diapositiva 26 muestra `set_multicycle_path 2 -setup` junto con `set_multicycle_path 1 -hold`. El protocolo o enable del circuito debe demostrar que el FF destino no captura antes.
- **False path:** ruta que no necesita cumplir el análisis temporal ordinario por una razón verificable. En un CDC asíncrono se puede exceptuar la entrada del **primer** FF sincronizador, mientras se mantiene temporizada la ruta entre el primer y el segundo FF del destino. Un false path no sincroniza físicamente una señal.

Cada excepción necesita un motivo documentado. Un constraint que solo hace desaparecer un WNS negativo puede ocultar un defecto real. **WNS** es el peor slack negativo; **TNS** acumula los slacks negativos de los endpoints relevantes.

## 3. Cómo cerrar timing

| Técnica | Qué cambia | Beneficio | Costo o cuidado |
| --- | --- | --- | --- |
| Pipeline | Agrega registros y divide la lógica en etapas | Reduce la demora combinacional por etapa y permite mayor frecuencia | Aumenta latencia, registros y complejidad de alineación |
| Retiming | Reubica registros existentes a través de lógica | Equilibra etapas sin agregar necesariamente nuevos FF | Debe preservar función, reset y latencia observable |
| Cloning | Duplica un registro o conductor de alto fanout | Reduce carga por copia y puede bajar delay | Usa más área y potencia |
| Buffers de delay | Aumenta demora de un camino corto | Puede corregir hold | Puede empeorar setup; requiere verificación posterior |

![División de una ruta larga mediante pipeline, diapositiva 21](Resumen_Modulo_9_assets/pipeline.png)

El ejemplo de la diapositiva 30 tiene `Tcomb = 8,5 ns` y `Tcq + Tsetup = 0,7 ns`. Sin pipeline, `Tclk,min ≈ 9,2 ns`, es decir, `Fmax ≈ 108,7 MHz`. Si dos etapas fueran exactamente iguales, cada una tendría `4,25 ns` de lógica: `Tclk,min ≈ 4,95 ns` y `Fmax ≈ 202 MHz`. La cifra de `200 MHz` en la diapositiva es redondeada e **ideal**; registros, lógica desbalanceada, routing e incertidumbre pueden reducirla. El throughput puede ser un resultado por ciclo después de llenar el pipeline, aunque la primera salida llega más tarde.

En DSP suelen aparecer rutas largas en multiplicadores, árboles de sumas y control de interfaces `ready/valid`. El pipeline debe conservar alineados **datos y señales de control**. Tras un cambio de arquitectura, revisar tanto setup como hold y repetir la verificación funcional.

## 4. Alcance de STA y motivo de CDC

STA comprueba retardos de los caminos declarados bajo sus clocks y corners PVT. No demuestra que el algoritmo sea correcto, ni que un protocolo entre clocks asíncronos conserve todos los datos. La simulación funcional comprueba comportamiento con estímulos; el análisis CDC revisa estructuralmente los cruces. También hay que examinar reset (RDC), glitches y posibles reconvergencias (diap. 33–35).

Un **dominio de clock** es el conjunto de FF gobernados por un reloj con una relación temporal conocida. Dos PLL independientes pueden crear dominios asíncronos aun si entregan la misma frecuencia. En un cruce asíncrono, el dato puede cambiar cerca de cualquier flanco del receptor. Por eso el primer FF puede entrar en **metaestabilidad**: su salida tarda un tiempo impredecible en resolver a `0` o `1` (diap. 37–39).

La metaestabilidad no se elimina con lógica digital. Se reduce la probabilidad de que alcance la lógica funcional, dando tiempo de resolución al primer FF. El **MTBF** (tiempo medio entre fallos) depende de la tecnología, la frecuencia de clock, la frecuencia de cambios del dato, el tiempo disponible para resolver y el diseño físico. La frase de la diapositiva 39 sobre “millones de años” es ilustrativa, no una garantía para cualquier circuito.

### Sincronizador de dos FF para una señal de un bit

```text
Dominio A                  Dominio B
FF_origen.Q ── cruce ──> FF1 ──> FF2 ──> lógica destino
                         clkB    clkB
```

`FF1` puede volverse metaestable; `FF2` debe recibir `FF1` **directamente**, sin lógica combinacional entre ellos. Los dos FF usan el clock de destino. En implementación física conviene colocarlos cerca y preservar la cadena frente a optimizaciones. La salida se observa con una latencia aproximada de dos ciclos del destino, según la fase relativa (diap. 40–41).

![Sincronizador de dos flip-flops y su comportamiento temporal, diapositiva 40](Resumen_Modulo_9_assets/doble_flop.png)

**Límite esencial:** dos FF sincronizan un **nivel de un bit**; no garantizan que el destino observe un pulso demasiado corto ni que un bus se capture de forma coherente.

### Glitches y reconvergencia

Una salida combinacional puede producir pulsos breves aunque sus entradas provengan de FF. Antes de cruzar un dominio, registrar esa señal en el origen. Si dos señales relacionadas cruzan mediante cadenas independientes, el destino puede ver una antes que la otra y calcular una combinación que nunca existió en origen. También es peligroso duplicar el sincronizador de una misma señal y reconverger ambas copias. Cuando corresponda, calcular y registrar una única señal en origen; para varios bits relacionados, usar un protocolo que garantice coherencia (diap. 42).

![Dos señales sincronizadas por separado pueden reconverger con valores incompatibles, diapositiva 42](Resumen_Modulo_9_assets/reconvergencia.png)

## 5. Transferencia de datos entre dominios

### Por qué falla el doble FF aplicado bit por bit

En un bus, los bits no cambian ni se propagan exactamente al mismo tiempo. Si cada bit usa su propio sincronizador, el destino puede mezclar bits del valor viejo y del nuevo. Por ejemplo, durante `0001 → 1100` podría aparecer `1001`, que no fue ninguno de los dos valores transmitidos (diap. 44). Hace falta trasladar el **evento de validez** o usar una codificación/protocolo apropiado.

### Enable synchronization para un bus estable

1. El origen registra y mantiene el bus en `data_hold`.
2. El origen anuncia que el bus es válido con una señal de un bit `valid`.
3. El destino sincroniza `valid` mediante dos FF.
4. Cuando detecta el evento sincronizado, captura el bus, que ya lleva tiempo estable.

![Sincronización del indicador VALID mientras se mantiene estable el bus, diapositiva 45](Resumen_Modulo_9_assets/enable_sync.png)

La técnica requiere que `valid` dure lo suficiente para ser capturado y que el bus permanezca estable hasta que el destino lo tome. Para un **pulso de salida de un solo ciclo**, el destino debe detectar el flanco de `valid_sync`, por ejemplo con `valid_sync && !valid_sync_d`; asignar simplemente `data_valid <= valid_sync` mantiene `data_valid` alto mientras lo esté `valid_sync`. Si el origen puede enviar otra palabra antes de que termine la transferencia, se necesita handshake o FIFO. Esta precisión ayuda especialmente en el ejercicio 2 (diap. 45, 71).

### Slow → Fast y Fast → Slow

| Dirección | Riesgo principal | Solución habitual |
| --- | --- | --- |
| Slow → Fast | Metaestabilidad, aunque el nivel suele durar varios ciclos del destino | Doble FF para un bit; `valid` más bus estable si hay datos |
| Fast → Slow | El destino puede no ver un pulso o perder transacciones | Pulso convertido en toggle con ACK, handshake o FIFO |

La **frecuencia por sí sola** no garantiza una transferencia: el nivel debe durar lo suficiente y el protocolo debe impedir que se sobrescriba un dato pendiente. Un evento aislado y una secuencia continua necesitan soluciones distintas (diap. 48, 51–52).

### Toggle handshake / 1-deep FIFO

El emisor mantiene `data_hold` y cambia el bit `toggle` cuando acepta `req`. El destino sincroniza el toggle, detecta que cambió, captura el dato y devuelve un ACK que vuelve sincronizado al origen. El emisor acepta otro dato solo cuando el ACK alcanza el toggle actual:

```text
ready = (toggle == ack_sync)
si req && ready:
    data_hold ← data_in
    toggle    ← ~toggle
```

La regla `req && ready` impide cambiar el toggle dos veces antes de que el destino vea el primer cambio. El bus queda estable durante todo el viaje de ida y vuelta. Es una transferencia confiable de una palabra por handshake, con latencia de varios ciclos de ambos relojes (diap. 49, 73).

![Handshake por toggle con reconocimiento de vuelta, diapositiva 49](Resumen_Modulo_9_assets/toggle_handshake.png)

### Código Gray

El código Gray hace que **valores consecutivos** de un contador difieran en un solo bit:

```systemverilog
assign ptr_gray = ptr_bin ^ (ptr_bin >> 1);
```

Por ejemplo, el binario `0111 → 1000` cambia cuatro bits; los valores Gray correspondientes `0100 → 1100` cambian uno. Para comprobar la propiedad en un testbench, `delta = gray_actual ^ gray_anterior` debe ser one-hot para cada incremento efectivo. Si se permite mantener el contador, `delta` también puede ser cero. Gray **no** hace seguros datos arbitrarios ni saltos de contador. En una implementación física también hay que controlar el skew de los bits para conservar la propiedad al llegar al destino (diap. 53, 72).

### FIFO asíncrona

Una FIFO permite flujo continuo con clocks independientes. Los datos se escriben y leen en una memoria de doble puerto o estructura equivalente. Lo que cruza hacia el otro dominio son los **punteros Gray**, sincronizados con dos FF por bit; la memoria de datos no pasa por sincronizadores bit a bit.

```text
Dominio de escritura                    Dominio de lectura
wptr binario → índice local             rptr binario → índice local
wptr Gray ── sync ────────────────────> compara EMPTY
compara FULL <───────────────── sync ── rptr Gray
```

Si la profundidad es `2^N`, los punteros suelen tener `N+1` bits: `N` para la posición y uno para diferenciar vueltas. En la formulación de la diapositiva 54, `EMPTY` ocurre cuando `rptr_gray == wptr_gray_sync`; `FULL` cuando el próximo puntero de escritura Gray coincide con el puntero de lectura sincronizado con sus **dos bits superiores invertidos**. El cálculo exacto de `FULL` debe usar el próximo estado y los anchos correctos del diseño.

Una FIFO absorbe diferencias **temporales** de velocidad y ráfagas hasta su capacidad. Si la tasa media de escritura supera indefinidamente la de lectura, cualquier profundidad finita acabará en `FULL`; el emisor debe respetar backpressure. Si la lectura supera a la escritura, el receptor debe manejar `EMPTY`. Cada puntero necesita reset adecuado a su dominio (diap. 54–56).

## 6. Reset Domain Crossing (RDC)

Un reset asíncrono puede activarse de inmediato, pero si se **libera** cerca del flanco de clock puede violar recovery/removal y producir un arranque inconsistente. Un patrón común usa dos FF con reset asíncrono y entrada constante `1`: ambos se ponen en `0` al activar el reset; tras liberarlo, el primero pasa a `1` en un flanco y el segundo en el siguiente. Cada dominio necesita su propio sincronizador de liberación (diap. 58–59).

![Reset con activación asíncrona y liberación sincronizada, diapositiva 59](Resumen_Modulo_9_assets/reset_sync.png)

RDC también aparece si registros relacionados usan resets distintos y salen de reset en momentos diferentes, incluso bajo un mismo clock. Por eso hay que revisar las dependencias entre dominios de reset, no solo la línea de reset aislada. **Aserción asíncrona y liberación síncrona** es el patrón mostrado en la presentación; la elección concreta depende del diseño y de la librería.

## 7. Verificación, herramientas y sign-off

- **Simulación RTL:** comprueba función y protocolos con los estímulos que se apliquen.
- **STA:** calcula timing de los caminos configurados y sus corners; necesita constraints correctos.
- **Análisis CDC/RDC estático:** enumera cruces y detecta patrones estructurales como sincronizadores ausentes, glitches, reconvergencia o resets problemáticos. Sus reportes requieren revisar falsos positivos.
- **Gate-level simulation (GLS):** puede mostrar `X` en el primer FF de un sincronizador cuando el modelo de librería detecta una violación esperable de setup/hold. La diapositiva 60 compara tres tratamientos: desactivar timing checks globalmente (puede esconder errores), poner setup/hold a cero en celdas de sincronización (requiere modelos específicos) o usar una librería especializada para esos FF (la opción preferida en la presentación). Ninguno justifica ignorar violaciones en el resto del diseño.
- **Sign-off:** exige reportes limpios o excepciones justificadas; la diapositiva 66 añade DRC y LVS para el cierre físico.

El análisis CDC conviene hacerlo **al terminar el RTL**, repetirlo **después de síntesis** para confirmar que el netlist conserva los sincronizadores, y revisarlo de nuevo **tras el routing**. Un cambio en un cruce o en los clocks exige repetir la revisión. Las herramientas estáticas buscan cruces sin protección, lógica combinacional antes del sincronizador, reconvergencias, sincronizaciones duplicadas y problemas de reset (diap. 63–64).

La presentación menciona Questa CDC, SpyGlass CDC y JasperGold CDC como herramientas dedicadas. Icarus Verilog sirve para simular las prácticas; Verilator aporta lint y chequeos limitados, mientras que Yosys no reemplaza un análisis CDC dedicado. Un flujo de sign-off revisa los hallazgos, documenta los falsos positivos aceptados y combina análisis estático con simulación y STA post-route (diap. 61, 65–66). El nombre de una herramienta no reemplaza la revisión del protocolo ni de sus constraints.

## 8. Guía para resolver los cinco ejercicios

Los ejercicios están definidos en las diapositivas 70–74. La presentación describe módulos y comandos, pero **no incluye en esta carpeta** los archivos `.v`, testbenches ni `run.sh`; los comandos servirán cuando se disponga de esos archivos.

| Ejercicio | Implementación pedida | Qué verificar | Error que ilustra |
| --- | --- | --- | --- |
| 1. `dff_sync2` | Vector `pipe[STAGES-1:0]`, reset, desplazamiento en `dst_clk`, salida en la última etapa | Todas las etapas usan el clock destino; no hay lógica entre FF; latencia y señales de metaestabilidad del testbench | `bad_cross` muestrea directamente la señal asíncrona |
| 2. `enable_sync` | `valid` pasa por dos FF en `clkB`; `data_hold` se captura cuando llega el evento | Bus estable durante la transferencia; `data_valid` dura un ciclo; los 200 casos del testbench pasan | `bad_bus_sync` mezcla bits viejos y nuevos |
| 3. `gray_counter` | Contador de `N+1` bits, salida binaria local y salida Gray | Secuencia completa; XOR de valores Gray consecutivos tiene un solo bit en `1` | Un puntero binario puede cambiar varios bits simultáneamente |
| 4. `toggle_handshake_tx` | Registrar dato y alternar toggle solo con `req && ready`; `ready = (toggle == ack_sync)` | Cuatro datos recibidos en orden, sin pérdida; origen espera ACK | `bad_tx` alterna demasiado rápido para el destino |
| 5. `cdc_unit` | Dos FF para `req` en `clkB`, preservar cadena, capturar dato cuando `sync2` lo indique | Reporte de FF, efecto de quitar `DONT_TOUCH`, excepción SDC y Fmax reportada | La síntesis o constraints pueden invalidar un cruce aparentemente correcto |

### Ejercicio 1: qué entender antes de codificar

En cada `posedge dst_clk`, `pipe[0]` recibe `src_bit`; cada etapa siguiente recibe el valor **anterior** de la etapa previa mediante asignaciones no bloqueantes (`<=`). El reset pone la cadena en un estado conocido. `synced = pipe[STAGES-1]`. Para la demostración estadística, la diapositiva usa `TAU_DEMO = 0`, `3000 ps` y `50 ps`; el modelo didáctico da `P(falla) = exp(-2T/τ)` y espera unas 11 fallas de segunda etapa en 2000 cambios para `τ = 3000 ps`, frente a ninguna para `50 ps`. No interpretar esa probabilidad del testbench como una medición real de MTBF del diseño.

```bash
iverilog -g2012 -o sim dff_sync2.v tb_dff_sync2.v && vvp sim
```

### Ejercicio 2: qué entender antes de codificar

`data_hold` se registra en `clkA`; únicamente `valid` atraviesa el sincronizador en `clkB`. El bus debe conservarse hasta que el receptor lo capture. Si el testbench exige que `data_valid` sea un pulso, generar un pulso al detectar el **flanco** de `vs2` y evitar capturas repetidas si el nivel permanece alto. La diapositiva espera `PASS 200/200` con `clkA = 125 MHz` y `clkB = 38 MHz`.

```bash
iverilog -g2012 -o sim enable_sync.v tb_enable_sync.v && vvp sim
```

### Ejercicio 3: qué entender antes de codificar

El contador binario alimenta el índice local; su versión Gray se usa para cruzar el dominio. Para valores consecutivos, comprobar que `gray_n ^ gray_(n−1)` tenga exactamente un bit alto. La diapositiva anuncia 16 valores y 15 verificaciones de transición; el caso `0111 → 1000` es especialmente útil para comparar binario y Gray.

### Ejercicio 4: qué entender antes de codificar

`ready` indica que el ACK sincronizado alcanzó el toggle del transmisor. Registrar `data_in` y alternar `toggle` en el **mismo evento aceptado**, `req && ready`. Después, mantener ambos hasta volver a `ready`. El testbench espera cuatro datos en orden. El receptor y la sincronización de ACK vienen provistos según la diapositiva.

### Ejercicio 5: qué responder en el análisis

1. **Cantidad de FF:** contar los FF de la cadena y los demás FF de captura en el reporte de síntesis; comparar con el RTL y con el chequeo de la práctica (`al menos 4 FF`, según la diapositiva). No asumir un número final sin ejecutar la síntesis.
2. **Sin `DONT_TOUCH`:** probar y comparar el netlist/reporte; el resultado depende de la herramienta y del RTL. Lo relevante es confirmar que siguen existiendo las dos etapas de sincronización.
3. **False path:** exceptuar el cruce asíncrono desde `clkA` a la **primera** etapa `sync1` de `clkB`. La ruta `sync1 → sync2` debe seguir bajo análisis de timing para reservar tiempo de resolución.
4. **Fmax:** leerla del reporte de OpenSTA/OpenLane para la implementación y corner ejecutados. No se deduce del esquema del sincronizador; indicar clock y corner al citarla.

La diapositiva propone `./run.sh synth`, `./run.sh openlane` y `make check_sync`. Su ruta `NIX_FLAKE=/home/mdelbarco/openlane2` es específica del entorno del docente y puede requerir adaptación.

## 9. Repaso rápido antes de empezar

- ¿Puedo distinguir setup de hold y calcular slack de setup a partir de arrival y required?
- ¿Reconozco I2O, I2R, R2R y R2O en un esquema?
- ¿Sé qué modelan `create_clock`, input/output delay y clock uncertainty?
- ¿Puedo explicar por qué pipeline mejora Fmax, pero añade latencia?
- ¿Sé por qué un doble FF sirve para un nivel de un bit y falla para un bus o un pulso corto?
- ¿Puedo elegir entre `valid` con bus estable, toggle con ACK y FIFO según el tráfico?
- ¿Sé comprobar la propiedad Gray y por qué los punteros de FIFO usan un bit adicional?
- ¿Puedo explicar la liberación síncrona del reset y qué revisan STA, CDC y RDC?

Si estas respuestas salen sin consultar las diapositivas, están cubiertos los conceptos necesarios para abordar los cinco ejercicios.
