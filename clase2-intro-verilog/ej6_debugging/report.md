# Informe Ejercicio 6 - Debugging

## Motivación

El módulo definido en `alu_bad.v` tiene un bug silencioso: no se define explícitamente la operación que realiza si op = `2'b11`. El objetivo de este ejercicio es identificar el efecto que tiene esto en una síntesis (un latch implícito) y proponer 2 soluciones.

## Implementación del *Test Bench*

`tb_alu.v` tiene dos fases. Fase 1: valores fijos en `a` y `b`, probando las 12 transiciones de `op`. Los resultados se logean a un archivo .csv. El resultado esperable es que el valor de `y` solo dependa del valor actual de `op`, independientemente del valor anterior; si hay un latch esto no ocurre. Fase 2: barrido de los 256 valores posibles de `a` (8 bits) para cada uno de los 3 op-codes definidos (`00`,`01`,`10`), comparando `y_fix1` y `y_fix2` contra un resultado esperado calculado en el propio TB — esto verifica la equivalencia funcional de ambos fixes de forma automática (contador de errores + PASS/FAIL), en vez de depender solo de la inspección visual del CSV.

## Fix

El error en `alu_bad.v` es no definir explícitamente la operación para op = `2b11`. Se proponen dos fixes, ambos dejando `y=0` para ese caso:

- **fix1 — caso `default`**: se agrega una rama `default: y = 8'd0;` al `case`, cubriendo cualquier valor de `op` no listado explícitamente.
- **fix2 — pre-asignación**: se asigna `y = 8'sd0;` *antes* de entrar al `case`, que solo lista las 3 operaciones definidas. Como toda ejecución pasa primero por la pre-asignación, cualquier rama no cubierta por el `case` conserva ese valor por defecto en vez de "recordar" el valor anterior de `y`.

Ambas técnicas garantizan que `y` quede asignado en todo camino de ejecución, que es la regla de oro para evitar la inferencia de latch en `always_comb`.

## Resultados

A continuación, una copia del .csv de salida 

```
time,   op_from,  op_to,  y_bad,  y_fix1, y_fix2
20000,  01,       00,     19,     19,     19
40000,  10,       00,     19,     19,     19
60000,  11,       00,     19,     19,     19
80000,  00,       01,     11,     11,     11
100000, 10,       01,     11,     11,     11
120000, 11,       01,     11,     11,     11
140000, 00,       10,     4,      4,      4
160000, 01,       10,     4,      4,      4
180000, 11,       10,     4,      4,      4
200000, 00,       11,     19,     0,      0
220000, 01,       11,     11,     0,      0
240000, 10,       11,     4,      0,      0
```

Analizando esto notamos que los resultados son consistentes en grupos de 3 filas (mismo valor de `op_to`) para `y_fix1` y `y_fix2`, mientras que no lo son para `y_bad`, lo que evidencia el latch implícito.

La fase 2 del TB (barrido de los 256 valores de `a` para cada op definida) confirma esto de forma automática:

```
----------------------------------------
Barrido de 256 vectores completo. Errores: 0
RESULTADO: PASS
----------------------------------------
```

0 errores en 768 vectores (256 valores de `a` × 3 op-codes): `y_fix1` y `y_fix2` coinciden entre sí y con el valor esperado en todos los casos, confirmando que ambos fixes son funcionalmente equivalentes.

## Verificación con yosys

`check_latch.ys` corre `alu_fix1.v` y `alu_fix2.v` y usa `select -assert-none t:$dlatch t:$dlatchsr` sobre cada uno — el script termina sin error, confirmando que ninguno de los dos fixes infiere latch:

```
$ yosys check_latch.ys
...
3.8. Executing PROC_DLATCH pass (convert process syncs to latches).
No latch inferred for signal `\alu_fix1.\y' from process `\alu_fix1.$proc$alu_fix1.v:15$1'.
...
7.8. Executing PROC_DLATCH pass (convert process syncs to latches).
No latch inferred for signal `\alu_fix2.\y' from process `\alu_fix2.$proc$alu_fix2.v:16$10'.
...
End of script. Logfile hash: ...
```

`alu_bad.v` no se incluye en ese mismo script: en yosys, `PROC_DLATCH` levanta un `ERROR` (no un warning) apenas detecta un latch dentro de un bloque `always_comb`, y ese error aborta el resto del script — no se podría seguir hasta chequear fix1/fix2 en la misma corrida. Por eso la demostración del bug en `alu_bad.v` se corre por separado, apuntando el mismo pipeline (`read_verilog -sv`, `hierarchy`, `proc`, `opt`) a ese archivo:

```
$ yosys -p "read_verilog -sv alu_bad.v; hierarchy -check -top alu_bad; proc; opt"

 /----------------------------------------------------------------------------\
 |  yosys -- Yosys Open SYnthesis Suite                                       |
 |  Copyright (C) 2012 - 2026  Claire Xenia Wolf <claire@yosyshq.com>         |
 |  Distributed under an ISC-like license, type "license" to see terms        |
 \----------------------------------------------------------------------------/
 Yosys 0.66 (git sha1 86f2ddebc-dirty, g++ 16.1.1 -march=x86-64 -mtune=generic -O2 -fno-plt -fexceptions -fstack-clash-protection -fcf-protection -fno-omit-frame-pointer -mno-omit-leaf-frame-
pointer -ffile-prefix-map=/build/yosys/src=/usr/src/debug/yosys -fPIC -O3) [startdir/yosys at makepkg]

1. Executing Verilog-2005 frontend: alu_bad.v
Parsing SystemVerilog input from `alu_bad.v' to AST representation.
Generating RTLIL representation for module `\alu_bad'.
Successfully finished Verilog frontend.

2. Executing HIERARCHY pass (managing design hierarchy).

2.1. Analyzing design hierarchy..
Top module:  \alu_bad

2.2. Analyzing design hierarchy..
Top module:  \alu_bad
Removed 0 unused modules.

3. Executing PROC pass (convert processes to netlists).

3.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

3.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Marked 1 switch rules as full_case in process $proc$alu_bad.v:15$1 in module alu_bad.
Removed a total of 0 dead cases.

3.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 0 redundant assignments.
Promoted 1 assignment to connection.

3.4. Executing PROC_INIT pass (extract init attributes).

3.5. Executing PROC_ARST pass (detect async resets in processes).

3.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 0 switches.
<suppressed ~1 debug messages>

3.7. Executing PROC_MUX pass (convert decision trees to multiplexers).
Creating decoders for process `\alu_bad.$proc$alu_bad.v:15$1'.
     1/1: $1\y[7:0]

3.8. Executing PROC_DLATCH pass (convert process syncs to latches).
ERROR: Latch inferred for signal `\alu_bad.\y' from always_comb process `\alu_bad.$proc$alu_bad.v:15$1'.
```
