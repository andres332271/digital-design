# Modulo 9 — Ejercicio 2: Enable Synchronization

Estos archivos son una **reconstruccion para practicar** basada en la diapositiva 71 de `Modulo_9.pptx`; no son los archivos originales del curso. `enable_sync.v` ya contiene la solucion completa.

## Consigna

Transferir una palabra desde `clkA` (125 MHz) hacia `clkB` (38 MHz):

- Guardar el dato en `data_hold` en el dominio `clkA`.
- Sincronizar **solo `valid_in`** mediante `vs1` y `vs2`, ambos con `clkB`.
- Detectar el flanco ascendente de `vs2`, copiar `data_hold` a `data_out` y producir un pulso de un ciclo en `data_valid`.

El testbench mantiene `data_in` y `valid_in` el tiempo suficiente y separa las transferencias para que el receptor las vea. El modulo no incluye confirmacion (`ACK`) hacia el emisor, por lo que no garantiza por si solo transferencias arbitrariamente rapidas.

## Archivos

- `enable_sync.v`: implementacion completa.
- `tb_enable_sync.v`: testbench autocorrector de 200 transferencias.
- `bad_bus_sync.v`: ejemplo conceptual incorrecto, para comparar.
- `tb_bad_bus_sync.v`: demuestra con skew que el ejemplo incorrecto puede entregar un valor intermedio.
- `run.sh`: compila y ejecuta ambas simulaciones con Icarus Verilog.
- `Resultados_Ejercicio_2.md`: resultados y limites de las simulaciones.

## Como probar

Con `iverilog` y `vvp` instalados:

```sh
./run.sh
```

La primera simulacion debe terminar con `PASS 200/200`. Comprueba el valor, el orden y que `data_valid` dure un ciclo. La segunda demuestra que `bad_bus_sync` puede entregar `0x1F` durante una transicion `0x00` a `0xFF` con skew entre bits.

**Nota:** la diapositiva muestra `data_valid <= vs2` en un fragmento ilustrativo, pero tambien pide un pulso de un ciclo. Esta plantilla sigue el requisito del pulso y usa `vs2_anterior` para detectar el flanco. No se incluye el modelo estadistico de metaestabilidad `TAU_DEMO` mencionado en la diapositiva; este paquete se centra en el protocolo y la comprobacion funcional.
