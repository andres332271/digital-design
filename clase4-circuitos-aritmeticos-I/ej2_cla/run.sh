#!/bin/bash
# run.sh — compila y simula con Icarus Verilog
set -euo pipefail
cd "$(dirname "$0")"

TB=tb_cla

RTL=(
    rca.sv
    full_adder.sv
    cla4.sv
    cla16.sv
)

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out ${TB}.sv ${RTL[@]}

echo " >>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: ${TB}.vcd (abrir con: gtkwave ${TB}.vcd)"