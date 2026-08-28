#!/usr/bin/env python3
"""Genera la LUT inicial para el reciproco Newton-Raphson."""

N_ENTRIES = 8
FRAC_BITS = 15
SCALE = 1 << FRAC_BITS


def quantize(value: float) -> int:
    """Redondea un valor real al entero U(16,15) mas cercano."""
    return int(value * SCALE + 0.5)


def main() -> None:
    print("// indice | punto medio | y0 real | constante U(16,15)")

    for index in range(N_ENTRIES):
        lower = 0.5 + index / 16.0
        upper = 0.5 + (index + 1) / 16.0
        midpoint = (lower + upper) / 2.0
        seed = 1.0 / midpoint
        seed_q15 = quantize(seed)

        print(
            f"3'd{index}: y0 = 16'h{seed_q15:04X}; "
            f"// x_mid={midpoint:.5f}, y0={seed:.9f}"
        )


if __name__ == "__main__":
    main()
