# Ejercicio 4 - FSM Detector de Secuencia 101

## Enunciado

Implementar una FSM Moore que detecte la secuencia binaria "101" en una entrada serial x. Cuando se detecta el patrón:

- La salida `y` se pone en 1 durante UN ciclo de clock.
- El detector se solapa: el último "1" de una detección puede ser el primer "1" de la siguiente.

Ejemplo: x="110101", y="000101" (dos detecciones, ciclos 4 y 6)

Mínimo: usar 4 estados (S0, S1, S10, S101). Diagrama de transiciones obligatorio.

## Datos

- 1 bit de entrada, 1 bit de salida
- Reset asíncrono activo-bajo
- Codificación: a elección (binary, one-hot)
- Patrón Moore: y=f(estado), no f(x)

## Entregar
- detector_101.v (3 always: registro + próximo-estado + salida)
- tb_detector_101.v con secuencia "11010110101"
- Diagrama de estados
- Verificación: contar detecciones esperadas vs obtenidas
- report.md: Breve, con secciones: motivación, implementación (módulo y TB) y resultados.

## Tip

Estado S101 detecta - y=1 ahí. Para overlap, S101 con x=1 va a S1 (NO a S10), porque el último "1" inicia una nueva búsqueda
