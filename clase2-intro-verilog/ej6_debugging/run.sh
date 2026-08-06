#!/bin/bash
# run.sh — compila y simula con Icarus Verilog
echo ">>> Compilando con iverilog..."
iverilog -g2012 -o sim.out tb_alu.v alu_bad.v alu_fix1.v alu_fix2.v

echo ">>> Ejecutando con vvp..."
vvp sim.out

echo ""
echo "VCD generado: *.vcd (abrir con: gtkwave *.vcd)"
