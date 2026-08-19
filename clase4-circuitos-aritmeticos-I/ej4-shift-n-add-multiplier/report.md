# Ejercicio 4 — Multiplicador Shift-and-Add secuencial

## Motivación

El objetivo es implementar un multiplicador unsigned 8×8 → 16 bits que reutiliza un único sumador de 8
bits a lo largo de 8 ciclos de reloj, en vez de instanciar hardware combinacional proporcional a N². Es el
primer punto de referencia de la serie ej4/ej5/ej6: sirve para comparar, más adelante, latencia y área
contra un multiplicador combinacional en matriz (ej5) y contra Booth radix-2 (ej6).

## Implementación

Dos módulos, separados según pide la consigna:

- **`control_fsm.sv`**: FSM de 3 estados (`IDLE → COMPUTE → DONE → IDLE`) con reset asíncrono. Cuenta los
  ciclos de `COMPUTE` y expone pulsos `load` (un ciclo, al aceptar `start`) y `shift_add` (activo durante
  los 8 ciclos de cómputo), además de `done`/`busy`.
- **`mul_seq.sv`**: datapath. Un único registro `acc` de 16 bits contiene en todo momento, en su mitad
  alta, la suma parcial, y en su mitad baja, los bits de `b` aún no consumidos. Cada ciclo:

  ```
  suma[8:0] = {1'b0, acc[15:8]} + (acc[0] ? {1'b0, a_reg} : 0)
  acc      <= {suma[8:0], acc[7:1]}
  ```

  Esa única concatenación hace a la vez la suma condicional (si el bit de `b` que sale por `acc[0]` es 1)
  y el shift a la derecha del acumulador completo — no hay un paso de shift separado, como pide el tip del
  enunciado. El sumador de 9 bits (8 bits + carry) es el único adder del diseño y se reusa en los 8 ciclos.

Al cabo de 8 ciclos, `acc[15:0]` es el producto final; no hace falta ningún ajuste posterior.

## Resultados

Testbench (`tb_mul_seq.sv`) con golden model embebido (`esperado = a*b` en SystemVerilog): 4 casos límite
(`0*0`, `255*255`, `0*255`, `1*1`) más 5 verificaciones dirigidas y 200 pares pseudoaleatorios (semilla
fija vía `$random(seed)`, reproducible entre corridas), 205 operaciones verificadas en total.

```
==========================================================
 Ejercicio 4 - Multiplicador shift-and-add secuencial (N=8)
==========================================================
  0 * 0 = 0        (8 ciclos, esperado 8)
  255 * 255 = 65025 (8 ciclos, esperado 8)
  0 * 255 = 0       (8 ciclos, esperado 8)
  1 * 1 = 1         (8 ciclos, esperado 8)

--- 200 pares pseudoaleatorios (semilla fija) ---
  pares verificados: 205

 RESULTADO: OK - sin discrepancias
 LATENCIA: OK - 8 ciclos constantes en las 205 operaciones
==========================================================
```

Sin discrepancias contra el golden model, y latencia constante de 8 ciclos en las 205 operaciones (una por
`start`, incluyendo el ciclo de carga).

### Área vs throughput (parcial — ej4 en aislado)

Costo de hardware: 1 sumador de 9 bits, 1 registro de 16 bits (`acc`) + 1 de 8 bits (`a_reg`), FSM de 3
estados con contador de $\lceil\log_2 8\rceil+1 = 4$ bits. Costo aproximadamente constante en N (no crece
con N² como una matriz combinacional), a cambio de N ciclos de latencia por operación — throughput de 1
resultado cada 8 ciclos (sin pipelining), frente a 1 resultado por ciclo que podría dar una versión
combinacional o pipelineada.

La comparación cuantitativa contra el multiplicador combinacional (ej5) está en
`../ej5-array-multiplier/report.md`: cambia los 8 ciclos de latencia de este ejercicio por ~15 retardos de
compuerta en un solo paso combinacional, a costa de pasar de un sumador reusado a 64 celdas de 1 bit. La
comparación contra Booth radix-2 (ej6, `../ej6-booth-radix2-wallace-dadda/report.md`) muestra que, en forma
combinacional, Booth radix-2 no reduce la cantidad de sumandos frente a este ejercicio ni frente a ej5 (las
tres arquitecturas manejan 8 PPs/sumas) — su ventaja real está en saltar ciclos en una versión secuencial
con corridas largas de bits iguales, algo que este ejercicio no explota (ciclo fijo de 8 siempre).
