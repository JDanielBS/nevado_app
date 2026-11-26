# Chat de voz (respuestas en audio con Piper) — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir una nueva pantalla "Chat de voz" en la que el asistente responda al visitante también en audio, usando modelos Piper (TTS neuronal, ligero, CPU, con voces en español), reutilizando el flujo de chat existente.

**Architecture:** Se mantiene el `ChatController` actual como fuente de verdad del texto. Se agrega un contrato `TtsEngine` en `lib/core/voice/` con una implementación sobre `flutter_piper_tts`, más un controlador de voz que envuelve al chat y dispara la síntesis cuando llega la respuesta completa. La descarga del modelo de voz se gestiona igual que la del LLM (instalación bajo demanda, verificación de archivos, carga/liberación de memoria). La UI nueva vive en `lib/features/chat/voice_chat_screen.dart` y se expone como nueva sección de navegación.

**Tech Stack:** Flutter 3.47.9 con FVM, `flutter_piper_tts` (Piper + reproductor), `shared_preferences` (ya disponible), voces Piper en español (`.onnx` + `.onnx.json` descargadas desde Hugging Face).

**Rama:** `feat/chat-de-voz` (creada desde `main` actualizado).

## Global Constraints

- Todos los comandos usan `fvm flutter` / `fvm dart`.
- Textos en español; controles mínimos de 44 px; `flutter analyze` y las pruebas deben pasar.
- El modelo de voz NO va dentro del APK: se descarga con wifi (o desde la red de la estación) como el LLM.
- Modo ahorro: la síntesis de voz se desactiva cuando `ahorroActivo` está activo.
- No modificar `Docs/` existentes salvo este plan y el estado.
- Sin `push`.

---

### Task 1: Dependencia y contrato TTS

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/voice/tts_engine.dart`
- Create: `lib/core/voice/tts_exceptions.dart`

- [ ] **Step 1: Agregar dependencia**

En `pubspec.yaml`, bajo `dependencies`, añadir:

```yaml
  flutter_piper_tts: ^0.5.2
```

Ejecutar `fvm flutter pub get`.

- [ ] **Step 2: Definir el contrato**

`lib/core/voice/tts_engine.dart`:

```dart
abstract interface class TtsEngine {
  String? unsupportedReason();
  Future<bool> isInstalled();
  Stream<int> install({Uri? origen});
  Future<void> load();
  Future<void> unload();
  Future<void> speak(String text);
  Future<void> stop();
  bool get isSpeaking;
}
```

- [ ] **Step 3: Excepciones**

`lib/core/voice/tts_exceptions.dart` con `CorruptVoiceModelException`.

- [ ] **Step 4: Prueba del contrato**

Crear `test/core/voice/fake_tts_engine.dart` y `test/core/voice/tts_engine_test.dart` con un fake que registra llamadas a `speak`. Ejecutar `fvm flutter test test/core/voice`.

---

### Task 2: Implementación Piper

**Files:**
- Create: `lib/core/voice/piper_tts_engine.dart`
- Modify: `lib/core/ai/model_file.dart` (reutilizar verificación si aplica)

- [ ] **Step 1: Implementar `PiperTtsEngine`**

Envolver `flutter_piper_tts`: inicialización, instalación del modelo de voz español, carga en memoria, `speak`, `stop`, liberación. Seguir el patrón de `EdgeLlmEngine` (un solo archivo importa el paquete).

- [ ] **Step 2: Fuente del modelo**

Definir constante con la URL base de la voz española (p. ej. `es_ES-davefx-medium`) en Hugging Face `rhasspy/piper-voices`. Documentar tamaño aproximado y SHA-256.

- [ ] **Step 3: Prueba de integración manual**

En un dispositivo, descargar y reproducir una frase. Registrar tiempo de carga y latencia en `Docs/pruebas/`.

---

### Task 3: Controlador de chat de voz

**Files:**
- Create: `lib/features/chat/voice_chat_controller.dart`
- Modify: `lib/features/chat/chat_controller.dart` (exponer hook opcional)

- [ ] **Step 1: Envolver `ChatController`**

`VoiceChatController extends ChangeNotifier` que contiene un `ChatController` y un `TtsEngine`. Reenvía `ask`, `turnos`, `phase`. Al terminar de generar la respuesta (o al recibir respuesta de fichas), llama a `tts.speak(textoFinal)` si `autoSpeak` y no está en modo ahorro.

- [ ] **Step 2: Auto-lectura configurable**

Propiedad `autoSpeak` persistida con `shared_preferences` (clave `voz_auto_leer`).

- [ ] **Step 3: Pruebas**

`test/features/chat/voice_chat_controller_test.dart`: con un `FakeTtsEngine`, al preguntar una ficha, se llama `speak` con el texto de la respuesta; con `autoSpeak=false` no se llama.

---

### Task 4: Pantalla y navegación

**Files:**
- Create: `lib/features/chat/voice_chat_screen.dart`
- Modify: `lib/app/shell.dart`

- [ ] **Step 1: Crear `VoiceChatScreen`**

UI similar a `ChatScreen` pero con:
  - Indicador de estado del modelo de voz y botón de descarga.
  - Toggle "Leer respuestas en voz alta".
  - Botón "Repetir" en cada turno para volver a sintetizar.
  - Botón "Detener" mientras se reproduce.

- [ ] **Step 2: Exponer controlador global**

`final chatDeVozDeLaApp = VoiceChatController(chatDeLaApp, PiperTtsEngine());` en `voice_chat_screen.dart`.

- [ ] **Step 3: Navegación**

Agregar `Seccion.guiaVoz` y entrada "Chat voz" en `_Navegacion`, o bien un botón dentro de "Guía IA" que abra la nueva pantalla. Decidir con el equipo; por defecto se añade entrada para descubribilidad.

- [ ] **Step 4: Pruebas de widget**

`test/features/chat/voice_chat_screen_test.dart`: renderiza sin crashear con un controlador fake.

---

### Task 5: Ajustes y modo ahorro

**Files:**
- Modify: `lib/core/settings/settings.dart`

- [ ] **Step 1: Añadir `vozActiva`**

Bandera en `Ajustes` (default true) y persistencia.

- [ ] **Step 2: Respetar modo ahorro**

En `VoiceChatController`, si `ahorroActivo` está activo, no cargar ni usar el TTS.

---

### Task 6: Verificación y documentación

**Files:**
- Modify: `Docs/ESTADO.md`, `Docs/PENDIENTES.md`

- [ ] **Step 1: Análisis y pruebas**

`fvm flutter analyze` y `fvm flutter test`. Corregir.

- [ ] **Step 2: APK de prueba**

`fvm flutter build apk --release --target-platform android-arm64`. Instalar y probar voz en el celular.

- [ ] **Step 3: Actualizar estado**

Anotar en `Docs/ESTADO.md` la nueva funcionalidad y pendientes (prueba en celular, tamaño de descarga, voces alternativas).

---

## Review Focus

- Latencia de síntesis aceptable en gama media (Samsung A15) sin GPU.
- No bloquear la UI mientras se sintetiza; permitir interrumpir.
- El modelo de voz se descarga una sola vez y se verifica.
- Modo ahorro desactiva la voz.
- Las pruebas existentes siguen pasando.
