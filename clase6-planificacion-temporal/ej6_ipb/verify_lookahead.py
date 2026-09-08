#!/usr/bin/env python3
"""Verifica que el desenrollado look-ahead de ej6_ipb/report.md sea EXACTAMENTE
la misma secuencia que la recursion original, no una aproximacion.

Original:  y[n] = a*y[n-1] + b*x[n]
Look-ahead: y[n] = a^2*y[n-2] + a*b*x[n-1] + b*x[n]   (n >= 1; y[-1]=y[-2]=0)

Usa Fraction (aritmetica racional exacta) para que una discrepancia no pueda
esconderse detras de un redondeo de punto flotante.
"""
from fractions import Fraction
import random

def golden(a, b, x):
    """Recursion original: y[n] = a*y[n-1] + b*x[n]."""
    y = []
    y_prev = Fraction(0)
    for xn in x:
        yn = a * y_prev + b * xn
        y.append(yn)
        y_prev = yn
    return y

def lookahead(a, b, x, y_true):
    """Formula desenrollada, usando y_true[n-2] (la misma secuencia, no una
    recalculada aparte -- lo que se verifica es la IDENTIDAD algebraica, no
    que dos implementaciones distintas coincidan por casualidad)."""
    y = []
    for n in range(len(x)):
        y_n1 = Fraction(0) if n - 1 < 0 else y_true[n - 1]
        y_n2 = Fraction(0) if n - 2 < 0 else y_true[n - 2]
        x_n1 = Fraction(0) if n - 1 < 0 else x[n - 1]
        if n == 0:
            # Caso base: coincide con la recursion original por construccion
            # (y[-1] = y[-2] = 0 en ambas).
            yn = b * x[n]
        else:
            yn = a * a * y_n2 + a * b * x_n1 + b * x[n]
        y.append(yn)
    return y

def demo():
    random.seed(1)
    N_CASOS = 200
    N_MUESTRAS = 50
    errores = 0
    for _ in range(N_CASOS):
        a = Fraction(random.randint(-9, 9), random.randint(1, 10))
        b = Fraction(random.randint(-9, 9), random.randint(1, 10))
        x = [Fraction(random.randint(-100, 100)) for _ in range(N_MUESTRAS)]

        y_true = golden(a, b, x)
        y_alt = lookahead(a, b, x, y_true)

        if y_alt != y_true:
            errores += 1
            print(f"  ERROR: a={a} b={b}")
            for n, (yt, ya) in enumerate(zip(y_true, y_alt)):
                if yt != ya:
                    print(f"    n={n}: original={yt} look-ahead={ya}")

    print(f"{N_CASOS} pares (a,b) x {N_MUESTRAS} muestras, aritmetica racional exacta")
    if errores == 0:
        print("RESULTADO: OK - identidad algebraica confirmada, 0 discrepancias")
    else:
        print(f"RESULTADO: FALLO - {errores}/{N_CASOS} casos con discrepancias")
    assert errores == 0

if __name__ == "__main__":
    demo()
