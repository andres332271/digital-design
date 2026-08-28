#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

echo "1. Compilando y simulando el pipeline..."
iverilog -g2012 -Wall -s tb_cordic_pipeline -o cordic_pipeline_sim \
  cordic_stage.sv cordic_pipeline.sv tb_cordic_pipeline.sv
vvp cordic_pipeline_sim

echo "2. Mapeando pipeline a primitivas Xilinx XC7 con Yosys..."
yosys -s synth.ys > yosys_pipeline.log

echo "3. Mapeando folded a primitivas Xilinx XC7 con Yosys..."
yosys -s synth_folded.ys > yosys_folded.log

echo "Listo: los logs contienen LUTs, FFs y CARRY4. Para Fmax hace falta P&R/timing."
