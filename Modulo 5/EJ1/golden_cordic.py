#!/usr/bin/env python3
"""Modelo dorado CORDIC usando fxpmath para el formato S(16,14).

Genera cordic_expected.svh, que el testbench incluye para comparar el RTL.
"""
from math import atan, cos, pi, sin
from pathlib import Path
try:
    from fxpmath import Fxp
except ModuleNotFoundError as exc:
    raise SystemExit("Falta fxpmath. Instalar con: pip3 install --user fxpmath") from exc

WORD_BITS = 16
FRAC_BITS = 14
N_ITER = 14


def fxp(value: float) -> Fxp:
    """Crea un numero S(16,14), igual a la convencion usada en Modulo 3."""
    return Fxp(value, signed=True, n_word=WORD_BITS, n_frac=FRAC_BITS,
               rounding="around", overflow="wrap")


def raw(value: float) -> int:
    """Convierte un real a su entero con signo S(16,14)."""
    return int(fxp(value).raw())


K_INV = raw(0.607252935)
ATAN_LUT = [raw(atan(2.0 ** -i)) for i in range(N_ITER)]
VECTORS = [("PI_6", raw(pi / 6)),
           ("PI_4", raw(pi / 4)),
           ("PI_3", raw(pi / 3))]


def cordic(theta: int) -> tuple[int, int, int]:
    """Replica las 14 iteraciones RTL, con shifts aritmeticos de enteros."""
    x, y, z = K_INV, 0, theta
    for i, atan_i in enumerate(ATAN_LUT):
        if z >= 0:
            x, y, z = x - (y >> i), y + (x >> i), z - atan_i
        else:
            x, y, z = x + (y >> i), y - (x >> i), z + atan_i
    return x, y, z


def main() -> None:
    output = Path(__file__).with_name("cordic_expected.svh")
    lines = ["// Archivo generado por golden_cordic.py. No editar manualmente."]

    print("Caso    theta fijo | cos RTL-modelo  sen RTL-modelo | cos ideal  sen ideal")
    for name, theta in VECTORS:
        x, y, _ = cordic(theta)
        theta_real = theta / (1 << FRAC_BITS)
        ideal_x = raw(cos(theta_real))
        ideal_y = raw(sin(theta_real))
        lines.extend([
            f"localparam logic signed [15:0] THETA_{name} = 16'sd{theta};",
            f"localparam logic signed [15:0] EXP_COS_{name} = 16'sd{x};",
            f"localparam logic signed [15:0] EXP_SEN_{name} = 16'sd{y};",
        ])
        print(f"{name:6} {theta:11d} | {x:15d} {y:15d} | {ideal_x:9d} {ideal_y:9d}")

    output.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\nGenerado: {output.name}")


if __name__ == "__main__":
    main()
