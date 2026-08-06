# Tabla

| # | Qué verifica | `rst` | `en` | `cnt` esperado | `tc` esperado | Patrón |
|:--:|---|:--:|:--:|:--:|:--:|:--:|
| 1 | Reset inicial pone `cnt = 0` y `tc = 0` | 0 | 1 | 0 | 0 | N |
| 4 | Conteo normal: primer incremento con `en=1` | 0 | 1 | 1 | 0 | N |
| 5 | Conteo normal: segundo incremento | 0 | 1 | 2 | 0 | N |
| 2 | Reset **síncrono**: aplicado entre flancos, `cnt` NO cambia todavía | 1 | 1 | 2 | 0 | A |
| 3 | Reset síncrono: en el flanco siguiente sí actúa, `cnt = 0` | 1 | 1 | 0 | 0 | N |
| 6 | Al llegar a 9, `tc` se pone en 1 | 0 | 1 | 9(luego de 9 ciclos) | 1 | N |
| 7 | Rollover: en el flanco siguiente `cnt` vuelve a 0 y `tc` baja | 0 | 1 | 0 | 0 | N |
| 8 | Conteo normal: primer incremento con `en=1` luego del rollover| 0 | 1 | 1 | 0 | N |
| 9 | Hold: con `en=0`, `cnt` no cambia durante varios ciclos | 0 | 0 | 1  | 0 | R |
| 10 | Con `cnt = 9` y `en = 0`: `tc` baja aunque la cuenta siga en 9 | 0 | 0 | 9 | 0 | N |
| 11 | Barrido: 100 ciclos con `en=1` → exactamente 10 pulsos de `tc` | 0 | 1 | 10 pulsos | 10 pulsos | R |