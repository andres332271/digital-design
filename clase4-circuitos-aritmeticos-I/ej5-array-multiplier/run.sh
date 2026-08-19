#!/bin/bash
# run.sh — compila y simula con Icarus Verilog (golden model embebido en el testbench)
set -euo pipefail
cd "$(dirname "$0")"

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out tb_array_mul.sv array_mul.sv full_adder.sv half_adder.sv

echo ">>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: tb_array_mul.vcd (abrir con: gtkwave tb_array_mul.vcd)"
