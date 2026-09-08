#!/bin/bash
# run_cross.sh — cross-check ej3 (fir_iter) vs ej4 (fir_pipeline): misma secuencia de
# entrada a ambos DUTs, comparar que produzcan exactamente la misma salida.
set -euo pipefail
cd "$(dirname "$0")"

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim_cross.out \
    tb_cross_check.sv \
    ../ej3_iterativo/fir_iter.sv ../ej3_iterativo/control_fsm.sv \
    ../ej4_pipeline/fir_pipeline.sv

echo ">>> Ejecutando con vvp..."
vvp sim_cross.out

echo ""
echo "VCD generado: tb_cross_check.vcd"
