# Nevados

Asistente sin conexión para guías y visitantes del Parque Nacional Natural Los Nevados, habilitado con un pase temporal. Ver `Docs/`.

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
dart run tool/generar_pase.dart                  # pase y modelo por la red local (10 minutos)
dart run tool/generar_pase.dart --usb            # igual, por cable USB
dart run tool/generar_pase.dart --sin-servidor   # solo el pase
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

La app no incluye el modelo: lo descarga al activar el pase, desde el computador de la estación, y luego
funciona sin red. No requiere token en el teléfono.

## Protección del contenido

| Medida | Detalle |
|---|---|
| Fichas cifradas | AES-256-GCM. La estación las entrega y el teléfono solo guarda el paquete cifrado; el texto vive en memoria |
| Llave temporal | Viaja en el QR del pase, cambia cada día y se guarda en el almacén seguro de Android |
| Vencimiento | Se destruye la llave, se borra el paquete y se descarta la respuesta en pantalla. Con la app cerrada, ocurre al abrirla |
| Pantalla | Bloqueadas las capturas, la grabación y la vista previa en recientes |
| Copias | Desactivadas la copia en la nube y la transferencia entre teléfonos |
| Ingeniería inversa | El APK de release se compila ofuscado |

En el APK solo van sin cifrar las fichas de emergencia (`assets/content/emergencia.json`). El mapa (datos
abiertos) y el modelo (público) no se cifran. Las fichas de origen están en `contenido/`.

Límites: no impide fotografiar la pantalla con otro equipo. Durante la vigencia, quien tenga conocimientos
técnicos puede extraer la llave del QR y descifrar el paquete de ese día, o leer la memoria de un teléfono
con acceso de administrador. El objetivo es que sea difícil, no imposible. La conexión con la estación es
local y sin cifrar; el pase conviene mostrarlo solo a quien vaya a usarlo.

## Estación de instalación

La aplicación no se publica en tiendas. En la estación, un computador reparte el APK y el modelo por la red
local y emite los pases (`dart run tool/generar_pase.dart`). Los pasos están en [`COMANDOS.md`](COMANDOS.md).

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
| Contenido cifrado | `lib/core/content/`, `lib/features/content/`, `contenido/` |
| Reglas de seguridad y búsqueda local | `lib/core/safety/`, `lib/core/search/`, `lib/core/assistant/` |
| Mapa y recorrido de 5 paradas | `lib/features/map/`, `assets/map/`, `maps/` (`maps/recorrido/`) |
| App del guía (editar, publicar, compartir, pases) | `lib/main_guia.dart`, `lib/features/guia/` |
| Publicación en R2 | `lib/core/content/publicacion_r2.dart`, `cloudflare/` |
| Modo ahorro y tamaño de texto (en "Acerca") | `lib/core/settings/`, `lib/features/about/` |
| Comparación de modelos | `eval/` |

El asistente decide en este orden: respuestas fijas (emergencias y medicamentos), búsqueda en las secciones de
la guía y el modelo, que responde solo con los 3 fragmentos recuperados (RAG) y sin fragmentos no se usa. En
modo ahorro o sin modelo se muestra el fragmento encontrado. La fuente la muestra la app, no el modelo. El
contenido (`contenido/secciones/`) es un borrador y **no está verificado**.

Hay dos apps del mismo código: la del visitante (`lib/main.dart`, por defecto) y la del guía
(`lib/main_guia.dart`, `--flavor guia`). Ver `COMANDOS.md` y `cloudflare/README.md`.

Pruebas: `fvm flutter test` y `fvm flutter analyze`.

Los documentos de estado y pendientes están en `Docs/guia/`.
