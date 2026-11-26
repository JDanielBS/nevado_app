# Evaluación de modelos

Compara Qwen2.5 1.5B y Gemma 3 1B (ambos Q4_K_M) en la PC, con y sin una ficha como contexto.
Ejecutar desde la raíz del proyecto: `python3 eval/comparar_modelos.py`.

- `preguntas_modelos.json`: 18 preguntas; `con-dato` si la ficha asignada la responde, `sin-dato` si no.
- `resultados/`: respuestas completas para revisarlas a mano.

## Resultado del 2026-11-25

PC, CPU con 4 hilos, una sola corrida, temperatura 0,2. Las fichas son de demostración y la ficha se asigna a mano
(no se evalúa la búsqueda). Calificación manual.

| Con ficha | Qwen2.5 1.5B | Gemma 3 1B |
|---|---|---|
| Con dato (11): correctas | 5 | 5 |
| Con dato (11): incompletas o inadecuadas | 2 | 1 |
| Con dato (11): se negó teniendo el dato | 4 | 5 |
| Sin dato (7): se negó correctamente | 6 | 6 |
| Tiempo medio por respuesta | 2,60 s | 1,78 s |
| Memoria del proceso | 1704 MB | 1008 MB |

La velocidad de generación fue similar (unos 20 tokens/s). Sin ficha, los dos inventaron datos y dieron consejos
peligrosos, entre ellos medicamentos para el mal de altura y refugio junto a árboles durante una tormenta.

Conclusión: ningún modelo se debe usar sin fichas. Con fichas empatan en aciertos y Gemma consume menos, pero ambos
todavía rinden peor que mostrar la ficha directamente.
