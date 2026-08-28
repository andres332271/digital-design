# Ejercicios finales — Módulo 5

Material de práctica de **CORDIC, Newton-Raphson y compromisos PPA**. Los enunciados provienen de las diapositivas finales del módulo; las notas de implementación se agregan para orientar el trabajo sin reemplazar el desarrollo.

## Convenciones comunes

- `S(W,F)`: número con signo de `W` bits totales y `F` bits fraccionarios.
- `U(W,F)`: número sin signo de `W` bits totales y `F` bits fraccionarios.
- Los ángulos de CORDIC están en radianes y deben usar la misma escala fija que `z`.
- `N_ITER`: cantidad de micro-rotaciones/iteraciones.
- Ver el archivo [Resumen_Modulo_5.md](Resumen_Modulo_5.md) para ecuaciones, LUT de ángulos, `K`, formatos y arquitectura.

---

## Ejercicio 1 — CORDIC iterativo en Verilog

### Enunciado

Implementar un CORDIC modo **rotación folded** en Verilog para calcular `sen(theta)` y `cos(theta)`.

Debe operar en punto fijo `S(16,14)` y completar 14 iteraciones en 14 ciclos.

### Datos

```text
NB     = 16
NBF    = 14
Formato = S(16,14)
N_ITER = 14
K^-1   ≈ 0.60725  -> x0 = K^-1 en S(16,14)
```

El rango angular de la rotación CORDIC básica es aproximadamente `|theta| <= 99.88°`. Si se pretende soportar otro rango, se debe hacer una reducción/pre-rotación antes de las iteraciones.

### Entregables

- [ ] RTL del datapath folded.
- [ ] ROM de 14 entradas con `atan(2^-i)` en `S(16,14)`.
- [ ] FSM de control: `idle`, `iter`, `done`.
- [ ] Testbench con `theta = pi/6`, `pi/4` y `pi/3`.

### Guía técnica

Inicialización:

```text
x = 1/K
y = 0
z = theta
```

En cada ciclo de iteración:

```text
d      = signo(z)
x_next = x - d · (y >>> i)
y_next = y + d · (x >>> i)
z_next = z - d · atan_lut[i]
```

Al completar `i = 0...13`:

```text
cos(theta) ≈ x
sen(theta) ≈ y
```

Valores de estímulo aproximados en `S(16,14)`:

| Ángulo | Valor real [rad] | Valor fijo aproximado |
|---|---:|---:|
| `pi/6` | 0.523599 | 8579 |
| `pi/4` | 0.785398 | 12868 |
| `pi/3` | 1.047198 | 17157 |

Puntos a verificar en simulación:

- `done` se activa una única vez, después de 14 iteraciones.
- El resultado no está escalado por `K`, porque se inicializó `x0 = 1/K`.
- `x_next`, `y_next` y `z_next` se calculan a partir de los registros viejos.
- Los shifts de valores negativos son aritméticos.

---

## Ejercicio 2 — Comparar CORDIC folded vs pipeline

### Enunciado

Tomar el CORDIC del ejercicio 1 y construir una versión **pipeline (unfolded)**. Comparar área, frecuencia y latencia entre ambas implementaciones con una herramienta de síntesis, por ejemplo Vivado, Yosys o similar.

### Datos

```text
Formato: S(16,14)
N = 14 iteraciones
Tecnología: FPGA Artix-7 o ASIC 45/130 nm
Constraint inicial: 100 MHz
```

### Entregables

- [ ] RTL del pipeline de 14 etapas.
- [ ] Tabla comparativa de área, frecuencia y latencia.
- [ ] Cálculo de throughput en muestras/segundo.
- [ ] Conclusión: cuándo usar cada arquitectura.

### Guía técnica

En el pipeline, cada etapa implementa una iteración fija `i`; por tanto, el shift y el valor de `atan(2^-i)` son constantes de esa etapa. Se registra la salida de cada etapa y se propagan señales de validez/identificación junto con `x`, `y` y `z`.

Plantilla para el informe:

| Métrica | Folded | Pipeline de 14 etapas |
|---|---:|---:|
| Datapaths CORDIC físicos | 1 | 14 |
| Latencia ideal | 14 ciclos | 14 ciclos |
| Throughput ideal | 1 muestra / 14 ciclos | 1 muestra / ciclo |
| Throughput a 100 MHz | 7.14 M muestras/s | 100 M muestras/s |
| Área esperada | menor | mayor (aprox. proporcional a 14 etapas) |
| Uso recomendado | datos esporádicos | streaming continuo |

Qué reportar desde la síntesis:

- FPGA: LUTs, FFs, DSPs usados (si los hubiera), `Fmax` y slack.
- ASIC: área en `um²`, potencia si está disponible, frecuencia/tiempo crítico.
- Aclarar si el throughput se calcula con la frecuencia objetivo (100 MHz) o con el `Fmax` obtenido.

No confundir conceptos: el pipeline tiene 14 ciclos de latencia para la primera salida, pero una vez lleno puede aceptar y producir una muestra por ciclo.

---

## Ejercicio 3 — CORDIC vectoring para magnitud y fase

### Enunciado

Implementar CORDIC modo **vectoring** para calcular:

```text
R = sqrt(x^2 + y^2)
phi = atan(y/x)
```

Comparar con una implementación directa que use un multiplicador y una ROM grande.

### Datos

```text
Entrada: x, y en S(16,15)
Salida:  R en S(16,15)
          phi en S(16,14)
N_ITER = 16
Vectores de test: cuadrantes I, II, III y IV
```

### Entregables

- [ ] RTL de CORDIC vectoring.
- [ ] Implementación de referencia con multiplicador.
- [ ] Comparación de área y precisión.
- [ ] Error versus cuadrante.

### Guía técnica

Inicialización y ecuaciones:

```text
x0 = x
y0 = y
z0 = 0

d      = -signo(y)
x_next = x - d · (y >>> i)
y_next = y + d · (x >>> i)
z_next = z - d · atan_lut[i]
```

Al final:

```text
yN ≈ 0
xN ≈ K · R
zN ≈ phi
```

Por lo tanto, si se requiere `R` sin escala, hay que compensar la ganancia:

```text
R ≈ xN · (1/K)
```

#### Cuadrantes

La corrección de cuadrante es esencial. La consigna sugiere pre-rotar 180° si `x < 0` para mantener el ángulo dentro del rango de convergencia.

Ejemplos de vectores para el testbench:

| Cuadrante | Vector sugerido | Fase esperada |
|---|---|---:|
| I | `(0.5, 0.5)` | `+pi/4` |
| II | `(-0.5, 0.5)` | `+3pi/4` |
| III | `(-0.5, -0.5)` | `-3pi/4` o equivalente |
| IV | `(0.5, -0.5)` | `-pi/4` |

Para la implementación de referencia, usá un modelo que calcule `x² + y²`, la raíz y `atan2(y,x)`. `atan2` (no sólo `atan(y/x)`) es necesario para distinguir correctamente los cuatro cuadrantes.

Métricas de error recomendadas:

```text
error_R   = |R_rtl - R_ref|
error_phi = |wrap_a_pi(phi_rtl - phi_ref)|
```

---

## Ejercicio 4 — Newton-Raphson para `1/x`

### Enunciado

Implementar un divisor por Newton-Raphson que calcule:

```text
y = 1/a
```

con 16 bits de precisión. Usar una LUT chica de 8 entradas para `y0` y completar la convergencia con 3–4 iteraciones de NR.

### Datos

```text
a normalizado a [0.5, 1.0)
Formato: U(16,16) para la LUT inicial, según la consigna
LUT inicial: 8 índices
Multiplicador: 16 × 16 -> 32 bits
```

### Entregables

- [ ] Generador de LUT en Python.
- [ ] RTL del datapath NR folded.
- [ ] FSM con `done` después de `N` iteraciones.
- [ ] Análisis de error en función de `N`.

### Guía técnica

La recurrencia es:

```text
y_next = y · (2 - a · y)
```

Operaciones de cada iteración:

```text
p      = a · y
e      = 2 - p
y_next = y · e
```

Arquitectura folded mínima:

- registros para `a` e `y`;
- uno o dos multiplicadores, según se reutilicen en uno o dos ciclos;
- restador;
- contador de iteraciones;
- FSM, por ejemplo `IDLE -> LOAD_SEED -> ITER -> DONE`.

#### LUT inicial de 8 entradas

Dividí el intervalo `[0.5, 1)` en 8 subintervalos. Para cada intervalo, una semilla simple es el inverso del punto medio:

```text
lim_inf = 0.5 + indice / 16
lim_sup = 0.5 + (indice + 1) / 16
medio   = (lim_inf + lim_sup) / 2
y0     = 1 / medio
```

El script generador debe convertir `y0` a la escala de punto fijo elegida y emitir constantes que el RTL pueda usar. Documentá explícitamente la convención de formato, porque la expresión `U(16,16)` de la diapositiva debe interpretarse junto con el ancho real del registro.

#### Escalado de productos

Un producto `16×16` genera 32 bits. Si ambos operandos están en Q16, el producto tiene 32 bits fraccionarios. Antes de reutilizarlo como operando Q16, se debe reescalar con un shift de 16 bits y definir redondeo/truncamiento y saturación.

#### Normalización y corrección final

La LUT está diseñada para `a` en `[0.5,1)`. Para entradas generales:

```text
a = m · 2^e, con m en [0.5,1)
1/a = (1/m) · 2^(-e)
```

Normalizá para obtener `m`, aplicá NR sobre `m` y al final compensá con el exponente `-e`.

#### Análisis de error

Compará contra `1.0/a` de un modelo de referencia. Una tabla mínima:

| Iteraciones | Error absoluto máximo | Error relativo máximo | Observación |
|---:|---:|---:|---|
| 0 |  |  | sólo semilla LUT |
| 1 |  |  |  |
| 2 |  |  |  |
| 3 |  |  | objetivo probable de 16 bits |
| 4 |  |  | verificar si compensa el costo |

La convergencia debe ser aproximadamente cuadrática cuando la semilla y la normalización son correctas. Si el error crece o no baja, revisá primero: rango de `a`, escala tras cada multiplicación y dirección de los shifts.

---

## Lista de control para los cuatro ejercicios

- [ ] Todos los valores de punto fijo tienen ancho, signo y cantidad de bits fraccionarios documentados.
- [ ] Las constantes de CORDIC y los ángulos de prueba están codificados en la escala correcta.
- [ ] La condición de finalización cuenta exactamente `N_ITER` iteraciones.
- [ ] El testbench usa tolerancias de error razonables, no igualdad exacta de punto fijo contra números reales.
- [ ] Los casos negativos y los cuatro cuadrantes están cubiertos cuando corresponda.
- [ ] El reporte PPA separa área, `Fmax`, latencia y throughput.
