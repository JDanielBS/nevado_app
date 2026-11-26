## **Documentación inicial del proyecto**

### ***Problemática***

El Parque Nacional Natural Los Nevados recibe miles de visitantes en alta montaña, un entorno sin red eléctrica, sin señal celular y sin internet. Los visitantes necesitan orientación (rutas, seguridad, normas, clima, fauna y flora, emergencias), pero hoy no cuentan con un medio que se la entregue de forma continua y personalizada en el sitio. Las soluciones basadas en la nube no funcionan allí, y la atención humana no alcanza para tantas personas.

### ***Requisito principal***

Desarrollar un **asistente de inteligencia artificial que funcione sin conexión a internet** (con o sin red, según haya cobertura) y que oriente a los visitantes del parque en alta montaña.

### ***Restricciones del entorno***

* No hay red eléctrica en el terreno.  
* No hay señal ni internet.  
* Se espera atender a miles de visitantes.

### ***Enfoque preliminar***

Una aplicación descargable antes de la visita, con el modelo y la información del parque almacenados en el dispositivo del usuario. Esto permite responder sin conexión y, cuando haya internet, actualizar contenidos o conectarse a servicios en la nube.

# **Matriz de requisitos (versión 3\)**

**Prioridad:** Esencial / Deseable / Opcional. **Estado:** Confirmado / Por validar.

**Cambios respecto a la versión 2:** modificados RF-04, RF-05b, RM-01, RM-03, RE-02, RE-03, RS-01, RS-02, RN-03 y RN-04; nuevos RF-05c, RF-07, RD-04, RD-05, RM-04, RM-05, RN-05 y RN-06.

| ID | Categoría | Requisito | Prioridad | Estado |
| ----- | ----- | ----- | ----- | ----- |
| RF-01 | Funcional | Responder preguntas del visitante en lenguaje natural sobre el parque | Esencial | Confirmado |
| RF-02 | Funcional | Funcionar 100 % sin conexión a internet | Esencial | Confirmado |
| RF-03 | Funcional | Brindar información con o sin internet según haya cobertura | Esencial | Confirmado |
| RF-04 | Funcional | Dar acceso rápido a emergencias (contactos, protocolos, mal de altura, puesto de guardaparques más cercano), sin depender del modelo | Esencial | Confirmado |
| RF-05a | Funcional | Mostrar el mapa del parque descargado en el dispositivo | Deseable | Por validar |
| RF-05b | Funcional | Mostrar las coordenadas GPS del visitante, copiables para dictarlas a un guardaparques, sin internet | Esencial | Por validar |
| RF-05c | Funcional | Mostrar la ubicación del visitante sobre el mapa | Deseable | Por validar |
| RF-06 | Funcional | Soportar español e inglés | Deseable | Confirmado |
| RF-07 | Funcional | Nivel 0 incluido en la instalación base (menos de \~50 MB): emergencias, normas, contactos y búsqueda por palabras clave, sin modelo | Esencial | Confirmado |
| RD-01 | Datos | Almacenar la base de conocimiento del parque en el dispositivo | Esencial | Confirmado |
| RD-02 | Datos | Mantener el contenido separado del modelo para actualizarlo sin reinstalar | Esencial | Confirmado |
| RD-03 | Datos | Usar fuentes oficiales identificables, con versión y fecha | Esencial | Confirmado |
| RD-04 | Datos | Cada dato operativo (acceso, volcán, clima, cierres) lleva fecha de vigencia y fecha visible. El asistente nunca afirma el estado actual: dice "según el dato del \[fecha\]" | Esencial | Confirmado |
| RD-05 | Datos | Verificar la integridad (checksum) del modelo y del contenido, y poder revertir una actualización fallida | Esencial | Por validar |
| RM-01 | Modelo de IA | Ejecutar un modelo ligero en el dispositivo. El modelo y el nivel se eligen según la RAM detectada y las pruebas, no por tamaño de parámetros | Esencial | Confirmado |
| RM-02 | Modelo de IA | Basar las respuestas en la información del parque para reducir invenciones | Esencial | Confirmado |
| RM-03 | Modelo de IA | Remitir a guardaparques o protocolos oficiales cuando la búsqueda no supere un umbral de similitud calibrado | Esencial | Confirmado |
| RM-04 | Modelo de IA | Respuestas extractivas por defecto: mostrar el fragmento oficial con fuente y fecha, y el modelo solo reformula. Todo número o fecha de una respuesta debe aparecer en los fragmentos recuperados, o se oculta | Esencial | Confirmado |
| RM-05 | Modelo de IA | Bloquear la generación en temas críticos (dosis de medicamentos, "¿puedo subir hoy?") y detectar intención de emergencia en español e inglés, incluida la jerga ("soroche") | Esencial | Confirmado |
| RE-01 | Dispositivo y energía | Tener bajo consumo de batería (no hay red eléctrica) | Esencial | Confirmado |
| RE-02 | Dispositivo y energía | La gama mínima es resultado de las pruebas (RAM, procesador, almacenamiento). Se detecta en ejecución y se degrada al Nivel 0 o a un modelo menor | Esencial | Por validar |
| RE-03 | Dispositivo y energía | Ser legible y operable al aire libre y con frío: uso con guantes, contraste alto bajo sol o nieve y tamaño de texto ajustable | Deseable | Confirmado |
| RS-01 | Distribución | Descarga previa a la visita (tienda de apps, QR, wifi en la entrada) y, si es posible, hotspot local en el centro de visitantes, con descarga por niveles | Esencial | Por validar |
| RS-02 | Distribución | Actualizar contenidos cuando haya conexión | Esencial | Confirmado |
| RN-01 | No funcional | Evitar que respuestas erróneas en temas críticos pongan en riesgo al visitante | Esencial | Confirmado |
| RN-02 | No funcional | Ofrecer interfaz simple, con botones grandes y uso con guantes | Deseable | Confirmado |
| RN-03 | No funcional | Soportar miles de visitantes: es un tema de distribución y soporte, no de servidor, porque cada uno usa su copia local | Esencial | Confirmado |
| RN-04 | No funcional | Procesar ubicación y uso en el dispositivo, sin telemetría por defecto | Deseable | Por validar |
| RN-05 | No funcional | Mostrar un aviso visible de que la app orienta y no reemplaza a guías ni a Parques Nacionales Naturales | Esencial | Confirmado |
| RN-06 | No funcional | Evaluar el asistente con un set de 100-150 preguntas en español e inglés (50 críticas). Criterio de aprobación: cero fallos en las críticas | Esencial | Por validar |

## **Supuestos a confirmar**

* Qué dispositivos usan realmente los visitantes.  
* Qué información oficial del parque está disponible y en qué formato.  
* Quién valida y mantiene el contenido operativo del parque, y cada cuánto cambia.  
* Protocolo de emergencia sin señal acordado con Parques Nacionales (puestos de guardaparques, refugios, radio).  
* Revisión médica del contenido sobre mal de altura.  
* Si existe wifi en la entrada del parque y cobertura celular real por sector (para un hotspot local o actualizaciones).  
* Si hay cartografía del parque de calidad suficiente para el mapa offline (RF-05a, RF-05c).  
* Si se guardarán o enviarán datos de ubicación en algún momento (RN-04 y Ley 1581 de 2012).  
* Si iOS está dentro del alcance (si sí, hay que probar en iPhone).

# **Estrategia actual**

1. **Nivel 0 empaquetado en la app** (menos de \~50 MB): emergencias, normas, contactos y búsqueda por palabras clave. Funciona sin modelo.  
2. **Datos con caducidad:** cada dato operativo lleva fecha de vigencia, y el asistente nunca afirma el estado actual del parque.  
3. **RAG offline con respuestas extractivas:** el conocimiento del parque en una base local. Se muestra el fragmento con fuente y fecha, y el modelo solo reformula. Si la búsqueda no supera el umbral de similitud, se dice "no sé" y se remite a un guardaparques.  
4. **Modelo pequeño cuantizado como descarga opcional.** Candidatos a evaluar: Gemma 4 E2B, Gemma 3 1B y Qwen3, con un set de preguntas propio en español e inglés.  
5. **Motor LiteRT-LM, con CPU por defecto.** La GPU se usa solo en una lista blanca de celulares probados.  
6. **Niveles según la RAM detectada**, no según el tamaño del modelo: Nivel 0 siempre, modelo pequeño si el celular lo soporta y modelo mayor solo en equipos probados.  
7. **Respuestas cortas y contexto limitado**, diseñando para una velocidad modesta (meta de diseño de \~5-10 tokens por segundo, a medir) y con streaming en pantalla.  
8. **Coordenadas GPS y emergencias fijas**, sin pasar por el modelo.  
9. **Prototipo y pruebas primero:** modelo de \~1-2 GB con RAG sobre pocos documentos, medido en 3-4 celulares reales.

# **Estrategias descartadas o pospuestas**

| Estrategia | Por qué se dejó fuera | Cuándo traerla de vuelta |
| ----- | ----- | ----- |
| **Modelos de 3-4B** (Phi-4 Mini, Gemma 3n/4 E4B, Llama 3.2 3B) | Pesan 2.5-4.5 GB y pueden fallar o ir lentos en gama media | Solo si la calidad del modelo de \~2B no alcanza, para gama alta |
| **Cuantización avanzada** (AWQ, SpinQuant, MobileQuant) | Con 4 bits estándar basta para empezar | Si el modelo no cabe o la calidad en español cae mucho |
| **Ajuste fino (LoRA/QLoRA)** | Solo se usa si hace falta. Con .litertlm habría que fusionar y reconvertir el modelo | Si las respuestas no tienen el estilo o la exactitud esperados |
| **Destilación con datos sintéticos** | Más trabajo y no es necesaria al inicio | Si se quiere un modelo pequeño especializado en el parque, en español e inglés |
| **Decodificación especulativa (MTP y propias)** (Lever, EdgeLLM) | No se confirmó que el paquete de Flutter la exponga, y rinde más en GPU, que puede ser inestable | Si la velocidad no alcanza y se confirma que funciona en el paquete |
| **Compresión del KV cache** (KIVI, TierKV, DynaKV) | Puede reducir la fidelidad en RAG | Si el contexto largo agota la memoria, y tras medir la calidad |
| **Otros motores** (llama.cpp, MLC LLM, ExecuTorch, ONNX Runtime Mobile, Cactus) | Con LiteRT-LM basta para empezar | Si un modelo no tiene buen soporte allí o falla en ciertos celulares |
| **Modo híbrido con nube** (HyCo, Synera) | El núcleo del proyecto es funcionar sin conexión | Si hay zonas con cobertura y se quieren respuestas más potentes allí |
| **Caché de respuestas frecuentes** (PerCache) | Es una optimización menor para el inicio | Si se repiten muchas preguntas y se quiere ahorrar batería |
| **RAG más avanzado** (EdgeRAG, MeMemo, índices optimizados) | Un RAG simple basta con pocos documentos | Si la base de conocimiento crece mucho o la búsqueda es lenta |
| **Búsqueda híbrida BM25 \+ vectorial** | El Nivel 0 por palabras clave ya cubre parte de la necesidad | Si la búsqueda falla con nombres propios o términos exactos |
| **Plan B en Kotlin nativo** | Se envuelve el motor tras una interfaz propia, sin gastar tiempo ahora | Si el paquete de Flutter falla o deja de mantenerse |
| **Hotspot local y descarga por niveles** | Depende de infraestructura sin confirmar | Antes de un piloto real con visitantes |
| **Carga del modelo solo bajo demanda** | Simplifica el prototipo | Si la batería o la memoria se vuelven un problema |

La mayoría se activa según lo que se mida en el prototipo: si falla la **calidad**, vuelven el ajuste fino, los modelos de 3-4B o un RAG más avanzado; si falla la **velocidad o la memoria**, vuelven la cuantización avanzada, la compresión del KV cache y los otros motores.

# **Stack final (Flutter)**

| Capa | Elección | Nota |
| ----- | ----- | ----- |
| **App** | Flutter 3.47.x fijado (por ejemplo con FVM) | No actualizar a versiones nuevas durante el hackatón |
| **Núcleo de IA** | `flutter_edge_ai` (^2.6.0 o superior) | Antes llamado `flutter_gemma` (renombrado, no descontinuado) |
| **Motor del LLM** | `flutter_edge_ai_litertlm` (^1.20.0 o superior) | Corre archivos `.litertlm` |
| **Modelo** | Por decidir tras las pruebas: Gemma 4 E2B (2.58 GB), Gemma 3 1B (\~0.6 GB) o Qwen3 | Se elige con un set de preguntas propio en español e inglés |
| **Nivel 0** | Contenido empaquetado en la app \+ búsqueda por palabras clave | Herramienta por definir |
| **Embeddings** | EmbeddingGemma 2 texto (270M, `.litertlm`) | Trae su propio tokenizador. Precalcular el índice en PC con el mismo perfil |
| **RAG** | `flutter_edge_ai_rag` \+ `flutter_edge_ai_sqlite` | Alternativa: `flutter_edge_ai_qdrant` (solo nativo) |
| **Medición de memoria** | `flutter_edge_ai_diagnostics` | Para detectar la RAM y definir la gama mínima |
| **GPS** | `geolocator` 14.x | Las coordenadas pasan a ser requisito Esencial |
| **Mapas offline (fase 2\)** | `flutter_map` \+ MBTiles | Sin paquete consolidado, se evalúa después |
| **Descargas** | Incluidas en el núcleo | Con checksum y reanudación |

No hacen falta: `flutter_edge_ai_embeddings`, MediaPipe, Genkit ni el paquete de voz.

# **Restricciones y detalles clave**

## **Compatibilidad**

* **Android:** `minSdk 30` (Android 11\) y solo `arm64-v8a`. El límite real será la RAM y el procesador, que se detectan en ejecución.  
* **iOS:** mínimo 15.0 y pods enlazados de forma estática (solo si está en el alcance).  
* **Flutter:** 3.47 es estable, así que `flutter_edge_ai_sqlite ^2.1` no genera conflicto. Fijar 3.47.x.

## **Configuración**

* Permiso INTERNET en el manifiesto de release, si no, el modelo no se descarga.  
* `fileType` debe ser `ModelFileType.litertlm`.  
* Usar `openChat` (`createChat` está obsoleto) y `Message.isUser: true` en los mensajes del usuario, o la respuesta sale vacía.  
* `maxTokens` es toda la ventana de contexto. Usar 2,048-3,072, con 2-3 fragmentos de 150-300 tokens e historial de 1-2 turnos.  
* Decodificación determinista (`topK: 1`), configurada al cargar el modelo, y razonamiento ("thinking") apagado.  
* Los modelos con acceso restringido en Hugging Face piden aceptar la licencia y pasar un token, sin dejarlo en el código.

## **Dependencias**

* Todos los paquetes `flutter_edge_ai_*` se actualizan juntos.  
* Primera compilación con internet: `sqlite-vec` se descarga desde GitHub. Es en el equipo de desarrollo, no en el celular.  
* Riesgo: un solo publicador, poca adopción y cambios frecuentes. Fijar versiones exactas, guardar el `pubspec.lock`, envolver el motor y el retriever en interfaces propias y verificar al arrancar que el índice no esté vacío.

## **Rendimiento y seguridad**

* La referencia de \~47-52 tokens/s es de un Galaxy S26 Ultra (gama muy alta). Diseñar para una velocidad mucho menor y medir en celulares reales.  
* GPU apagada por defecto: usar CPU y activar la GPU solo en celulares probados.  
* La descarga de un modelo grande (\~2.5 GB) depende de wifi previo o de un hotspot local. Un modelo de \~1 GB reduce el problema.  
* La predicción multi-token (MTP) no es base de viabilidad.  
* Ajuste fino: se pospone. Habría que fusionar y reconvertir el modelo a `.litertlm`.

# **Plan de pruebas inicial**

1. **Humo en 3-4 celulares reales** (gama baja, media y alta, más un iPhone si iOS está en el alcance): 10 turnos con RAG de \~1,500 tokens, CPU frente a GPU. Medir tiempo al primer token, tokens por segundo, RAM pico, cierres por memoria y temperatura.  
2. **Frío y batería:** 20 respuestas a \~0 °C frente a 20 °C. Medir el porcentaje de batería por respuesta, apagados y uso con guantes.  
3. **Calidad y seguridad:** 100-150 preguntas en español e inglés, 50 de ellas críticas (mal de altura, rutas, normas, emergencias, trampas como "¿qué dosis tomo?"). Medir recall@3, "no sé" correcto, alucinaciones y números exactos. Aprobación: cero fallos en las críticas.
