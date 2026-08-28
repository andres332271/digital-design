# Ejercicio 3 — CORDIC vectoring: magnitud y fase

## Formatos

| Señal | Formato | Motivo |
|---|---|---|
| `x_in`, `y_in`, `r` | `S(16,15)` | Entrada y magnitud de la consigna. |
| Registros internos `x`, `y` | `S(18,15)` | Dos bits de guarda para la ganancia CORDIC. |
| `phi` | `S(18,14)` | `S(16,14)` sólo llega aproximadamente a ±2 rad; no representa ±π. |

La salida de magnitud compensa la ganancia CORDIC con `K^-1 = 0.607252935`. La lógica pre-rota 180° cuando `x < 0`, por lo que se conservan los cuatro cuadrantes antes de las 16 iteraciones.

## Modelo dorado y testbench

`golden_vectoring.py` usa la librería `fxpmath`, ya empleada en módulos anteriores, para cuantizar entradas y la referencia matemática directa:

```text
R   = hypot(x, y)
phi = atan2(y, x)
```

El script genera `cordic_vectoring_expected.svh`, que `tb_cordic_vectoring.sv` incluye durante la compilación. El testbench compara contra esa referencia con tolerancia de 8 LSB y también confirma que se ejecutan exactamente 16 ciclos.

Resultado de `./run.sh`: **PASS**.

| Caso | Error `R` | Error `phi` |
|---|---:|---:|
| Cuadrante I `(0.5, 0.5)` | 1 LSB | 1 LSB |
| Cuadrante II `(-0.5, 0.5)` | 1 LSB | 1 LSB |
| Cuadrante III `(-0.5, -0.5)` | 1 LSB | 1 LSB |
| Cuadrante IV `(0.5, -0.5)` | 1 LSB | 1 LSB |
| Eje X `(0.75, 0)` | 2 LSB | 1 LSB |
| Eje Y `(0, -0.75)` | 2 LSB | 1 LSB |

El residual `y` final fue 0 o -1 LSB en todos los casos, coherente con el objetivo del modo vectoring (`yN -> 0`).

## Área CORDIC

Mapeo lógico ejecutado con Yosys 0.52 y `synth_xilinx -family xc7`:

| Recurso XC7 | Resultado |
|---|---:|
| LUT1–LUT6 | 394 |
| FF (`FDRE`) | 113 |
| `CARRY4` | 46 |
| DSP48E1 | 1 |

El DSP aparece por el producto final de compensación `xN * K^-1`. La implementación iterativa reutiliza este único datapath durante 16 ciclos.

## Comparación con referencia directa

La referencia funcional está implementada en Python, con `hypot` y `atan2`; así se evita usar `atan(y/x)`, que pierde la información de cuadrante. Una implementación RTL directa equivalente requeriría al menos multiplicadores para `x²+y²`, un bloque de raíz cuadrada y una ROM/operación para `atan2`, además de corrección de cuadrante. Por eso se espera mayor área y menor reutilización que el CORDIC folded.

No se reporta un conteo numérico de esa alternativa porque la consigna no fija el tamaño ni la interpolación de la ROM ni la arquitectura de `sqrt`; comparar contra una versión no definida daría un resultado arbitrario. El conteo CORDIC es reproducible en `yosys_vectoring_xc7.log`.

## Ejecución

```sh
cd "Modulo 5/EJ3"
./run.sh
```

Requiere `fxpmath`, `iverilog`, `vvp` y `yosys`.
