#!/bin/bash
# run.sh — compila y simula con Icarus Verilog
set -euo pipefail
cd "$(dirname "$0")"
 
TB=tb_booth_radix2
 
RTL=(
    booth_radix2.sv
)
 
echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out "${TB}.sv" "${RTL[@]}"
 
echo ">>> Ejecutando con vvp..."
vvp sim.out
 
echo ""
echo "VCD generado: ${TB}.vcd (abrir con: gtkwave ${TB}.vcd)"