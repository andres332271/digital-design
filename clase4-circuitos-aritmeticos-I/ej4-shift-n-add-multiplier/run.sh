#!/bin/bash
# run.sh — compila y simula con Icarus Verilog (golden model embebido en el testbench)
set -euo pipefail
cd "$(dirname "$0")"

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out tb_mul_seq.sv mul_seq.sv control_fsm.sv

echo ">>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: tb_mul_seq.vcd (abrir con: gtkwave tb_mul_seq.vcd)"
