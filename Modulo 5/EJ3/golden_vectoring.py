#!/usr/bin/env python3
"""Modelo dorado de referencia para CORDIC vectoring.

Usa fxpmath, igual que los generadores del modulo 3 y EJ1. Calcula la
referencia matematica directa (hypot + atan2), la cuantiza y genera el include
SystemVerilog que consume tb_cordic_vectoring.sv.
"""
from math import atan2, hypot
from pathlib import Path

try:
    from fxpmath import Fxp
except ModuleNotFoundError as exc:
    raise SystemExit("Falta fxpmath. Instalar con: pip3 install --user fxpmath") from exc


def raw(value: float, bits: int, frac: int) -> int:
    """Cuantizacion signed con redondeo al mas cercano y wrap, via fxpmath."""
    number = Fxp(value, signed=True, n_word=bits, n_frac=frac,
                 rounding="around", overflow="wrap")
    return int(number.raw())


def sv_signed(value: int, bits: int) -> str:
    """Literal SystemVerilog valido, incluido para valores negativos."""
    return f"-{bits}'sd{-value}" if value < 0 else f"{bits}'sd{value}"


# Entradas en S(16,15); R en S(16,15); phi en S(18,14).
VECTORS = [
    ("Q1",  0.5,  0.5),
    ("Q2", -0.5,  0.5),
    ("Q3", -0.5, -0.5),
    ("Q4",  0.5, -0.5),
    ("EJE_X", 0.75, 0.0),
    ("EJE_Y", 0.0, -0.75),
]


def main() -> None:
    lines = ["// Generado por golden_vectoring.py. No editar manualmente."]
    print("Caso    x,y                 | R ref (Q15)  phi ref (Q14)")
    for name, x, y in VECTORS:
        x_raw = raw(x, 16, 15)
        y_raw = raw(y, 16, 15)
        r_raw = raw(hypot(x, y), 16, 15)
        phi_raw = raw(atan2(y, x), 18, 14)
        lines.extend([
            f"localparam logic signed [15:0] X_{name} = {sv_signed(x_raw, 16)};",
            f"localparam logic signed [15:0] Y_{name} = {sv_signed(y_raw, 16)};",
            f"localparam logic signed [15:0] R_REF_{name} = {sv_signed(r_raw, 16)};",
            f"localparam logic signed [17:0] PHI_REF_{name} = {sv_signed(phi_raw, 18)};",
        ])
        print(f"{name:6} ({x:+.4f}, {y:+.4f}) | {r_raw:10d} {phi_raw:14d}")

    output = Path(__file__).with_name("cordic_vectoring_expected.svh")
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generado: {output.name}")


if __name__ == "__main__":
    main()
