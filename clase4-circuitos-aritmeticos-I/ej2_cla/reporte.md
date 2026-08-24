# Informe Ejercicio 2 - CLA 4 bits y CLA 16 bits jerárquico

## Motivación

El RCA del ejercicio 1 tiene delay lineal porque cada etapa espera el acarreo de la anterior. El Carry Lookahead ataca eso con álgebra: define, para cada posición, dos señales que dependen **solo de los operandos** y no del acarreo,

```
g_i = a_i · b_i        (la posición genera acarreo)
p_i = a_i ⊕ b_i        (la posición propaga el que le llega)
```

de modo que `c_{i+1} = g_i + p_i·c_i`. Desplegando esa recursión, todos los acarreos quedan expresados en función de `g`, `p` y `c₀` exclusivamente:

```
c1 = g0 + p0·c0
c2 = g1 + p1·g0 + p1·p0·c0
c3 = g2 + p2·g1 + p2·p1·g0 + p2·p1·p0·c0
c4 = g3 + p3·g2 + p3·p2·g1 + p3·p2·p1·g0 + p3·p2·p1·p0·c0
```

Se evalúan todos en paralelo, en dos niveles de lógica, sin importar la posición. La profundidad pasa de O(N) a constante dentro del bloque.

El precio se lee en la última ecuación: cinco términos, uno de ellos con AND de cinco entradas. El fan-in crece de forma cuadrática con el ancho del bloque, por lo que un CLA plano de 16 bits necesitaría un AND de 17 entradas — inviable en cualquier biblioteca de celdas. De ahí la jerarquía.

## Implementación

### Módulo

`cla4.sv` implementa las cuatro ecuaciones con compuertas explícitas y el mismo modelo de retardo del ejercicio 1, de modo que los delays sean comparables. Expone además dos señales agregadas:

```
PG = p3·p2·p1·p0                              el bloque entero propaga
GG = g3 + p3·g2 + p3·p2·g1 + p3·p2·p1·g0      el bloque entero genera
```

que cumplen la misma recursión un nivel más arriba. **Ninguna de las dos depende de `cin`**, así que se calculan mientras el acarreo todavía no llegó — eso es lo que hace posible la jerarquía.

`cla16.sv` encadena cuatro bloques con un segundo nivel de lookahead que aplica la recursión sobre `PG_k` y `GG_k`. El acarreo de entrada de cada bloque **no viene del bloque anterior**: se calcula en paralelo desde ese segundo nivel, lo que elimina el ripple entre bloques. El `cout` de cada `cla4` queda deliberadamente sin conectar, porque el acarreo que importa es el que ya calculó el nivel superior, disponible antes.

Profundidad resultante: 1 TG (`g`,`p`) + 2 TG (`PG`,`GG`) + 2 TG (lookahead de nivel 2) + 2 TG (acarreos internos) + 1 TG (suma) = **8 TG**, contra 32 TG del RCA de 16 bits.

### Test Bench

Casos de borde sobre `cla4` y `cla16`, más los 1000 vectores aleatorios que pide el enunciado. Además de comparar contra el operador `+` del simulador, hace **verificación cruzada contra el RCA del ejercicio 1**: ambas arquitecturas deben coincidir para el mismo estímulo. Es una comprobación independiente, porque un error en el modelo de referencia no puede afectar a las dos por igual.

La medición de delay reporta **dos caminos distintos**, y esto es deliberado:

- **`cin → cout`**: el CLA da 2 TG contra 32 del RCA (16×). Pero es una comparación sesgada — en un datapath real `cin` suele estar disponible antes que los operandos.
- **`operandos → cout`**: el camino que efectivamente fija Fmax cuando el sumador está entre registros. Acá la ventaja es 6.4×.

Reportar solo el primero infla la ventaja del CLA por un factor de 2.5.

Verifiqué que el chequeo es real quitando un término de la ecuación de `c3` (`p2·p1·g0` → `p2·g0`): el testbench lo detecta en los vectores aleatorios, y la verificación cruzada contra el RCA lo marca por separado.

## Resultados

```
--- 1000 vectores aleatorios sobre cla16 ---
  1000 vectores sin discrepancias
  cla16 y rca16 coinciden en todos los casos

   Camino               RCA 16    CLA 16    mejora
   -------------------  --------  --------  --------
   cin -> cout             32 TG      2 TG    16.0x
   operandos -> cout       32 TG      5 TG     6.4x

 RESULTADO: PASS - 1007 casos sin discrepancias
```

| Arquitectura | Delay (operandos → cout) | Profundidad | Crecimiento |
|---|---|---|---|
| RCA 16 | 32 TG | lineal | 2N |
| CLA 16 jerárquico | 5 TG | constante por nivel | ~log N |

### Discusión: dónde gana el CLA

**Gana cuando el ancho crece.** Con N = 4 la diferencia es marginal; a 16 bits ya es 6.4×, y la brecha se ensancha porque el RCA suma 2 TG por bit mientras el CLA suma 2 TG por *nivel de jerarquía*. Pasar de 16 a 64 bits agrega 96 TG al RCA y apenas 2 TG al CLA (un tercer nivel de lookahead).

**Gana cuando el delay es el recurso escaso.** El costo es área y ruteo: cada bloque necesita la red de AND-OR completa, con compuertas de fan-in creciente, y el segundo nivel agrega su propia red. En un bloque no crítico el RCA sigue siendo la elección correcta.

**No gana si el fan-in real se descompone.** El modelo de retardo usado asume que un AND de 5 entradas cuesta un nivel de lógica. En una biblioteca real ese fan-in se descompone en un árbol y agrega niveles, de modo que la ventaja medida acá es una cota optimista. La conclusión cualitativa —el CLA escala mucho mejor— se mantiene; el factor exacto depende de la tecnología.