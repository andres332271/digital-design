#!/bin/bash
# run.sh — compila y simula con Icarus Verilog (golden model embebido en el testbench)
set -euo pipefail
cd "$(dirname "$0")"

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out tb_booth_r2.sv booth_r2.sv

echo ">>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: tb_booth_r2.vcd (abrir con: gtkwave tb_booth_r2.vcd)"
