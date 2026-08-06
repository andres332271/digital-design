#!/bin/bash
# run.sh — compila y simula con Icarus Verilog
set -euo pipefail
cd "$(dirname "$0")"

TOP=bcd_counter

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out tb_${TOP}.v ${TOP}.v

echo ">>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: tb_bcd_counter.vcd (abrir con: gtkwave tb_bcd_counter.vcd)"