# Nevados

Asistente sin conexión para visitantes del Parque Nacional Natural Los Nevados. Ver `Docs/`.

## Preparar el entorno

La versión de Flutter está fijada en `.fvmrc`.

```powershell
dart pub global activate fvm
fvm install
fvm flutter pub get
fvm flutter run
```

Si `fvm` no se reconoce, agrega `%LOCALAPPDATA%\Pub\Cache\bin` al PATH.

En VS Code, si la extensión Java muestra `Unsupported class file major version`, define en tu configuración de usuario `java.import.gradle.java.home` con la ruta de un JDK 21.

## Asistente con IA (experimental)

Usa Gemma 3 1B (584 MB), que se descarga desde la app. Solo en Android arm64 con 4 GB de RAM o más; el emulador no lo ejecuta.

1. Acepta la licencia en https://huggingface.co/litert-community/Gemma3-1B-IT y crea un token de lectura.
2. Crea `.env` en la raíz (git lo ignora) con `HUGGINGFACE_TOKEN=hf_...`.
3. Ejecuta con el token:

```powershell
fvm flutter run --dart-define-from-file=.env
```

En VS Code, agrega a `.vscode/settings.json`: `"dart.flutterRunAdditionalArgs": ["--dart-define-from-file=.env"]`.

El token queda dentro del APK. No compartas ni publiques un APK compilado así.

## Guía sin conexión

| Función | Dónde |
|---|---|
| Emergencias y fichas | `lib/features/emergency/`, `lib/features/cards/`, `assets/content/` |
| Reglas de seguridad y búsqueda local | `lib/core/safety/`, `lib/core/search/`, `lib/core/assistant/` |
| Ubicación GPS bajo demanda | `lib/features/location/`, `lib/core/location/` |
| Mapa | `lib/features/map/`, `assets/map/`, `maps/` |
| Modo ahorro y tamaño de texto | `lib/core/settings/` |
| Comparación de modelos | `eval/` |

El asistente decide en este orden: reglas de emergencia y de límites, fichas y, solo si no hay nada, el modelo
(que no se usa en modo ahorro). El contenido actual es de demostración y **no está verificado**.

Pruebas: `fvm flutter test` y `fvm flutter analyze`.

Los documentos de estado y pendientes están en `Docs/guia/`.
