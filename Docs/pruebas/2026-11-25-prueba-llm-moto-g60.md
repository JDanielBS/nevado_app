# Prueba de modelos en Moto G60 (2026-11-25)

## Resumen

- Gemma 3 1B q4 sigue siendo el candidato para continuar: 5 correctas, 1 incompleta y 1 fallo, con buena velocidad y poca memoria.
- Qwen3 0.6B `dynamic INT4`: 4 correctas, 2 incompletas y 1 fallo. Más lento.
- Qwen3.5 0.8B `int8`: 3 correctas, 4 incompletas o contradictorias y ningún fallo total. Fue el que mejor respondió sobre soroche, pero tarda de 33 a 44 s en recargar antes de cada pregunta y usa hasta 1.8 GB.
- Qwen3 1.7B `dynamic INT4`: 5 correctas, 2 incompletas y ningún fallo, pero no es viable en este teléfono: hasta 173 s por respuesta.
- Ningún modelo respondió de forma completa la pregunta sobre soroche.
- Sin texto de apoyo, Qwen3 0.6B dio información falsa sobre el mal de altura.
- La prueba de Qwen3 `mixed INT4` no es válida: ese archivo tiene un defecto conocido.

Son 7 casos con textos inventados, una pasada con Gemma, Qwen3.5 y Qwen3 1.7B, y dos con Qwen3 0.6B `dynamic INT4`. No sirve para aprobar un modelo (RN-06 pide 100 a 150 preguntas).

## Entorno

| Elemento | Valor |
|---|---|
| Teléfono | Moto G60, Android 12, arm64, 3.7 GB de RAM total, cerca de 1.1 GB disponibles antes de la prueba |
| App | Flutter 3.47.9, release, CPU, `topK: 1`, `maxTokens: 2048` |
| Paquetes | `flutter_edge_ai` 2.7.2, `flutter_edge_ai_litertlm` 1.21.3 (librerías nativas v0.19.1-c) |
| Velocidad | Fragmentos de streaming por segundo, aproximadamente tokens por segundo |

## Corrida 1: preguntas sin texto de apoyo

Modelo: Qwen3 0.6B `dynamic INT4` (345 MB).

| Métrica | Resultado |
|---|---|
| Descarga | 22 s |
| Carga | 5.9 s |
| Primer token | 3.2 a 4.1 s |
| Velocidad | 4.2 a 4.3 frag/s |
| RAM máxima de la app | 1163 MB |

| Pregunta | Calidad |
|---|---|
| Qué es el mal de altura y sus síntomas | Falsa: lo asocia a altura "imposible o muy baja" y lo llama "mal de la espuma" |
| Tengo soroche y me duele la cabeza | No reconoce "soroche". No indica descender ni pedir ayuda |
| Qué ropa llevar | Repite en bucle "Ropa de lucha o protección" |
| Hora de cierre (con el dato en la pregunta) | Correcta |

## Corrida 2: preguntas con texto de apoyo

Máximo 150 tokens de respuesta. Instrucción: responder en máximo 3 frases, solo con el texto, y decir "No sé, consulta a un guardaparques." si no está la respuesta.

| Métrica | Gemma 3 1B q4 (584 MB) | Qwen3 `mixed INT4` (498 MB) |
|---|---|---|
| Descarga | 39 s | 35 s |
| Carga | 10.5 s | 8.1 s |
| Primer token, entrada de 100 a 190 tokens | 2.7 a 5.6 s | no válido |
| Primer token, contexto largo (1119 tokens según Gemma) | 21.7 s | no válido |
| Velocidad | 6.3 a 7.1 frag/s | no válido |
| RAM máxima | 1132 MB | 1650 MB |

| Caso | Gemma 3 1B |
|---|---|
| Síntomas del mal de altura | Incompleto: omite cansancio y dificultad para dormir |
| Soroche y dolor de cabeza | **Falla:** "No sé, consulta al guía." |
| Ropa | Correcto |
| Hora de cierre | Correcto |
| Pregunta sin respuesta en el texto | Se abstiene |
| Dosis de medicamento | Se abstiene |
| Hora de cierre en contexto largo | Correcto |

No usó la frase exacta de abstención: dio tres variantes.

Batería: 40 % al inicio y al final, 30.9 a 31.5 °C, con el teléfono conectado por USB. No permite concluir nada sobre consumo.

## Corrida 3: Gemma 3 1B frente a Qwen3 `dynamic INT4`

Mismos 7 casos, textos, instrucción y límites de la corrida 2. Los datos de Gemma son los de la corrida 2. Qwen3 `dynamic INT4` (345 MB) se ejecutó dos veces seguidas.

| Métrica | Gemma 3 1B q4 | Qwen3 pasada 1 | Qwen3 pasada 2 |
|---|---|---|---|
| Carga del modelo | 10.5 s | 2.6 s | 2.9 s |
| Primer token, contexto corto | 2.7 a 5.6 s | 3.1 a 7.9 s | 3.2 a 6.3 s |
| Primer token, contexto largo | 21.7 s | 34.9 s | 35.2 s |
| Tokens del contexto largo | 1119 | 1461 | 1461 |
| Velocidad | 6.3 a 7.1 frag/s | 4.0 a 4.2 frag/s | 4.1 a 4.2 frag/s |
| RAM máxima, contexto corto | 1132 MB | 1073 MB | 1097 MB |
| RAM máxima, contexto largo | 998 MB | 1377 MB | 1433 MB |

Tiempos totales por caso, en segundos:

| Caso | Gemma | Qwen3 pasada 1 | Qwen3 pasada 2 |
|---|---|---|---|
| Síntomas | 16.5 | 18.5 | 16.8 |
| Soroche | 4.9 | 11.8 | 11.7 |
| Ropa | 10.4 | 13.2 | 13.2 |
| Hora | 7.6 | 6.2 | 6.3 |
| Sin respuesta | 4.7 | 8.1 | 8.4 |
| Dosis | 5.0 | 8.4 | 9.0 |
| Contexto largo | 25.4 | 37.3 | 37.5 |

Las respuestas de Qwen3 fueron idénticas en las dos pasadas.

| Caso | Respuesta de Qwen3 | Valoración | Gemma |
|---|---|---|---|
| Síntomas | "El mal de altura (soroche) puede aparecer al subir rápido. Síntomas: dolor de cabeza, náuseas, mareo, cansancio y dificultad para dormir." | Correcta | **Incompleta:** omite cansancio y dificultad para dormir |
| Soroche | "¿Qué hago? Deja de subir, descansar y pedir ayuda si tienes el mal de altura." | **Incompleta:** omite descender y avisar al guía | **Fallo:** no responde |
| Ropa | "Para caminar en alta montaña, llevas una capa seca, una capa abrigada y una chaqueta impermeable." | **Incompleta:** omite gorro, guantes, botas, gafas y protector solar | Correcta |
| Hora | "El sendero cierra a las 14:00." | Correcta | Correcta |
| Sin respuesta | "No sé, consulta a un guardaparques." | Correcta | Correcta |
| Dosis | "No sé. Consulta a un guardaparques." | Correcta | Correcta |
| Contexto largo | "No sé, consulta a un guardaparques." | **Fallo:** el dato estaba en el texto | Correcta |

Qwen3 siguió mejor la frase de abstención pedida.

### Límites de la comparación

- Qwen3 `dynamic INT4` ya estaba descargado y se había cargado antes, así que su tiempo de carga puede beneficiarse de caché. El de Gemma fue de primera carga. No son comparables.
- Gemma se midió justo después de otro modelo en la misma ejecución. Qwen3 se midió en una ejecución aparte.
- RAM es la memoria residente del proceso, muestreada durante la generación.
- Antes de la corrida 3: 1.0 GB disponibles, batería 42 % y 30.8 °C. Al final: 42 % y 31.0 °C, conectado por USB.

## Corrida 4: Qwen3.5 0.8B `int8`

No se encontró en `litert-community` un Qwen de 1B. Se usó el más cercano, Qwen3.5 0.8B (Apache 2.0, sin token). Qwen3 1.7B se probó después (corrida 5).

- Archivo: `Qwen3.5-0.8B_int8.litertlm` (965 MB), revisión `7c656dc9e84b135df6b702e54fbe14a05c67abb8`. La [ficha](https://huggingface.co/litert-community/Qwen3.5-0.8B) lo recomienda para CPU con LiteRT-LM 0.19.x.
- `ModelType.qwen35`, razonamiento apagado, mismos casos y límites.
- La ficha exige un motor nuevo por conversación porque el estado recurrente no se reinicia. La app de prueba recargó el modelo antes de cada caso.
- Una sola pasada.

| Métrica | Gemma 3 1B q4 | Qwen3 0.6B | Qwen3.5 0.8B |
|---|---|---|---|
| Tamaño | 584 MB | 345 MB | 965 MB |
| Descarga | 39 s | 22 s | 56 s |
| Carga del modelo | 10.5 s | 2.6 a 2.9 s (con caché probable) | 33 a 44 s, en cada pregunta |
| Primer token, contexto corto | 2.7 a 5.6 s | 3.1 a 7.9 s | 5.2 a 7.3 s (13.2 s en el primer caso) |
| Primer token, contexto largo | 21.7 s | 34.9 a 35.2 s | 33.3 s |
| Velocidad | 6.3 a 7.1 frag/s | 4.0 a 4.2 frag/s | 5.6 a 6.7 frag/s, con dos casos a 1.0 y 1.4 |
| RAM máxima | 1132 MB | 1433 MB | 1797 MB |

La causa de los dos casos lentos de Qwen3.5 no se investigó. La memoria disponible antes de la corrida era de 1.1 GB.

| Caso | Respuesta de Qwen3.5 (resumida) | Valoración | Tiempo de respuesta |
|---|---|---|---|
| Síntomas | Da tres síntomas y la indicación de descender, y agrega "No hay una respuesta en el texto" | **Incompleta y contradictoria** | 65.5 s |
| Soroche | "Deja de subir rápido y descansa. Avisa al guía o guardaparques. Si los síntomas empeoran, descén de inmediato." | **Incompleta:** cambia "dejar de subir" por "dejar de subir rápido" y omite los signos de alarma | 12.6 s |
| Ropa | Lista completa y al final "No sé, consulta a un guardaparques" | **Contradictoria** | 16.0 s |
| Hora | "El sendero de prueba cierra a las 14:00." y datos extra | Correcta | 11.2 s |
| Sin respuesta | Texto no pedido sobre mal de altura y luego "No sé" | **Incompleta:** no se abstiene limpiamente | 11.4 s |
| Dosis | "No sé, consulta a un guardaparques." | Correcta | 7.4 s |
| Contexto largo | Hora correcta y texto extra | Correcta | 74.8 s |

Los tiempos de respuesta no incluyen la recarga del modelo.

### Valoración con el mismo criterio

| Modelo | Correctas | Incompletas o contradictorias | Fallos |
|---|---|---|---|
| Gemma 3 1B q4 | 5 | 1 | 1 |
| Qwen3 0.6B `dynamic INT4` | 4 | 2 | 1 |
| Qwen3.5 0.8B `int8` | 3 | 4 | 0 |

La valoración es manual y de una sola persona evaluadora (Claude). Batería: 42 % al inicio y al final, 31.5 a 32.2 °C, conectado por USB.

## Corrida 5: Qwen3 1.7B `dynamic INT4`

- Archivo: `Qwen3-1.7B_dynamic_wi4b32_afp32.litertlm` (932 MB según la [ficha](https://huggingface.co/litert-community/Qwen3-1.7B)), revisión `c421cc3775575372ac2ca4aa1bebc97300ae36b6`. Apache 2.0, sin token. Pide LiteRT-LM 0.18.0 o superior.
- `ModelType.qwen3`, razonamiento apagado, un solo motor, mismos casos y límites. Una pasada.
- Descarga: 61 s. Carga: 20.3 s.

| Caso | Respuesta | Valoración | Primer token | Velocidad | Total | RAM |
|---|---|---|---|---|---|---|
| Síntomas | "El mal de altura es un síntoma que puede aparecer al subir rápidamente. Sus síntomas incluyen dolor de cabeza, náuseas, mareo, cansancio y dificultad para dormir." | Correcta | 16.9 s | 0.3 frag/s | 172.6 s | 1605 MB |
| Soroche | "Dejá de subir, descansa y avisa al guía. Si los síntomas empeoran, descenderás de inmediato." | **Incompleta:** omite los signos de alarma y pedir ayuda | 18.9 s | 0.3 | 117.8 s | 1430 MB |
| Ropa | "Para caminar en alta montaña, debes llevar: gorro, guantes, botas de caminata, gafas de sol y un ropa impermeable." | **Incompleta:** omite las capas y el protector solar | 20.2 s | 0.4 | 105.7 s | 1463 MB |
| Hora | "El sendero cierra a las 14:00." | Correcta | 8.2 s | 2.4 | 13.6 s | 1505 MB |
| Sin respuesta | "No sé, consulta a un guardaparques." | Correcta | 17.9 s | 2.3 | 22.2 s | 1489 MB |
| Dosis | "No sé, consulta a un guardaparques." | Correcta | 20.8 s | 0.6 | 37.3 s | 1501 MB |
| Contexto largo (1461 tokens) | "El sendero cierra a las 14:00." | Correcta | 71.9 s | 0.3 | 110.6 s | 1594 MB |

La app no se cerró, pero Android estuvo cerrando otros procesos por falta de memoria (`lowmemorykiller`, motivos "PSI critical event" y "thrashing"). Es la explicación probable de la lentitud; no se verificó de forma aislada. Memoria disponible: 1.0 GB antes y 0.57 GB al final. Batería: 42 % a 41 %, 32.4 a 33.5 °C, conectado por USB.

## Comparación general

Mismos 7 casos con texto de apoyo, CPU.

| Métrica | Gemma 3 1B q4 | Qwen3 0.6B INT4 | Qwen3.5 0.8B int8 | Qwen3 1.7B INT4 |
|---|---|---|---|---|
| Correctas / incompletas / fallos | 5 / 1 / 1 | 4 / 2 / 1 | 3 / 4 / 0 | 5 / 2 / 0 |
| Primer token, contexto corto | 2.7 a 5.6 s | 3.1 a 7.9 s | 5.2 a 13.2 s | 8.2 a 20.8 s |
| Primer token, contexto largo | 21.7 s | 34.9 a 35.2 s | 33.3 s | 71.9 s |
| Velocidad, frag/s | 6.3 a 7.1 | 4.0 a 4.2 | 1.0 a 6.7 | 0.3 a 2.4 |
| Total por respuesta | 4.7 a 25.4 s | 6.2 a 37.5 s | 7.4 a 74.8 s | 13.6 a 172.6 s |
| Carga | 10.5 s | 2.6 a 2.9 s (caché probable) | 33 a 44 s por pregunta | 20.3 s |
| RAM máxima | 1132 MB | 1433 MB | 1797 MB | 1605 MB |
| Licencia | `gemma`, con token | Apache 2.0 | Apache 2.0 | Apache 2.0 |

La memoria disponible varió entre corridas, así que las diferencias pequeñas no son concluyentes.

## Por qué Qwen3 `mixed INT4` respondía siempre lo mismo

Respondió "Hello! I'm here to help..." en los 7 casos.

El publicador del modelo documenta que ese archivo tiene una plantilla de chat anterior a LiteRT-LM 0.18. Con LiteRT-LM 0.18.0 y 0.19.0 el motor descarta el mensaje del usuario y procesa 9 tokens sea cual sea la entrada. El archivo se retiró de la rama principal el 2026-11-06 ([ficha del modelo](https://huggingface.co/litert-community/Qwen3-0.6B)). El catálogo de `flutter_edge_ai_litertlm` 1.21.3 todavía lo ofrece, fijado a una revisión anterior.

Coincide con lo observado: misma respuesta, mismo número de fragmentos y un primer token que no crece con el contexto largo.

No usar `qwen3_0_6b.mixedInt4`. La comparación válida es la de la corrida 3, con `dynamicInt4`.

## Decisiones propuestas

1. Seguir con Gemma 3 1B. Qwen3 `dynamic INT4` queda como alternativa sin restricción de acceso (Apache 2.0). Qwen3.5 0.8B se descarta en este teléfono mientras requiera recargar el modelo en cada pregunta, y Qwen3 1.7B por su lentitud.
2. Usar 1 o 2 fragmentos, menos de unos 400 tokens de contexto.
3. Mostrar el fragmento oficial de inmediato y la redacción del modelo después.
4. Responder emergencias y mal de altura con contenido fijo, sin modelo (RF-04, RM-05).
5. Decidir "no sé" con el umbral de búsqueda (RM-03), no leyendo la respuesta del modelo.

## Pendiente

- Condiciones de la licencia `gemma` para uso comercial.
- Distribución de un modelo restringido sin incluir un token en la app.
- Batería y temperatura sin USB, frío.
- Embeddings en memoria junto al modelo.
- GPU en este teléfono.
- Set de preguntas propio.

## Textos y preguntas usados

Textos inventados para la prueba. No son información oficial.

- **Altura:** "El mal de altura (soroche) puede aparecer al subir rápido. Síntomas: dolor de cabeza, náuseas, mareo, cansancio y dificultad para dormir. Qué hacer: dejar de subir, descansar, avisar al guía o guardaparques y descender si los síntomas empeoran. Si hay confusión, dificultad para caminar o para respirar, descender de inmediato y pedir ayuda."
- **Ropa:** "Para caminar en la montaña se recomienda vestir por capas: una primera capa que seque rápido, una capa abrigada y una chaqueta impermeable. Llevar gorro, guantes, botas de caminata, gafas de sol y protector solar."
- **Sendero:** "El sendero de prueba abre a las 06:00 y cierra a las 14:00. Solo se permite el ingreso con guía."
- **Contexto largo:** un párrafo de normas generales repetido, con el texto del sendero en medio y el de altura al final.

La app de prueba es desechable y no está en el repositorio.
