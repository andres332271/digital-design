# Informe Ejercicio 5 - Multiplicador de Booth radix-2

## Motivación

El ejercicio 4 optimiza la multiplicación por una constante conocida en tiempo de diseño, que puede recodificarse fuera de línea. Cuando el multiplicador es un operando variable esa vía no sirve: hay que recodificar sobre la marcha con lógica local. Booth radix-2 hace eso examinando pares de bits solapados (`dᵢ = bᵢ₋₁ − bᵢ`, con `b₋₁ = 0`): `01` suma el multiplicando, `10` lo resta, `00` y `11` no operan.

## Implementación

### Módulo

`booth_radix2.sv` es secuencial: FSM de tres estados (`IDLE`/`CALC`/`DONE`) sobre el registro desplazable `[A:Q:Q₋₁]`. Cada ciclo evalúa el par `(Q[0],Q₋₁)`, aplica la acción sobre el acumulador y desplaza aritméticamente el conjunto; tras N iteraciones `{A,Q}` contiene el producto.

### Test Bench

`tb_booth_radix2.sv` encapsula el handshake en la tarea `multiplicar()` (pulso de `start`, espera de `done`), de modo que el resto del banco queda independiente del protocolo. Los estímulos se aplican en **flanco descendente** mientras el DUT registra en el ascendente, para que las señales estén estables al muestrearse. Corre tres bloques: el caso del enunciado con traza ciclo a ciclo de `A`/`Q`/`Q₋₁` (accediendo por ruta jerárquica a las señales internas), los casos límite con multiplicando `−8`, y el barrido exhaustivo de los 256 pares.

Verifiqué que el chequeo es real con cuatro mutantes: acumulador de N bits, desplazamiento lógico, `b₋₁=1` y sumar/restar intercambiados. Los cuatro se detectan, pero **solo el primero necesita el barrido exhaustivo** — los otros tres ya fallan en el caso del enunciado.

## Resultados

```
    ciclo 0 | par (1,0) -> restar  | A=00000 Q=1011 Q_1=0
    ciclo 1 | par (1,1) -> ninguna | A=11101 Q=0101 Q_1=1
    ciclo 2 | par (0,1) -> sumar   | A=11110 Q=1010 Q_1=1
    ciclo 3 | par (1,0) -> restar  | A=00010 Q=0101 Q_1=0
  producto = -30  (11100010)
 RESULTADO: OK - sin discrepancias
```

Los 256 pares coinciden con la referencia, incluidos `−8·−8=64` y `−8·7=−56`. Los dígitos recodificados `(−1,+1,0,−1)` evalúan `−8+4+0−1 = −5 = B`, confirmando la recodificación.

En la forma de onda se ve `m_reg=0x18` (`−8` extendido a 5 bits) durante el caso límite, el signo replicándose en cada ASR (`1A`→`1D`, `1C`→`1E`), y `product` con valores intermedios sin sentido hasta que sube `done`: la salida solo es válida en ese instante, como fija el protocolo.