#!/usr/bin/env python3
"""Recomputa las cuentas en `tu` de ej5_ppa/report.md a partir de los datos
medidos en simulacion (no re-deriva los datos medidos en si -- esos vienen de
./run.sh, ver ref/review-plan.md punto 3), solo la aritmetica que combina
ciclos medidos x T_clk analitico.
"""
from fractions import Fraction

T_MUL = 2  # tu
T_ADD = 1  # tu
N = 4      # taps

# --- ej3: iterativo ---
T_CLK_ITER = T_MUL + T_ADD  # MAC de 1 ciclo, mult y add sin registro intermedio
LAT_CICLOS_ITER = N          # medido en tb_fir_iter.sv: 4 ciclos constantes
THROUGHPUT_MIN_CICLOS_ITER = N + 1  # minimo de la FSM (N compute + 1 done)
THROUGHPUT_MEDIDO_CICLOS_ITER = 6   # medido en tb_fir_iter.sv (con overhead de TB)

# --- ej4: pipeline retimeado ---
T_CLK_PIPE = max(T_MUL, T_ADD + T_ADD)  # etapas balanceadas: mult vs. 2 add
LAT_CICLOS_PIPE = 2                      # 2 etapas, medido en tb_fir_pipeline.sv
THROUGHPUT_CICLOS_PIPE = 1               # 1 muestra/ciclo en regimen permanente

def demo():
    lat_iter_tu = LAT_CICLOS_ITER * T_CLK_ITER
    tp_min_iter = Fraction(1, THROUGHPUT_MIN_CICLOS_ITER * T_CLK_ITER)
    tp_medido_iter = Fraction(1, THROUGHPUT_MEDIDO_CICLOS_ITER * T_CLK_ITER)

    lat_pipe_tu = LAT_CICLOS_PIPE * T_CLK_PIPE
    tp_pipe = Fraction(1, THROUGHPUT_CICLOS_PIPE * T_CLK_PIPE)

    print(f"T_clk iterativo (mult+add sin registro)      = {T_CLK_ITER} tu   (report: 3 tu)")
    print(f"T_clk pipeline  (max(mult, 2*add))            = {T_CLK_PIPE} tu   (report: 2 tu)")
    print(f"fmax relativo pipeline/iterativo              = {Fraction(T_CLK_ITER, T_CLK_PIPE)}x "
          f"(report: 1.5x)")
    print()
    print(f"Latencia iterativo  = {LAT_CICLOS_ITER} ciclos x {T_CLK_ITER}tu = {lat_iter_tu} tu"
          f"   (report: 12 tu)")
    print(f"Latencia pipeline   = {LAT_CICLOS_PIPE} ciclos x {T_CLK_PIPE}tu = {lat_pipe_tu} tu"
          f"    (report: 4 tu)")
    print()
    print(f"Throughput iterativo (minimo FSM)  = 1/{THROUGHPUT_MIN_CICLOS_ITER*T_CLK_ITER} tu^-1"
          f"   (report: 1/15 tu^-1)")
    print(f"Throughput iterativo (medido en TB) = 1/{THROUGHPUT_MEDIDO_CICLOS_ITER*T_CLK_ITER} tu^-1"
          f"   (report: 1/18 tu^-1)")
    print(f"Throughput pipeline (medido, streaming) = 1/{THROUGHPUT_CICLOS_PIPE*T_CLK_PIPE} tu^-1"
          f"    (report: 1/2 tu^-1)")

    throughput_relativo = tp_pipe / tp_min_iter
    print()
    print(f"Throughput relativo pipeline/iterativo (vs. minimo FSM) = {throughput_relativo}x"
          f"   (report: ~7.5x)")

    errores = 0
    checks = [
        (T_CLK_ITER, 3), (T_CLK_PIPE, 2),
        (lat_iter_tu, 12), (lat_pipe_tu, 4),
        (throughput_relativo, Fraction(15, 2)),
    ]
    for obtenido, esperado in checks:
        if obtenido != esperado:
            print(f"  ERROR: {obtenido} != {esperado}")
            errores += 1

    print()
    if errores == 0:
        print("RESULTADO: OK - todas las cuentas en tu de ej5_ppa/report.md verificadas")
    else:
        print(f"RESULTADO: FALLO - {errores} cuentas no coinciden")
    assert errores == 0

if __name__ == "__main__":
    demo()
