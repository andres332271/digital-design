# Módulo 3 - codificación numérica

Esta colección contiene 6 ejercicios que cubren los temas centrales del módulo: conversión Float ↔ Fixed, suma y multiplicación en punto fijo, recortado con truncado/redondeo/saturación, recodificación CSD, multiplicación Booth radix-2, y aritmética en RNS.

Los ejercicios 2 a 6 cuentan con un módulo Verilog y un testbench para Icarus + GTKWave; los archivos están en ejercicios/verilog/.

- ej1: Conversión Float ↔ Fixed (Cálculo)
- ej2: Suma en punto fijo signado (Cálculo + Verilog)
- ej3: Truncado, Redondeo y Saturación (Cálculo + Verilog)
- ej4: CSD — recodificación (Cálculo + Verilog)
- ej5: Booth radix-2 (Cálculo + Verilog)
- ej6: RNS — multiplicación modular (Cálculo + Verilog)

## fxpmath — modelo de referencia en Python

Los ejercicios 2 a 6 de esta colección incluyen testbenches self-checking: en lugar de inspeccionar visualmente formas de onda, comparan la salida del DUT contra una referencia "golden" generada por una librería Python que modela aritmética en punto fijo.

La librería que usamos es fxpmath. Reproduce con exactitud el formato S(NB, NBF) que estudiamos en el módulo, con control fino de overflow (wrap / saturate) y de redondeo (trunc / around / etc).

### Instalación

fxpmath se instala con pip:

```
pip3 install --user fxpmath
```

Compatible con Python ≥ 3.7. No necesita compilación: es Python puro apoyado en NumPy.

### Uso básico

La clase principal es Fxp. Recibe un valor y los parámetros del formato:

```
from fxpmath import Fxp
x = Fxp(9.625, signed=True, n_word=8, n_frac=3) # S(8, 3)
print(x.bin()) # '01001101'
print(x.hex()) # '4d'
print(x.get_val()) # 9.625
```

### Parámetros del constructor

```
Parámetro       Valores               Significado
---------------------------------------------------------------------------------
signed          True / False          Aritmética en C2 o sin signo
n_word          entero ≥ 1            NB (bits totales)
n_frac          entero                NBF (bits fraccionales; puede ser negativo)
overflow        "wrap" / "saturate"   Qué hacer si el valor sale del rango
rounding        "trunc" / "around"    Cómo eliminar bits LSB sobrantes
```

### Ejemplos relevantes para los ejercicios

Suma en punto fijo (ej2)

```
A = Fxp(-0.875, signed=True, n_word=6, n_frac=4)
B = Fxp( 0.9375, signed=True, n_word=8, n_frac=5)
S = Fxp(A.get_val() + B.get_val(), signed=True, n_word=9, n_frac=5)
print(S.bin(), S.get_val()) # 000000010 0.0625
```

Trunc vs Round, Wrap vs Sat (ej3)

```
x = 5.5625
tw = Fxp(x, signed=True, n_word=7, n_frac=3, overflow='wrap', rounding='trunc')
rs = Fxp(x, signed=True, n_word=7, n_frac=3, overflow='saturate',
rounding='around')
print(tw.get_val(), rs.get_val()) # 5.5 5.625
```

Multiplicación signada (ej4 y ej5)

```
A = Fxp(6, signed=True, n_word=4)
B = Fxp(-5, signed=True, n_word=4)
P = Fxp(A.get_val() * B.get_val(), signed=True, n_word=8)
print(P.get_val()) # -30
```

## Integración con los testbenches Verilog

En cada carpeta `verilog/ejNN_xx/` hay 4 archivos:

```
Archivo           Contenido
----------------------------------------------------------------------------------
gen_vectors.py    Genera los vectores .hex usando fxpmath como referencia
*.v (DUT)         Módulo Verilog a verificar
tb_*.v            Testbench self-checking que lee los .hex y compara contra el DUT
run.sh            Encadena los pasos: generar → compilar → simular → GTKWave
```

Flujo de un ejercicio:

- gen_vectors.py emite uno o más archivos .hex con los vectores de entrada (a.hex, b.hex, …) y los valores esperados (expected.hex).
- El testbench Verilog usa $readmemh para cargar esas memorias.
- Por cada vector, aplica las entradas al DUT y compara la salida contra el valor esperado.
- Al final imprime PASS o FAIL con la cantidad de casos correctos / fallidos.

### Ajustar la cobertura

Por defecto, cada gen_vectors.py genera 1000 vectores (bordes + random). Para cambiarlo, exportar N_VECTORS antes de correr run.sh:

```
# Cobertura rápida (debug)
N_VECTORS=100 ./run.sh
# Cobertura exhaustiva
N_VECTORS=10000 ./run.sh
En los ejercicios 5 y 6 la cobertura por defecto es exhaustiva (256 y ~105 casos respectivamente),
porque el rango representable cabe entero en memoria. N_VECTORS sólo limita el random extra.
```

### Comandos individuales (sin run.sh)

```
# 1. Generar vectores
python3 gen_vectors.py
# 2. Compilar
iverilog -o sim.out tb_*.v *.v
# 3. Simular
vvp sim.out
# 4. Ver waveform
gtkwave *.vcd &
```
