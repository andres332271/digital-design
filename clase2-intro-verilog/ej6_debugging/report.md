# Informe Ejercicio 6 - Debugging

## Motivación

El módulo definido en `alu_bad.v` tiene un bug silencioso: no se define explícitamente la operación que realiza si op = `2'b11`. El objetivo de este ejercicio es identificar el efecto que tiene esto en una síntesis (un latch implícito) y proponer 2 soluciones.

## Implementación del *Test Bench*

El test consiste en asignar valores fijos a los vectores de entrada `a` y `b`, y probar las 12 transiciones de `op`. Los resultados se logean a un archivo .csv. El resultado esperable es que el valor de `y` solo dependa del valor actual de `op`, independientemente del valor anterior. Si hay un latch esto no ocurre.

## Fix

El error en `alu_bad.v` es no definir explícitamente la operación para op = `2b11`. Esto se solucionó asignando el valor 0 al resultado de la operación. En fix1 se usó un caso `default`, mientras que en `fix2` se utilizó `unique case (op)`, junto con el caso explícito `2'b11`.

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

Alternativamente, utilizando el script de yosys nos arroja un error (ver última línea de output).

```
$ yosys check_latch.ys

 /----------------------------------------------------------------------------\
 |  yosys -- Yosys Open SYnthesis Suite                                       |
 |  Copyright (C) 2012 - 2026  Claire Xenia Wolf <claire@yosyshq.com>         |
 |  Distributed under an ISC-like license, type "license" to see terms        |
 \----------------------------------------------------------------------------/
 Yosys 0.66 (git sha1 86f2ddebc-dirty, g++ 16.1.1 -march=x86-64 -mtune=generic -O2 -fno-plt -fexceptions -fstack-clash-protection -fcf-protection -fno-omit-frame-pointer -mno-omit-leaf-frame-
pointer -ffile-prefix-map=/build/yosys/src=/usr/src/debug/yosys -fPIC -O3) [startdir/yosys at makepkg]

-- Executing script file `check_latch.ys' --

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
