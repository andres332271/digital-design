# Módulo 9 — Ejercicio 2: transferencia de un bus entre relojes

## Objetivo

Implementar `enable_sync` para transferir una palabra desde el dominio `clkA` al dominio `clkB`. La idea es **mantener el bus de datos estable** y sincronizar únicamente la señal de un bit que indica que el dato es válido.

## Qué debe hacer el circuito

1. En `clkA`, guardar el dato de entrada en `data_hold` cuando comienza una transferencia.
2. Mantener `data_hold` sin cambios hasta que el receptor pueda capturarlo.
3. Pasar la señal `valid` por **dos flip-flops** que usan `clkB` (`vs1` y `vs2`).
4. En `clkB`, detectar cuándo `vs2` pasa de `0` a `1` y capturar `data_hold` una sola vez.
5. Generar `data_valid` como un **pulso de un ciclo de `clkB`** por cada dato recibido.

```text
Dominio clkA                           Dominio clkB

data_in → data_hold ──────────────────→ registro de salida
              valid ─────→ vs1 → vs2 ─→ detectar flanco → data_valid
```

![Esquema de sincronización de valid con el bus estable](Resumen_Modulo_9_assets/enable_sync.png)

## Por qué se hace así

Si se sincronizara cada bit del bus por separado, algunos bits podrían llegar antes que otros y el receptor podría formar una palabra que el emisor nunca envió. Al sincronizar `valid` y mantener el bus estable, el receptor espera a recibir el aviso antes de tomar la palabra completa.

Para que `data_valid` dure un solo ciclo, hay que detectar el **flanco** de `vs2`, por ejemplo con `vs2 && !vs2_d`, donde `vs2_d` guarda el valor anterior de `vs2`. Usar directamente `data_valid = vs2` dejaría la salida activa mientras `vs2` permanezca en `1`.

Esta técnica requiere que `valid` dure lo suficiente para que `clkB` lo detecte y que el emisor no sobrescriba `data_hold` antes de la captura. Si el emisor necesita mandar otra palabra sin esperar, hace falta un *handshake* o una FIFO.

## Verificación esperada

- `clkA = 125 MHz` y `clkB = 38 MHz`.
- El bus recibido coincide con el enviado en los 200 casos del testbench.
- `data_valid` aparece una sola vez por transferencia y dura un ciclo de `clkB`.
- La versión incorrecta `bad_bus_sync` ilustra el riesgo de mezclar bits viejos y nuevos.
- Resultado esperado del testbench: `PASS 200/200`.

Si se dispone de `enable_sync.v` y `tb_enable_sync.v`, ejecutar:

```bash
iverilog -g2012 -o sim enable_sync.v tb_enable_sync.v && vvp sim
```

**Nota:** el resumen del módulo describe el ejercicio, pero los archivos Verilog y el testbench no están incluidos en esta carpeta.
