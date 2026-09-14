#!/bin/bash
# run.sh — compila y simula con Icarus Verilog (golden model embebido en el testbench)
# N_VECTORS=<n> ./run.sh para mas/menos muestras aleatorias (default 200).
set -euo pipefail
cd "$(dirname "$0")"

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out tb_fir_pipeline_cadena.sv fir_pipeline_cadena.sv

echo ">>> Ejecutando con vvp..."
vvp sim.out ${N_VECTORS:+"+N_VECTORS=$N_VECTORS"}

echo ""
echo "VCD generado: tb_fir_pipeline_cadena.vcd (abrir con: gtkwave tb_fir_pipeline_cadena.vcd)"

echo ""
echo ">>> Mapeando a primitivas Xilinx XC7 con Yosys..."
yosys -s synth_xc7.ys > yosys_xc7.log
echo "Log de sintesis: yosys_xc7.log (DSP48E1/CARRY4/FF/LUT via 'stat'; sin P&R ni timing)."

echo ""
echo ">>> Mapeando a celdas estandar sky130hd con Yosys..."
yosys -s synth_sky130.ys > yosys_sky130.log
echo "Log de sintesis: yosys_sky130.log (celdas + area en um^2 via 'stat -liberty'; sin P&R ni timing)."
