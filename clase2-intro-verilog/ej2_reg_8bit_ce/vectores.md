# Tabla

| # | Qué verifica | `rst_n` | `ce` | `d` | `q` esperado | Patrón |
|:--:|---|:--:|:--:|:--:|:--:|:--:|
| 1 | Reset inicial fuerza `q = 00` (con `ce=1` y `d≠0`, para probar que domina) | 0 | 1 | h55 | h00 | asincrono |
| 2 | Escritura con `ce=1`: `q` toma `d` | 1 | 1 | h22 | h22 | normal |
| 3 | Segunda escritura con otro valor: descarta que `q` quede pegado | 1 | 1 | hC4 | hC4 | normal |
| 4 | Hold, ciclo 1: `ce=0`, `d` cambia, `q` no | 1 | 0 | h11 | hC4 | repeticion |
| 5 | Hold, ciclo 2: `d` cambia de nuevo, `q` sigue igual | 1 | 0 | hCF | hC4 | repeticion |
| 6 | Hold, ciclo 3: confirma que no se actualiza cada N ciclos | 1 | 0 | hCC | hC4 | repeticion |
| 7 | Re-habilitación: sube `ce`, `q` toma el `d` **actual** (no el de cuando bajó `ce`) | 1 | 1 | hAA | hAA | normal |
| 8 | Borde inferior: `d = 8'h00` con `ce=1` | 1 | 1 | 0 | 0 | normal |
| 9 | Borde superior: `d = 8'hFF` con `ce=1` | 1 | 1 | FF | FF | normal |
| 10 | Reset en caliente **asíncrono**: baja entre flancos y actúa sin esperar reloj | 0 | 1 | h77 | h00 | asincrono |