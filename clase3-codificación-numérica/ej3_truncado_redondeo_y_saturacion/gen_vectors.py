"""Genera los .hex para el testbench de ej3 (truncado / redondeo / wrap / saturación).

Dos recortes, cada uno con dos variantes (según la consigna):
    x: S(10,6) -> S(7,3)   (NBI igual, solo se pierden bits fraccionarios)
       -> x_trunc.hex, x_round.hex
    y: S(11,6) -> S(5,3)   (NBI e NBF se achican, con overflow real)
       -> y_wrap.hex, y_sat.hex

expected_*.hex se calcula con fxpmath (mismos parámetros overflow/rounding
que usa el DUT), y sirve de referencia golden para el testbench.
"""
import os
import random

from fxpmath import Fxp

NBI_X_IN, NBF_X_IN = 4, 6
NBI_X_OUT, NBF_X_OUT = 4, 3

NBI_Y_IN, NBF_Y_IN = 5, 6
NBI_Y_OUT, NBF_Y_OUT = 2, 3

N_VECTORS = int(os.environ.get("N_VECTORS", 1000))
random.seed(0)


def raw_hex(bits: str) -> str:
    n_hex = (len(bits) + 3) // 4
    return format(int(bits, 2), f"0{n_hex}x")


def code_hex(code: int, width: int) -> str:
    n_hex = (width + 3) // 4
    return format(code & (2**width - 1), f"0{n_hex}x")


def resize(code, n_word_in, n_frac_in, n_word_out, n_frac_out, rounding, overflow):
    x = Fxp(code / 2**n_frac_in, signed=True, n_word=n_word_in, n_frac=n_frac_in)
    y = Fxp(x.get_val(), signed=True, n_word=n_word_out, n_frac=n_frac_out,
             rounding=rounding, overflow=overflow)
    return raw_hex(y.bin())


def gen_codes(nbi, nbf, extra):
    w = nbi + nbf
    codes = list(extra)
    lo, hi = -(2**(w - 1)), 2**(w - 1) - 1
    while len(codes) < N_VECTORS:
        codes.append(random.randint(lo, hi))
    return codes[:N_VECTORS]


# Ejemplo de la consigna: x = 5.5625 en S(10,6) -> código = 5.5625 * 2**6 = 356
x_edges = [356, 0, -(2**(NBI_X_IN + NBF_X_IN - 1)), 2**(NBI_X_IN + NBF_X_IN - 1) - 1]
x_codes = gen_codes(NBI_X_IN, NBF_X_IN, x_edges)

with open("x.hex", "w") as fx, \
     open("expected_x_trunc.hex", "w") as fxt, \
     open("expected_x_round.hex", "w") as fxr:
    for code in x_codes:
        fx.write(code_hex(code, NBI_X_IN + NBF_X_IN) + "\n")
        fxt.write(resize(code, NBI_X_IN + NBF_X_IN, NBF_X_IN, NBI_X_OUT + NBF_X_OUT, NBF_X_OUT,
                          "trunc", "wrap") + "\n")
        fxr.write(resize(code, NBI_X_IN + NBF_X_IN, NBF_X_IN, NBI_X_OUT + NBF_X_OUT, NBF_X_OUT,
                          "around", "wrap") + "\n")

# Ejemplo de la consigna: y = 8.75 en S(11,6) -> código = 8.75 * 2**6 = 560
y_edges = [560, 0, -(2**(NBI_Y_IN + NBF_Y_IN - 1)), 2**(NBI_Y_IN + NBF_Y_IN - 1) - 1]
y_codes = gen_codes(NBI_Y_IN, NBF_Y_IN, y_edges)

with open("y.hex", "w") as fy, \
     open("expected_y_wrap.hex", "w") as fyw, \
     open("expected_y_sat.hex", "w") as fys:
    for code in y_codes:
        fy.write(code_hex(code, NBI_Y_IN + NBF_Y_IN) + "\n")
        fyw.write(resize(code, NBI_Y_IN + NBF_Y_IN, NBF_Y_IN, NBI_Y_OUT + NBF_Y_OUT, NBF_Y_OUT,
                          "trunc", "wrap") + "\n")
        fys.write(resize(code, NBI_Y_IN + NBF_Y_IN, NBF_Y_IN, NBI_Y_OUT + NBF_Y_OUT, NBF_Y_OUT,
                          "trunc", "saturate") + "\n")

print(f"Generados {len(x_codes)} vectores de x y {len(y_codes)} de y")
