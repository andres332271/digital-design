# Informe Ejercicio 6 - RNS, multiplicación modular

## Motivación

En aritmética posicional el acarreo se propaga: sumar o multiplicar palabras anchas obliga a esperar que el carry recorra todo el operando, y ese es el camino crítico. El sistema numérico de residuos rompe esa dependencia representando cada valor por sus restos respecto de módulos coprimos, `N → (N mod 3, N mod 5, N mod 7)`. Cada canal opera **por separado y en paralelo**, sin ninguna señal compartida.

El precio es la asimetría: suma y producto salen baratos, pero comparar, dividir, determinar signo o detectar desborde exigen volver al dominio posicional. El ejercicio trabaja la base `{3,5,7}` (M=105) con `X=14`, `Y=6` → 84.

## Implementación

### Módulo

Un módulo por archivo, siguiendo la estructura del datapath. `rns_pkg.sv` concentra la base y las constantes; `bin_to_rns.sv` y `rns_to_bin.sv` son las conversiones; `rns_mult_core.sv` el cálculo; `rns_multiplicacion_modular.sv` el top que los encadena.

Las constantes del Teorema Chino del Resto se **precalculan fuera de línea** (`Cᵢ = Mᵢ·(Mᵢ⁻¹ mod mᵢ)` → 70, 21, 15): al ser la base una constante de diseño, los inversos modulares no requieren lógica y el reconstructor queda como tres multiplicaciones por constante, una suma y una reducción módulo M.

### Test Bench

El modelo de referencia es el operador `*` del simulador, que opera en aritmética posicional. Ahí está el valor de la comparación: el DUT llega al resultado por una vía completamente distinta —descomposición en residuos, producto por canal y reconstrucción por TCR—, así que coincidir en todo el dominio es evidencia fuerte.


## Resultados

```
--- Caso del enunciado: X = 14, Y = 6 ---
  X = 14  ->  (2, 4, 0)
  Y = 6   ->  (0, 1, 6)
  producto residuo a residuo  ->  (0, 4, 0)
  recomposicion por TCR: Z = 84
--- Barrido sobre el rango representable: 711 vectores ---
 RESULTADO: OK - 711 vectores sin discrepancias
```

Fuera de rango el sistema falla en silencio, y el testbench lo documenta explícitamente: `14·9 = 126 > 105` y el DUT devuelve `126 mod 105 = 21` **sin emitir señal de desborde alguna**. No hay bit de overflow porque no hay acarreo entre canales que pueda delatarlo; detectarlo exigiría reconvertir al dominio posicional, anulando la ventaja del sistema.

Costo en bits: 2+3+3 = **8 bits** de registro para cubrir `[0,105)`, contra los **7** que bastan en binario posicional. RNS es redundante en área; lo que compra es que el camino crítico del cálculo pase de un operador de 7 bits a uno de 3. Por eso conviene en cadenas con muchos productos y sumas y conversiones poco frecuentes —FIR largos, correlación, aritmética modular de RSA/ECC—.