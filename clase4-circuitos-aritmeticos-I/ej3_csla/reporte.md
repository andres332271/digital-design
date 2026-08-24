# Informe Ejercicio 3 - CSLA de 16 bits por bloques de 4

## Motivación

El CLA del ejercicio 2 ataca la cadena de acarreo con álgebra: calcula los acarreos sin esperarlos. El Carry Select toma un camino distinto —**especulación**— que no requiere ninguna reformulación algebraica.

Cada bloque calcula su resultado **dos veces en paralelo**: una suponiendo que el acarreo entrante será 0 y otra suponiendo que será 1. Cuando el acarreo real llega, un multiplexor elige cuál de las dos respuestas era la correcta. El costo de esperar el acarreo deja de ser el delay de una suma completa y pasa a ser el delay de un mux.

## Implementación

### Módulo

`rca4.sv` es el sumador interno y `csla16.sv` arma los cuatro bloques. Cada bloque instancia dos `rca4` con `cin` cableado a 0 y a 1, y multiplexa sumas y acarreo con el `sel` que llega del bloque anterior.

El sumador interno es un RCA y no un CLA de forma deliberada: **la ventaja del CSLA no viene de acelerar la suma dentro del bloque**, sino de que esa suma ya esté hecha cuando llega el acarreo. Con bloques de 4 bits, un RCA interno tiene delay suficientemente bajo y área mínima.

El multiplexor se describe con compuertas (`not`, dos `and`, `or` → 2 TG) en lugar de un operador ternario, para que su retardo participe de la medición. Sin eso la comparación no sería justa: el mux **es** el camino crítico entre bloques.

Profundidad resultante: 9 TG del `rca4` del bloque 0, más 2 TG por cada uno de los tres muxes en cascada = **15 TG**.

### Test Bench

Casos de borde y 1000 vectores aleatorios, con **verificación cruzada entre las tres arquitecturas**: RCA, CLA y CSLA instanciadas en el mismo banco, con el mismo estímulo, deben coincidir. Eso permite completar la tabla comparativa sin estimaciones — los tres números salen de la misma simulación y el mismo modelo de retardo.

La medición usa el camino `operandos → cout`, el que fija Fmax entre registros, con el acarreo naciendo en el bit 0 y obligado a alcanzar el bit 15.

Verifiqué que el chequeo es real forzando el `sel` de los muxes a 0 (el CSLA elige siempre la respuesta de `cin=0`): falla desde el segundo caso de borde, y la verificación cruzada lo marca por separado.

## Resultados

```
--- 1000 vectores aleatorios ---
  1000 vectores sin discrepancias
  las tres arquitecturas coinciden en todos los casos

   Arquitectura   delay        full adders   comentario
   ------------  -----------  ------------  ------------------
   RCA  16          32 TG              16   cadena completa
   CSLA 16 (4x4)    15 TG              28   RCA4 + 3 muxes
   CLA  16 (4x4)     5 TG               -   lookahead 2 niveles

 RESULTADO: PASS - 1005 casos sin discrepancias
```

| Arquitectura | Delay | Full adders | Lógica extra | Delay × área |
|---|---|---|---|---|
| RCA 16 | 32 TG | 16 | — | 512 |
| CSLA 16 (4×4) | 15 TG | 28 | 15 muxes | 420 |
| CLA 16 (4×4) | 5 TG | — | red AND-OR de 2 niveles | — |

El CSLA es **2.13× más rápido que el RCA** a costa de un 75 % más de full adders, y el CLA es **3× más rápido que el CSLA**.