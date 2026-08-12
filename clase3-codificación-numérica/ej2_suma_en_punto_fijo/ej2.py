from fxpmath import Fxp

A = Fxp(-0.875, signed=True, n_word=6, n_frac=4)
B = Fxp( 0.9375, signed=True, n_word=8, n_frac=5)
S = Fxp(A.get_val() + B.get_val(), signed=True, n_word=9, n_frac=5)
print(S.bin(), S.get_val()) # 000000010 0.0625

