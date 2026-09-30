# Resultados finales — Ejercicio 2: Enable Synchronization

**Fecha:** 30 de septiembre de 2026  
**Herramienta:** Icarus Verilog (`iverilog` y `vvp`)  
**Comando:** `./run.sh`

## Implementacion realizada

En `enable_sync.v`, `data_hold` registra `data_in` con `clkA` cuando `valid_in` esta activo. `valid_in` cruza al dominio `clkB` mediante `vs1` y `vs2`. El flanco ascendente de `vs2` hace que el receptor copie `data_hold` a `data_out` y active `data_valid` durante un ciclo de `clkB`.

El reset `rst_n` inicializa los registros a cero. El testbench mantiene el dato y el aviso estables durante la transferencia y deja tiempo entre transferencias para que el aviso vuelva a cero en el receptor.

## Simulaciones

| Prueba | Estimulo y comprobacion | Resultado |
| --- | --- | --- |
| `tb_enable_sync.v` | 200 palabras de 8 bits; `clkA = 125 MHz`, `clkB ≈ 38 MHz`; verifica valor, orden, un dato recibido por envio y pulso de `data_valid` de un ciclo | **PASS 200/200** |
| `tb_bad_bus_sync.v` | Transicion `0x00 → 0xFF` con distinto retardo por bit; comprueba el valor intermedio producido por el sincronizador incorrecto | **Se observo `0x1F`**, valor que no era ninguno de los extremos |

Salida principal de `./run.sh`:

```text
PASS 200/200
PASS demo: bad_bus_sync entrego 0x1f entre 0x00 y 0xFF
```

La segunda prueba pasa cuando **reproduce el problema esperado** en `bad_bus_sync`; ese modulo sigue siendo un ejemplo incorrecto.

## Alcance del resultado

La simulacion funcional comprueba el comportamiento bajo los estimulos del testbench. No modela la metaestabilidad fisica ni sustituye un analisis CDC. `tb_bad_bus_sync.v` introduce skew de manera determinista para mostrar como aparece una palabra intermedia.

Este `enable_sync` no devuelve un `ACK`: el emisor debe mantener el dato estable y espaciar las transferencias. Si necesita enviar sin esperar a que el receptor pueda tomar el dato, se requiere un handshake o una FIFO.

Los archivos de la practica son una reconstruccion basada en la diapositiva 71 de `Modulo_9.pptx`, no los archivos originales del curso. El modelo estadistico `TAU_DEMO` mencionado en la diapositiva no forma parte de esta reconstruccion.
