"""Genera a.hex / b.hex / expected.hex para el testbench de ej2 (suma en punto fijo).

Formatos (fijados por la consigna):
    A: S(6, 4)   B: S(8, 5)   Suma: S(9, 5)   (NBF_out = max, NBI_out = max + 1)

Cada línea de los .hex es el patrón de bits en complemento a 2, en hex,
listo para $readmemh en el testbench SystemVerilog.
"""
import os
import random

from fxpmath import Fxp

NBA, NBFA = 6, 4
NBB, NBFB = 8, 5
NBS, NBFS = 9, 5  # NBF_out = max(NBFA, NBFB); NBI_out = max(NBIA, NBIB) + 1

N_VECTORS = int(os.environ.get("N_VECTORS", 1000))
random.seed(0)


def raw_hex(bits: str) -> str:
    n_hex = (len(bits) + 3) // 4
    return format(int(bits, 2), f"0{n_hex}x")


def sum_case(code_a: int, code_b: int):
    a = Fxp(code_a / 2**NBFA, signed=True, n_word=NBA, n_frac=NBFA)
    b = Fxp(code_b / 2**NBFB, signed=True, n_word=NBB, n_frac=NBFB)
    s = Fxp(a.get_val() + b.get_val(), signed=True, n_word=NBS, n_frac=NBFS)
    return a, b, s


edge_codes_a = [-(2**(NBA - 1)), 2**(NBA - 1) - 1, 0]
edge_codes_b = [-(2**(NBB - 1)), 2**(NBB - 1) - 1, 0]

cases = [(ca, cb) for ca in edge_codes_a for cb in edge_codes_b]
cases.append((-28, 30))  # ejemplo de la consigna: A=-1.75, B=0.9375

while len(cases) < N_VECTORS:
    ca = random.randint(-(2**(NBA - 1)), 2**(NBA - 1) - 1)
    cb = random.randint(-(2**(NBB - 1)), 2**(NBB - 1) - 1)
    cases.append((ca, cb))

with open("a.hex", "w") as fa, open("b.hex", "w") as fb, open("expected.hex", "w") as fe:
    for ca, cb in cases:
        a, b, s = sum_case(ca, cb)
        fa.write(raw_hex(a.bin()) + "\n")
        fb.write(raw_hex(b.bin()) + "\n")
        fe.write(raw_hex(s.bin()) + "\n")

print(f"Generados {len(cases)} vectores en a.hex / b.hex / expected.hex")
