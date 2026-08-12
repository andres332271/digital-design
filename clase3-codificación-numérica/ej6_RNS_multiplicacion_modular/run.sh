#!/bin/bash
# run.sh — compila y simula con Icarus Verilog
set -euo pipefail
cd "$(dirname "$0")"

TOP=RNS_multiplicacion_modular
EXT=sv

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out tb_${TOP}.${EXT} ${TOP}.${EXT}

echo ">>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: tb_${TOP}.vcd (abrir con: gtkwave tb_${TOP}.vcd)"