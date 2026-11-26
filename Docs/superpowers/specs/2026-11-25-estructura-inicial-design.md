# Estructura inicial de la app (tarea 1)

Fecha: 2026-11-25. Estado: diseño aprobado en conversación, spec pendiente de revisión.

## Objetivo

Dejar en la raíz del repositorio un proyecto Flutter que compile y se pueda trabajar desde VS Code, sobre el que el equipo agregue las demás tareas sin conflictos.

## Alcance

### Versión y plataformas

- Flutter 3.47.x fijado con FVM (`.fvmrc` en git). Se confirma el parche exacto disponible antes de fijarlo. Si 3.47.x no está disponible, se detiene y se consulta.
- `pubspec.lock` en git.
- Nombre del paquete Dart: `nevado_app`. Identificador de la app: `co.nevados.app`.
- Android: `minSdk 30`, permiso `INTERNET` en el manifiesto principal, filtro `arm64-v8a` solo en release (los emuladores son x86_64).
- iOS: versión mínima 15.0. No se compila en este equipo (requiere macOS o nube).
- Web: solo para revisar la interfaz rápido. No es plataforma de entrega.

### Estructura

```text
Docs/
assets/content/          # contenido del Nivel 0
lib/
  main.dart
  app/                   # tema, rutas, widget raíz
  core/ai/
    llm_engine.dart      # interfaz propia del motor
    retriever.dart       # interfaz propia de búsqueda
  features/
    home/
    emergency/
    location/
    chat/
    map/                 # a cargo del compañero
test/
android/  ios/  web/
```

### Contenido inicial

- Pantalla de inicio con cuatro botones grandes: Emergencias, Asistente, Mi ubicación, Mapa.
- Aviso visible en inicio: la app orienta y no reemplaza a guías ni a Parques Nacionales Naturales (RN-05).
- Tema de alto contraste. El texto respeta el tamaño configurado en el sistema (RE-03).
- Cuatro pantallas destino vacías con título. Navegación con `Navigator`, sin librería de rutas.
- Interfaces `LlmEngine` (genera respuesta en streaming a partir de un prompt) y `Retriever` (devuelve fragmentos con texto, fuente, fecha y puntaje para una consulta). Solo contratos, sin implementación.
- Textos en español.

### Repositorio

- Agregar a `.gitignore` las entradas de Flutter y FVM (`.dart_tool/`, `.fvm/`, entre otras) sin borrar las existentes.
- Generar el proyecto sin sobrescribir `Docs/` ni `.gitignore`.
- La ruta local del JDK para VS Code va en la configuración de usuario, no en el repositorio.

## Fuera de alcance

Paquetes de IA, GPS, mapas, contenido real del parque, gestor de estado, inglés. Cada uno entra con su tarea.

## Verificación

- `flutter analyze` sin problemas.
- Prueba de widget: la pantalla de inicio muestra el aviso y cada botón abre su pantalla.
- `flutter build apk --debug` y `flutter build web` terminan bien.
- La app corre en el emulador desde VS Code.

## Riesgos

- Flutter 3.47.x puede cambiar las versiones de Gradle y requisitos de Java respecto a la prueba hecha con 3.41.9.
- `flutter_edge_ai` puede no soportar web. Se confirma antes de la tarea 7.
- `.gitignore` ignora `*.db`. Habrá que hacer una excepción si el Nivel 0 usa una base empaquetada.
