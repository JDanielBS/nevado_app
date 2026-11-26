# Pendientes

> Copia traída del proyecto previo. Las rutas `app_flutter/` y `docs/` corresponden a esa estructura anterior; en este repositorio ver el `README.md`.

Última actualización: 2026-11-25

## Migración a Flutter (2026-11-25)
Hecho:
- [x] Flutter 3.50.1 instalado en `~/herramientas/flutter`. App en `app_flutter/` con todo lo de la versión Expo portado y el mapa integrado. 41 pruebas pasan.
- [x] Pestaña "Modelo" movida a Inicio > Herramientas de desarrollo (solo Android).

Falta:
- [x] APK release instalado en un Samsung Galaxy A15 (2026-11-25); la app abre y el mapa 3D carga en la vista web de Android.
- [x] Mapa y respuestas del asistente funcionan en modo avión (prueba manual del equipo, 2026-11-25).
- [ ] Recorrer el resto de pantallas y probar GPS, batería y el reinicio en modo avión.
- [x] Reglas de emergencia ampliadas a lesiones, estado grave y animales (2026-11-25); 60 pruebas pasan. Instalado en el celular; falta probarlo allí y revisar la lista de frases.
- [ ] Guardar los ajustes al cerrar la app (requiere un paquete de almacenamiento local; avisar antes de instalar).
- [ ] Firma propia para publicar el APK (hoy se firma con la clave de depuración).
- [ ] Retirar o archivar `app/` (Expo) cuando el equipo lo confirme.

## Mapa (sector Nevado del Ruiz)
Hecho:
- [x] Datos: recorte de OpenStreetMap, límite WDPA, curvas de nivel cada 100 m y teselas de elevación (zoom 10 a 12). Visor con relieve 3D, mapa plano, filtro por zoom y fichas de lugares.

Falta:
- [x] Borde sur ampliado de 4,80 a 4,75 (2026-11-25): la Cumbre Sur del Nevado de Santa Isabel ya queda dentro. Datos e imagen satelital regenerados.
- [x] Estilo ilustrado aplicado al visor (2026-11-25), con aviso de carga mientras se dibuja. Revisado en el navegador.
- [ ] Comprobar en el celular el estilo nuevo: fluidez y legibilidad a pleno sol.
- [ ] Verificar senderos y refugios antes de mostrarlos como datos de la guía. Hay rutas de cumbre trazadas en OSM y el plan de manejo menciona senderos al glaciar cerrados.
- [ ] Confirmar con el SGC la vigencia del mapa de amenaza volcánica 2015 y su licencia antes de incluirlo en la app.
- [ ] Confirmar las condiciones de uso del polígono WDPA (Protected Planet) para redistribuirlo en la app.
- [ ] Revisar el catálogo de fuentes termales (INGEOMINAS, 2001) contra una fuente actual antes de usar sus coordenadas.

## Spike del modelo local (en curso)
Decisiones tomadas:
- Modelo: Qwen2.5-1.5B-Instruct, cuantización Q4_K_M (`qwen2.5-1.5b-instruct-q4_k_m.gguf`, 1.117.320.736 bytes, descarga desde Hugging Face, repo oficial `Qwen/Qwen2.5-1.5B-Instruct-GGUF`). Llama 3.2 1B solo si Qwen no cabe en la RAM o va lento en el celular.
- Compilación: Android SDK local (no EAS Build, para no subir el código a servicios en la nube).
- Nombre de paquete Android: `co.edu.paramo.asistente`.
- Comparación con NVIDIA: no existe un Nemotron de 1,5B; lo más chico es Nemotron 3 Nano 4B (GGUF oficial en `nvidia/NVIDIA-Nemotron-3-Nano-4B-GGUF`), unas 2,5 veces más grande. Se decidió no usarlo por ahora y seguir con Qwen. Queda como candidato de comparación en el benchmark.
- `nemotron-3.5-embed-1b` es un modelo de embeddings (no genera texto): solo sirve para la búsqueda semántica.

Hecho:
- [x] Dependencias instaladas con `npx expo install`: `llama.rn` (0.13.0-rc.12, versión de prueba), `expo-build-properties`, `expo-file-system`. Plugins agregados a `app.json`.
- [x] Pantalla de spike `app/src/spike/ModeloSpike.tsx` (pestaña "Modelo", solo Android): descarga el modelo con verificación de tamaño, lo carga y responde una pregunta midiendo tiempos.
- [x] Tipos y 37 pruebas pasan (verificado de nuevo tras generar `android/`). El `import` de `llama.rn` es dinámico para no romper web ni pruebas.
- [x] Android SDK instalado en `~/Android/Sdk` (2,5 GB): platform-tools, platforms/android-37.0, build-tools 37.0.0, cmake 3.22.1, NDK 27.1.12297006. Licencias aceptadas. Variables `ANDROID_HOME`, `ANDROID_SDK_ROOT` y `PATH` agregadas a `~/.bashrc`.
- [x] `app.json` con `android.package`; `app/android/` generada con `npx expo prebuild --platform android` (también cambió los scripts `android` e `ios` de `package.json` a `expo run:android` y `expo run:ios`).
- [x] APK de depuración compilado (arm64-v8a, 158 MB, 14 min 29 s la primera vez): `cd app/android && ./gradlew assembleDebug -PreactNativeArchitectures=arm64-v8a`. Gradle 9.4.1 funciona con el JDK 21 instalado.
- [x] `postinstall` de `llama.rn`: no hace falta aprobarlo; las librerías nativas ya están en `jniLibs` y su SHA-256 coincide con `native-artifacts.json`.
- [x] Modelo probado en PC (llama.cpp compilado con cmake en `~/herramientas/llama.cpp/build/bin/`, GGUF en `~/modelos/qwen2.5-1.5b/`): unos 32 tokens/s generando y 179 tokens/s procesando el prompt, CPU, 8 hilos. Calidad: ante "¿qué es el mal de altura?" inventó un término y dio consejos médicos dudosos; confirma que el modelo solo no sirve para contenido de seguridad (por eso existe la capa A).

Falta:
- [x] Celular de prueba conectado por USB (2026-11-25): Samsung Galaxy A15 (SM-A155M), 6 GB de RAM, Android 16.
- [x] App instalada en el celular.
- [x] Primera prueba del modelo en el Samsung Galaxy A15 (2026-11-25, reportada por el equipo): carga en 9 s, respuesta en 4,4 s (5 fragmentos, dato por confirmar). A "¿Qué es el páramo?" respondió que es la parte superior del bosque, formada por rocas y suelos calcáreos: respuesta incorrecta.
- [x] Gemma 3 1B IT Q4_K_M descargado en la PC como candidato de comparación (2026-11-25): `~/modelos/gemma-3-1b/gemma-3-1b-it-Q4_K_M.gguf`, 806.058.240 bytes, de `ggml-org/gemma-3-1b-it-GGUF`, SHA-256 verificado. Falta revisar su licencia.
- [x] Comparación Qwen vs. Gemma en la PC (2026-11-25), ver `eval/README.md`: con ficha empatan en aciertos (5 de 11), Gemma usa menos memoria (1,0 vs. 1,7 GB) y responde antes; ambos se niegan demasiado y sin ficha inventan.
- [ ] Ajustar la instrucción del modelo para reducir las negativas injustificadas y repetir la comparación antes de decidir.
- [ ] Ejecutar el spike en el celular: descargar el modelo por wifi, activar modo avión, cargar y responder. Anotar tiempo de carga, tiempo de respuesta y RAM, y compararlo con la PC.
- [ ] Si el spike funciona: benchmark de 2 o 3 modelos (`ondevice-bench`), conectar el modelo al buscador y a las guardias de seguridad, descarga previa con reanudación y aviso de espacio libre, y prueba en modo avión (`offline-check`).
- [ ] Definir cómo llega el modelo (1,04 GB) a miles de celulares: descarga por wifi al primer uso, punto de descarga local en la entrada del parque o asset packs de Play Store (no verificado). No puede ir dentro del APK.
- [ ] Decidir el modelo de embeddings para la búsqueda semántica (candidatos: multilingual-e5-small en GGUF, nemotron-3.5-embed-1b).
- [ ] Prueba temporal usando una API de NVIDIA (propuesta del equipo; falta el ID del modelo de chat y confirmar el plan). Solo para desarrollo: la clave no debe ir en el código final ni en archivos versionados, y la app final no puede depender de internet.
- [x] Limpieza (2026-11-25): borrados los compilados de `app/` (de 18 GB a 1,8 GB; se regeneran al recompilar) y los instaladores `cmdline.zip` y de Flutter.
- [ ] Limpieza opcional: `~/.gradle/caches/9.4.1` (2,6 GB, solo lo usaba la app Expo) cuando se retire `app/`.

## Técnicos
- [ ] Hook de pruebas automáticas tras editar código (PostToolUse). Pospuesto por decisión del usuario. Con Flutter, el comando sería `flutter test` y `flutter analyze` desde `app_flutter/`.
- [ ] Probar en Android real: permiso y lectura de GPS, lectura de batería, disparo automático del modo ahorro al 20 %.
- [ ] Que el asistente con modelo de IA consulte `ahorroActivo` y no se cargue en modo ahorro (la pantalla de prueba ya lo respeta).
- [ ] Evento climático manual (el usuario lo dejó fuera de esta ronda).
- [ ] Reemplazar `fichas.demo.json` por el paquete verificado de `data/verificado/`.
- [ ] SQLite MCP opcional para inspeccionar la base de contenido (requiere aprobación para instalar).
- [ ] Spike del asistente: comparar modelos cuantizados contra la línea base sin modelo generativo (skill `ondevice-bench`).

## Datos
- [x] Zona piloto: sector Nevado del Ruiz. Fuentes del mapa con licencia abierta (OSM, Copernicus, Sentinel-2 2016); ver `maps/*/ORIGEN.md`.
- [ ] Responsable de revisar el contenido de seguridad.
- [ ] Conjunto de 50 a 100 preguntas de evaluación (`eval/preguntas.jsonl`).

## Equipo
- [ ] Reparto de tareas entre los 3 integrantes (aún sin definir).
- [x] Teléfono Android de prueba: Samsung Galaxy A15 (SM-A155M), 6 GB de RAM, gama media.

## Después del MVP
- [ ] Versión iOS.
- [ ] Audio de fichas, brújula, punto de descarga local.
- [ ] Spike de comunicación cercana y Meshtastic.
