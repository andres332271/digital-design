#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

echo "1. Generando las constantes de la LUT U(16,15)..."
python3 gen_lut.py

echo "2. Compilando Newton-Raphson y el testbench..."
iverilog -g2012 -Wall -s tb_nr -o nr_sim \
  fsm.sv nr_lut.sv nr.sv tb_nr.sv

echo "3. Simulando error versus numero de iteraciones..."
vvp nr_sim

echo "Resultados detallados: error_vs_n.csv"
echo "Ondas de simulacion: sim_nr.vcd"
