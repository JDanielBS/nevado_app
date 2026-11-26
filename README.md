# Nevados

Asistente sin conexión para guías del Parque Nacional Natural Los Nevados. Lo usa solo el guía; no se distribuye a los visitantes. Ver `Docs/`.

La lista completa de comandos está en [`COMANDOS.md`](COMANDOS.md).

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

## Pase de recorrido

La app solo funciona con un pase vigente, para que no se use fuera del recorrido. Sin pase quedan disponibles
**Seguridad** y **Acerca**; la ruta, las estaciones, el mapa y la guía IA se bloquean. Todo se comprueba sin internet.

Generar un pase (en un computador del personal, desde la raíz del proyecto):

```sh
dart run tool/generar_pase.dart                # 12 minutos, valor para pruebas
dart run tool/generar_pase.dart --minutos 720  # 12 horas
```

El QR queda en `build/pases/pase.svg` (se abre con un navegador). En la app: **Escanear pase**. También se
puede pegar el código que imprime el comando.

| Archivo | Contenido |
|---|---|
| `secrets/pase_privada.key` | Clave privada. No se versiona. Quien la tenga puede crear pases; compartirla solo por un canal privado. |
| `lib/core/access/public_key.dart` | Clave pública incluida en la app. Se versiona. |

Para generar pases válidos en otro computador, copiar allí la clave privada. `--nuevas-claves` la reemplaza e
invalida los pases y los APK anteriores.

Límites:

- Controla el tiempo, no el lugar: dentro de la vigencia la app funciona también fuera del parque.
- Reinstalar la app (o borrar sus datos), atrasar la hora y reutilizar un QR antiguo permite volver a entrar.
- No protege contra un APK modificado.
- La hora del computador que genera el pase y la del teléfono deben coincidir (tolerancia de 2 minutos).

## Asistente con IA (experimental)

Usa Gemma 3 1B (584 MB). Solo en Android arm64 con 4 GB de RAM o más; el emulador no lo ejecuta.

La Guía IA puede leer en voz alta **solo las respuestas que escribe el modelo** (las de fichas, reglas y
emergencias se muestran en texto). La voz es Piper `es_ES-davefx-medium` sobre `sherpa-onnx` 1.13.8: se descarga
de la estación, se verifica con SHA-256 y funciona sin red. Se apaga en modo ahorro o en "Acerca".
`sherpa-onnx` 1.x incluye `espeak-ng`, con licencia GPL-3: pendiente de revisar antes de distribuir.

La app no incluye el modelo: lo descarga al activar el pase, desde el computador de la estación, y luego
funciona sin red. No requiere token en el teléfono.

## Estación de instalación

La aplicación no se publica en tiendas. En la estación, un computador reparte el APK y el modelo por la red
local y emite los pases (`tool/servidor_estacion.dart`). Los pasos están en [`COMANDOS.md`](COMANDOS.md).

- El pase lleva firmada la dirección del modelo; la app verifica el archivo con SHA-256 antes de cargarlo.
- La conexión local es HTTP sin cifrar, por lo que la app permite ese tipo de tráfico.
- El modelo se redistribuye bajo los términos de Gemma (https://ai.google.dev/gemma/terms): pendiente de
  revisar sus condiciones.

## Guía sin conexión

| Función | Dónde |
|---|---|
| Estructura de pantallas (diseño "Kumanday") | `lib/app/shell.dart`: encabezado y navegación Ruta · Guía IA · Seguridad |
| Ruta, estaciones y fichas por estación | `lib/features/route/`, `lib/features/station/`, `lib/core/route/estaciones.dart` |
| Fotos de cada estación (paisaje, flora, fauna) | `assets/imagenes/` (ver `LEEME.md`); el paisaje también es la marca de agua |
| Paleta por estación y componentes | `lib/core/ui/palette.dart`, `lib/core/ui/widgets.dart`, fuentes en `fonts/` |
| Seguridad, emergencias y fichas | `lib/features/safety/`, `assets/content/` |
| Pase de recorrido | `lib/core/access/`, `lib/features/access/`, `tool/generar_pase.dart` |
| Reglas de seguridad y búsqueda local | `lib/core/safety/`, `lib/core/search/`, `lib/core/assistant/` |
| Mapa | `lib/features/map/`, `assets/map/`, `maps/` |
| Modo ahorro y tamaño de texto (en "Acerca") | `lib/core/settings/`, `lib/features/about/` |
| Comparación de modelos | `eval/` |

El asistente decide en este orden: reglas de emergencia y de límites, fichas y, solo si no hay nada, el modelo
(que no se usa en modo ahorro). El contenido actual es de demostración y **no está verificado**.

Pruebas: `fvm flutter test` y `fvm flutter analyze`.

Los documentos de estado y pendientes están en `Docs/guia/`.
