#!/usr/bin/env python3
"""Recomputa el IPB del ej6 (y el de su version look-ahead) con una funcion
generica IPB = max(T_lazo_i / D_lazo_i), en vez de la cuenta a mano del report.
"""
from fractions import Fraction

T_MUL = 2  # tu, misma referencia que ej1/ej3/ej4/ej5
T_ADD = 1  # tu

def iteration_bound(lazos):
    """lazos: lista de (T_lazo, D_lazo). Devuelve IPB = max(T_i/D_i)."""
    limites = [Fraction(t, d) for t, d in lazos]
    return max(limites), limites

def demo():
    # IIR de 1er orden: y[n] = a*y[n-1] + b*x[n].
    # Unico lazo: add -> z^-1 -> xa -> add. x*b no es parte del lazo (entrada externa).
    T_lazo = T_MUL + T_ADD  # xa + add
    D_lazo = 1              # 1 registro z^-1
    ipb, limites = iteration_bound([(T_lazo, D_lazo)])
    print(f"IIR 1er orden: T_lazo={T_lazo}tu D_lazo={D_lazo} -> LB={limites[0]}tu")
    print(f"IPB = {ipb} tu  (report dice 3 tu)")
    assert ipb == Fraction(3), "no coincide con ej6_ipb/report.md"

    # Look-ahead: mismo T_lazo (a^2, a*b precalculados fuera del lazo), pero
    # el lazo ahora pasa por y[n-2] -> D_lazo=2.
    ipb2, limites2 = iteration_bound([(T_lazo, 2)])
    print(f"\nLook-ahead: T_lazo={T_lazo}tu D_lazo=2 -> LB={limites2[0]}tu")
    print(f"IPB_nuevo = {ipb2} tu  (report dice 1.5 tu)")
    assert ipb2 == Fraction(3, 2), "no coincide con ej6_ipb/report.md"

    print("\nRESULTADO: OK - IPB y IPB_nuevo coinciden con ej6_ipb/report.md")

if __name__ == "__main__":
    demo()
