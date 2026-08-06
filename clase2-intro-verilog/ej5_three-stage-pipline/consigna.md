# Consigna Ej5

## Enunciado

Implementar un pipeline de 3 etapas que calcula:

$$y=((x+A)*B)>>4$$

Etapas del pipeline:

- 1: Suma $x+A$
- 2: Multiplica por $B$
- 3: Shift right aritmético 4 posiciones

La interfaz usa handshake AXI-Stream:

- Entrada: `x_in`, `valid_in`, `ready_out`
- Salida: `y_out`, `valid_out`, `ready_in`
- Cuando `ready_in` sea 0, el pipeline DEBE bloquear (stall).
- Cuando hay stall y `valid_in` sea 1, `ready_out` es 0.

## Datos

- `A` = `8'sd5`, `B` = `8'sd3` (constantes hardcoded)
- `x_in`: 8 bits signed
- `y_out`: 16 bits signed
- *Latencia*: 3 ciclos
- *Throughput*: 1 muestra/ciclo en régimen sin stalls

## Entregar

- `pipeline_3stage.v`
- `tb_pipeline` con golden model en software
- Probar con stall (ready_in alternando 1/0)
- Reportar throughput observado vs teórico
