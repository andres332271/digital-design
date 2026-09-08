# Clase 6 — Planificación temporal

## Introducción

Esta clase es teórica (`ref/notas-de-clase.md`: *"la estrategia de implementación es libre a
criterio propio"*), a diferencia de las anteriores del curso — el objeto de estudio no es un
módulo RTL aislado sino las decisiones de **cuándo** ejecuta cada operación un algoritmo ya
definido, y cómo esas decisiones (no la aritmética en sí) determinan latencia, throughput, área
y consumo de un mismo cálculo.

Los seis ejercicios comparten un único caso de estudio para que las comparaciones tengan
sentido entre sí: un **FIR de 4 coeficientes en forma directa**
(`y[n] = h0·x[n] + h1·x[n-1] + h2·x[n-2] + h3·x[n-3]`), con dos latencias de referencia fijadas
desde el ej1 y reusadas en todo lo demás: `t_mul = 2 tu`, `t_add = 1 tu`. El ej6 lo convierte a
un IIR de 1er orden para poder hablar de lazos de realimentación, algo que un FIR (puramente
feed-forward) no tiene.

El hilo conductor, ejercicio a ejercicio:

| Ejercicio | Qué agrega | Informe |
|---|---|---|
| 1 | Construye el DFG del FIR y fija el camino crítico (4 tu, árbol de sumas) | [ej1_dfg_fir4.md](ej1_dfg_fir4.md) |
| 2 | ASAP/ALAP sobre ese DFG — resulta en movilidad 0 en los 7 nodos | [ej2_asap_alap.md](ej2_asap_alap.md) |
| 3 | Versión iterativa real (RTL): 1 mult + 1 add compartidos, FSM, medida con testbench | [ej3_iterativo.md](ej3_iterativo.md) |
| 4 | Versión pipeline real (RTL): cut-set + retiming, medida y sintetizada | [ej4_pipeline.md](ej4_pipeline.md) |
| 5 | Comparación PPA de ej3 vs. ej4 con datos medidos/sintetizados, no estimados | [ej5_ppa.md](ej5_ppa.md) |
| 6 | Conversión a IIR, cálculo del IPB, y qué hace falta para bajarlo | [ej6_ipb.md](ej6_ipb.md) |

A diferencia de clases anteriores del curso, acá **sí conviene bajar a RTL real** en ej3 y ej4
(y sintetizarlos con Yosys en ej5) aunque el enunciado no lo pida explícitamente: son los únicos
dos puntos donde una arquitectura concreta se puede verificar y medir en vez de solo estimarse a
mano — el resto (ej1, ej2, ej6) son documentos de diseño puro, sin nada que sintetizar.

Cada informe cierra con dos secciones de verificación: una de recomputación independiente
(scripts que rehacen las cuentas, testbenches cruzados ej3-vs-ej4) y una de **contraste con
fuentes externas** (el libro de texto de la materia — Parhi — y otras referencias, no solo
`ref/Modulo_6.pptx`). Son la razón por la que los números de estos seis documentos se pueden
dar por confiables y no solo "razonados".

## Conclusiones

**1. La planificación es arquitectura, no matemática.** Los seis ejercicios calculan
exactamente el mismo filtro (ej3, ej4, y la versión ASAP ideal de ej1/ej2 son, algebraicamente,
la misma función de transferencia — confirmado en ej4 con un testbench cruzado, no solo
argumentado). Lo único que cambia es *cuándo* y *con qué hardware* se ejecuta cada operación, y
eso alcanza para mover la latencia entre 3 y 12 tu, el throughput en un factor ~7.5×, y el área
sintetizada en un factor ~2× — sin tocar una sola constante del algoritmo.

**2. La topología del DFG decide cuánto margen hay para compartir hardware.** El árbol de sumas
balanceado que se eligió en ej1 (mejor camino crítico que la cadena) tiene como contrapartida
movilidad 0 en los 7 nodos (ej2): no hay ciclos ociosos que aprovechar. Eso se traduce
directamente en que la versión iterativa de ej3 necesita 4 ciclos, no los 3 del ASAP ideal — la
movilidad 0 no es una curiosidad de la tabla, es la prueba de que compartir hardware en *ese*
DFG tiene un costo de latencia insalvable.

**3. Folding y pipelining son la misma moneda, del lado opuesto.** ej3 (1 mult + 1 add
compartidos) y ej4 (4 mults en paralelo, 2 etapas) son los dos extremos del espacio de
soluciones: folding gana área (~2.4× menos LCs, y el multiplicador compartido es 1 solo
DSP48E1 en vez de 4) a costa de throughput y de necesitar una FSM de control; pipelining gana
throughput y fmax a costa de replicar hardware y no necesita más control que un `valid` viajando
con los datos. Ninguno es "mejor" en abstracto — la ganancia de throughput terminó siendo mayor,
proporcionalmente, que el costo de área, pero eso es una propiedad de *este* DFG y estos
recursos, no una ley general.

**4. Retiming no es gratis, tiene un límite formal.** El propio libro de la materia (Parhi,
*VLSI Digital Signal Processing Systems*, `ref/pahri-slides/`) lo dice explícito: retiming no
cambia la cantidad de registros en un ciclo. Eso es lo que permite en ej4 bajar de 3 a 2 etapas
de pipeline sin perder el fmax ya ganado (retiming *sí* sirve para redistribuir), y es también
la prueba formal de por qué en ej6 el IPB de un lazo con realimentación **no se puede bajar
solo con retiming** — hace falta cambiar el DFG (Shannon, C-Slow con streams reales, o
look-ahead).

**5. Un lazo de realimentación cambia las reglas del juego.** Todo lo feed-forward (ej1-ej5) se
puede pipelinear tanto como se quiera, cortando el camino crítico en más y más etapas sin límite
teórico. El IIR de ej6 introduce un piso duro (`IPB = 3 tu`) que ningún pipeline ni retiming
externo al lazo puede franquear — la única forma de bajarlo es rediseñar el propio DFG del lazo.
De las tres herramientas para eso, Shannon resultó no aplicar bien acá (no hay una entrada de
control natural sobre la que pivotear en una recursión aritmética pura), C-Slow resultó tener un
matiz importante que la primera versión de este informe no tenía bien (es válido con 1 solo
stream, pero solo *mejora* el throughput con varios streams reales), y look-ahead terminó siendo
la única que baja el IPB de un único canal sin trucos adicionales — y se pudo verificar
algebraicamente con aritmética exacta, no solo argumentar.

**6. Verificar en vez de asumir encontró errores reales, dos veces.** La revisión de este
módulo no fue una formalidad: ampliar la cobertura de un testbench de
ej4 encontró un bug real en el propio testbench (una muestra fantasma por un handshake mal
armado), y contrastar contra el libro de texto encontró un error real de redacción en la
sección de C-Slow de ej6 (no un matiz — una afirmación que decía "inválido sin streams" cuando
en realidad es "válido pero sin ganancia"). Ambos se corrigieron. Ninguno de los dos se habría
encontrado solo releyendo el markdown.
