#!/usr/bin/env sh
set -eu

# Genera los valores esperados con un modelo independiente en Python.
python3 golden_cordic.py

# Compila y ejecuta el testbench con Icarus Verilog.
iverilog -g2012 -s tb_cordic -o cordic_sim \
  cordic.sv ROM.sv cordic_fsm.sv tb_cordic.sv
vvp cordic_sim
