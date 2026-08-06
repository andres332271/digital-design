# Informe Ejercicio 5 - Pipeline de 3 etapas

## Motivación

`pipeline_3stage.v` implementa $y=((x+A)\times B)>>4$ en 3 etapas (suma, producto, shift) con handshake AXI-Stream y soporte de stall vía `ready_in`. El objetivo es verificarlo contra un golden model en software, con y sin stalls, y reportar throughput.

## Implementación del *Test Bench*

`tb_pipeline.v` compara cada muestra contra un golden model combinacional (`sum = x+5; prod = sum*3; y = prod >>> 4`). Los valores esperados se encolan (FIFO) cuando hay handshake de entrada (`valid_in && ready_out`) y se verifican contra `y_out` cuando hay handshake de salida (`valid_out && ready_in`). El estímulo tiene 3 fases: régimen continuo sin stalls (50 muestras), régimen con `ready_in` alternando 1/0 (50 muestras), y drenaje del pipeline.

## Resultados

```
----------------------------------------
Muestras enviadas:  75
Muestras recibidas: 75
Errores:            0
Throughput observado: 75 datos / 111 ciclos = 0.676
Throughput teorico (sin stall): 1.0 dato/ciclo
RESULTADO: PASS
----------------------------------------
```

0 errores, 75/75 muestras correctas. El throughput observado (0.676) combina las 3 fases: 1.0 dato/ciclo en régimen continuo (fase 1, coincide con el teórico), ~0.5 dato/ciclo con `ready_in` alternando (fase 2, ya que la mitad de los ciclos son stall), y ciclos de drenaje sin nuevas entradas (fase 3). El resultado confirma que el pipeline respeta el handshake y no pierde ni corrompe muestras bajo stall.
