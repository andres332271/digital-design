#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
python3 golden_vectoring.py
iverilog -g2012 -Wall -s tb_cordic_vectoring -o cordic_vectoring_sim \
  cordic.sv ROM.sv cordic_fsm.sv tb_cordic_vectoring.sv
vvp cordic_vectoring_sim
yosys -p 'read_verilog -sv ROM.sv cordic_fsm.sv cordic.sv; synth_xilinx -family xc7 -top cordic_vectoring; stat' > yosys_vectoring_xc7.log
echo "Sintesis XC7: yosys_vectoring_xc7.log"
