#!/bin/bash
# run.sh — compila y simula con Icarus Verilog (golden model embebido en el testbench)
# N_VECTORS=<n> ./run.sh para mas/menos muestras aleatorias (default 200).
set -euo pipefail
cd "$(dirname "$0")"

echo ">>> Compilando con iverilog..."
iverilog -g2012 -Wall -o sim.out tb_fir_iter.sv fir_iter.sv control_fsm.sv

echo ">>> Ejecutando con vvp..."
vvp sim.out ${N_VECTORS:+"+N_VECTORS=$N_VECTORS"}

echo ""
echo "VCD generado: tb_fir_iter.vcd (abrir con: gtkwave tb_fir_iter.vcd)"

echo ""
echo ">>> Mapeando a primitivas Xilinx XC7 con Yosys..."
yosys -s synth.ys > yosys.log
echo "Log de sintesis: yosys.log (DSP48E1/CARRY4/FF/LUT via 'stat'; sin P&R ni timing)."
