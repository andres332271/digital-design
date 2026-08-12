#!/bin/bash
# run.sh — compila y simula con Icarus Verilog
set -euo pipefail
cd "$(dirname "$0")"

TB=tb_rns_multiplicacion_modular

RTL=(
    rns_pkg.sv
    bin_to_rns.sv
    rns_mult_core.sv
    rns_to_bin.sv
    rns_multiplicacion_modular.sv
)

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out "${RTL[@]}" "${TB}.sv"

echo ">>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: ${TB}.vcd (abrir con: gtkwave ${TB}.vcd)"