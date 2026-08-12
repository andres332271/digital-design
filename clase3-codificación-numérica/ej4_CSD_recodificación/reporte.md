# Informe Ejercicio 4 - Recodificación CSD

## Motivación

Multiplicar por una constante conocida en tiempo de diseño no necesita un multiplicador general: como `Y = X·K = Σ dᵢ (X << i)` y los corrimientos son cableado, el costo real es la **cantidad de dígitos no nulos de K** (con `n` no-ceros hacen falta `n−1` operadores). En binario la representación es única y no hay nada que elegir; al admitir dígitos `{−1,0,+1}` el sistema se vuelve redundante y puede elegirse la forma de menor peso. Para K=23: binario `2⁴+2²+2¹+2⁰` (4 términos, 3 sumadores) contra CSD `2⁵−2³−2⁰` (3 términos, 2 operadores). El ejercicio implementa ambas y evidencia la diferencia.

## Implementación

### Módulo

Un módulo por archivo: `CSD_recodificacion.sv` es el diseño y `mult_K23_bin.sv` la referencia de comparación. El cuerpo del CSD es una línea, `assign y = (xe <<< 5) - (xe <<< 3) - xe`, que traduce dígito a dígito la recodificación.

Dos decisiones no triviales. **`OUTW = WIDTH + 5`** no es libre: multiplicar por 23 escala el rango en ese factor, así que hacen falta `ceil(log₂23)=5` bits enteros extra. Con `WIDTH=8` el peor caso es `−128·23 = −2944`, que no entra en 12 bits (`[−2048,2047]`) pero sí en 13. **La extensión de signo va antes del corrimiento**: si se desplazara sobre los 8 bits de entrada, `(x <<< 5)` perdería los cinco bits de más peso. En hardware la extensión no cuesta nada — es el bit de signo conectado a cinco posiciones.

### Test Bench

`tb_CSD_recodificacion.sv` instancia los dos DUT con el mismo estímulo y chequea tres propiedades independientes por vector: cada implementación contra el modelo de referencia (`x*23`), y **ambas entre sí**. Se usa `!==` en lugar de `!=` para que una salida en `x` dispare el error en vez de devolver desconocido, y `#1` tras asignar la entrada para que las salidas se propaguen antes de leerlas.

## Resultados

```
--- Barrido exhaustivo: 256 vectores ---
 RESULTADO: OK - 256 vectores sin discrepancias
```
