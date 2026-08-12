#!/bin/bash
# run.sh — genera vectores, compila y simula con Icarus Verilog
set -euo pipefail
cd "$(dirname "$0")"

echo ">>> Generando vectores con fxpmath..."
python3 gen_vectors.py

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out tb_sumador_punto_fijo.sv sumador_punto_fijo.sv

echo ">>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: tb_sumador_punto_fijo.vcd (abrir con: gtkwave tb_sumador_punto_fijo.vcd)"
