#!/usr/bin/env python3
"""Recomputa ASAP/ALAP/movilidad del DFG de ej1 con un scheduler generico
(topologico, modelo de 1 ciclo por operacion -- ver ej2_asap_alap/report.md),
en vez de confiar solo en la tabla armada a mano.
"""

def asap(preds):
    """preds: dict nodo -> lista de predecesores. Devuelve dict nodo -> ciclo ASAP."""
    ciclo = {}
    def calc(n):
        if n in ciclo:
            return ciclo[n]
        if not preds[n]:
            ciclo[n] = 1
        else:
            ciclo[n] = 1 + max(calc(p) for p in preds[n])
        return ciclo[n]
    for n in preds:
        calc(n)
    return ciclo

def alap(preds, asap_ciclo):
    succs = {n: [] for n in preds}
    for n, ps in preds.items():
        for p in ps:
            succs[p].append(n)
    L = max(asap_ciclo.values())
    ciclo = {}
    def calc(n):
        if n in ciclo:
            return ciclo[n]
        if not succs[n]:
            ciclo[n] = L
        else:
            ciclo[n] = min(calc(s) for s in succs[n]) - 1
        return ciclo[n]
    for n in preds:
        calc(n)
    return ciclo

def demo():
    # DFG de ej1_dfg_fir4/report.md (arbol de sumas): m0..m3 sin predecesores
    # (entradas primarias), a1=m0+m1, a2=m2+m3, a3=a1+a2=y[n].
    preds = {
        "m0": [], "m1": [], "m2": [], "m3": [],
        "a1": ["m0", "m1"],
        "a2": ["m2", "m3"],
        "a3": ["a1", "a2"],
    }
    esperado_asap = {"m0": 1, "m1": 1, "m2": 1, "m3": 1, "a1": 2, "a2": 2, "a3": 3}
    esperado_alap = dict(esperado_asap)  # ej2_asap_alap/report.md: movilidad 0 en todos

    a_asap = asap(preds)
    a_alap = alap(preds, a_asap)

    print(f"{'nodo':<4} {'ASAP':>5} {'ALAP':>5} {'mov':>4}")
    errores = 0
    for n in preds:
        mov = a_alap[n] - a_asap[n]
        print(f"{n:<4} {a_asap[n]:>5} {a_alap[n]:>5} {mov:>4}")
        if a_asap[n] != esperado_asap[n] or a_alap[n] != esperado_alap[n]:
            print(f"  ERROR: {n} no coincide con ej2_asap_alap/report.md")
            errores += 1

    print()
    print(f"Latencia ASAP (script) = {max(a_asap.values())} ciclos "
          f"(report dice 3)")
    if errores == 0:
        print("RESULTADO: OK - coincide exactamente con la tabla de ej2_asap_alap/report.md")
    else:
        print(f"RESULTADO: FALLO - {errores} nodos no coinciden")
    assert errores == 0

if __name__ == "__main__":
    demo()
