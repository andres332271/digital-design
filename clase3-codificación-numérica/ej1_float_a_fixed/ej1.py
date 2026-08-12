import numpy as np

def num_to_bin(x, NB, NBF, verbose=False):
    """
    Obtiene la representación en punto fijo.
    Funciona tanto para unsigned como para signed con complemento a 2.
    No es necesario especificar signed o unsigned.
    """

    # Calculos
    exponents = np.arange(NB-NBF-1, -NBF-1, -1)
    weights = np.power(2.0, exponents)
    quotients = (x // weights).astype(int)
    bits = quotients % 2

    # Output por consola (opcional)
    if verbose:
        # Imprime calculos intermedios en forma de tabla
        print(f"x = {x}")
        print('')
        print(f"{'exp':>5} {'peso':>10} {'x//peso':>10} {'bit':>5}")
        for e, w, q, b in zip(exponents, weights, quotients, bits):
            print(f"{e:5d} {w:10.4f} {q:10d} {b:5d}")
        print('')

        # Imprime el output final
        output = ''.join(map(str, bits))
        print(f'X({NB}, {NBF}) = \'{output}\'')
        print(70*"=" + "\n")

    return bits


def ieee754_simple(x, verbose=True):

    # Calculos
    if x == 0.0:
        sign, exponent, exponent_biased, frac_part = 0, -127, 0, 0.0
    else:
        sign = int(x < 0)                       # bit de signo
        x_abs = abs(x)
        exponent = int(np.floor(np.log2(x_abs)))       # exponente real (sin sesgo)
        exponent_biased = exponent + 127               # exponente con sesgo
        frac_part = x_abs / 2.0**exponent - 1.0        # parte fraccionaria normalizada, en [0,1)
 
    exp_bits  = num_to_bin(exponent_biased, NB=8,  NBF=0)   # U(8,0)
    mant_bits = num_to_bin(frac_part,     NB=23, NBF=23)  # U(23,23)
 
    output = str(sign) + ''.join(map(str, exp_bits)) + ''.join(map(str, mant_bits))
 
    # Output por consola (opcional)
    if verbose:
        print(f"x = {x}")
        print("")
        print(f"{'item':<30} {'numero':<10} {'bits':<25}")
        print(65*'-')
        print(f"{'signo':<30} {'':<10} {sign:<25}")
        print(f"{f'exponente (e={exponent}, sesgo 127)':<30} {exponent_biased:<10} {''.join(map(str, exp_bits)):<25}")
        print(f"{'mantisa':<30} {frac_part:<10.6f} {''.join(map(str, mant_bits)):<25}")
        print("")
        print(f"  IEEE754: \'{output}\'")
        print(70*"=" + "\n")

    return


if __name__ == '__main__':
    x = 9.625
    num_to_bin(x, 8, 3, verbose=True)
    ieee754_simple(x, verbose=True)
