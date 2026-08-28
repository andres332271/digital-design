# Ejercicio 2 — Comparación CORDIC folded vs. pipeline

## Implementación y verificación

Se comparan dos CORDIC circulares en modo rotación, con formato `S(16,14)` y 14 micro-rotaciones:

- **Folded:** reutiliza un datapath durante 14 ciclos.
- **Pipeline:** instancia 14 etapas `cordic_stage`; cada una contiene una micro-rotación y un registro.

El testbench `tb_cordic_pipeline.sv` inyecta `pi/6`, `pi/4` y `pi/3` en tres ciclos consecutivos. Verifica el valor exacto del modelo fijo de referencia, la validez consecutiva de las salidas y una latencia de 14 ciclos.

Resultado de simulación (`./run.sh`): **PASS**.

| Entrada | cos fijo | sen fijo | residual `z` |
|---|---:|---:|---:|
| `pi/6` | 14191 | 8189 | 1 |
| `pi/4` | 11586 | 11585 | 0 |
| `pi/3` | 8189 | 14191 | -1 |

## Síntesis

Se ejecutó Yosys 0.52 con `synth_xilinx -family xc7`, un mapeo lógico a primitivas de la familia Xilinx 7-series. No se usaron DSP: las micro-rotaciones sólo contienen sumas/restas y desplazamientos constantes.

| Recurso XC7 | Folded | Pipeline | Relación pipeline/folded |
|---|---:|---:|---:|
| LUT1–LUT6 | 269 | 932 | 3.46× |
| FF (`FDRE`) | 103 | 704 | 6.83× |
| `CARRY4` | 26 | 282 | 10.85× |
| DSP | 0 | 0 | — |

Los números son de Yosys y sirven para comparar arquitecturas. Incluyen buffers y puertos del top, por lo que no equivalen a una utilización final de un FPGA particular. Los logs reproducibles son `yosys_folded.log` y `yosys_pipeline.log`.

## Latencia y throughput

| Métrica | Folded | Pipeline de 14 etapas |
|---|---:|---:|
| Datapaths físicos | 1 | 14 |
| Latencia | 14 ciclos de iteración | 14 ciclos |
| Inicio de nuevas muestras | una cada 14 ciclos | una por ciclo |
| Throughput a 100 MHz | 7.14 M muestras/s | 100 M muestras/s |

El throughput se calcula como `f_clk / 14` para folded y `f_clk` para pipeline. La primera salida del pipeline aparece después de 14 ciclos; luego aparece una salida válida por cada ciclo de entrada válida.

## Frecuencia

La constraint de referencia es **100 MHz** (período de 10 ns). Yosys sin place-and-route no calcula slack ni `Fmax`, así que no se reporta un valor inventado. Para cerrar esta métrica en una Artix-7 se debe ejecutar Vivado (síntesis + implementación) con un XDC de 10 ns y tomar `WNS`/`Fmax` del reporte de timing. El pipeline debería tener un camino combinacional más corto por etapa que el folded, aunque su uso de área es mayor.

## Conclusión

La versión **folded** conviene para señales esporádicas o recursos limitados: reduce de forma marcada LUTs, FFs y lógica de acarreo, a cambio de aceptar una muestra cada 14 ciclos. La versión **pipeline** conviene en streaming: mantiene la misma latencia inicial, pero entrega hasta 14 veces más muestras por segundo a igual reloj. Su costo es replicar el datapath y sus registros en las 14 etapas.

## Reproducción

Desde `Modulo 5/EJ2`:

```sh
./run.sh
```

El comando compila el testbench y genera los logs de síntesis. Se requiere `iverilog`, `vvp` y `yosys`.
