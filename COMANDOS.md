# Comandos

Última actualización: 2026-11-26

Todos se ejecutan desde la raíz de este repositorio (`nevado_app/`).

## 1. Preparar el entorno

Se necesita el SDK de Android y la versión de Flutter fijada en `.fvmrc` (3.47.9).

### Con FVM (recomendado)

```sh
dart pub global activate fvm
fvm install
fvm flutter pub get
```

Si `fvm` no se reconoce en Windows, agregar `%LOCALAPPDATA%\Pub\Cache\bin` al PATH.

En los comandos de este documento, anteponer `fvm`: `fvm flutter ...` y `fvm dart ...`.

### Linux con Flutter 3.50.1, sin FVM

```sh
export PATH=$HOME/herramientas/flutter/bin:$PATH
flutter pub get
```

La ruta es la del equipo donde está instalado; ajustarla si es otra. Con esta versión:

- Agregar `--android-skip-build-dependency-validation` a `flutter run` y `flutter build apk`.
- `flutter pub get` modifica `pubspec.lock`. No subir ese cambio.

## 2. Token del modelo (preparar la estación)

El modelo se descarga **una sola vez** en el computador de la estación; los teléfonos lo reciben desde allí y
no necesitan token.

1. Aceptar la licencia en https://huggingface.co/litert-community/Gemma3-1B-IT y crear un token de lectura.
2. Descargar el modelo (584 MB) en la carpeta `estacion/`, que git ignora. Reemplazar `hf_...` por el token:

```sh
mkdir estacion
curl -L -H "Authorization: Bearer hf_..." -o estacion/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/d448835d84411a08f577e25f3afebe528402d73b/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm
```

En Windows PowerShell, usar `curl.exe` en lugar de `curl`.

### Token dentro de la app (descarga por internet)

Decisión del 2026-11-26: la app del visitante descarga el modelo desde Hugging Face con un token **de solo
lectura** del equipo y, si falla, desde el teléfono del guía. Crear `.env` (git lo ignora):

```sh
HUGGINGFACE_TOKEN=hf_...
CONTENIDO_URL=https://nevados-contenido.<cuenta>.workers.dev
```

y compilar con `--dart-define-from-file=.env`. El token queda dentro del APK y se puede extraer: si se filtra,
revocarlo y crear otro. `CONTENIDO_URL` sale de `cloudflare/README.md`.

## 3. Ejecutar en el teléfono (desarrollo)

Activar la depuración USB en el teléfono y conectarlo. Requiere Android 11 o superior; el modelo, además,
arm64 y 4 GB de RAM.

```sh
flutter devices
flutter run                                                               # app del visitante
flutter run --flavor guia -t lib/main_guia.dart --dart-define-from-file=secrets/guia.env   # app del guía
```

Mientras corre: `r` recarga, `R` reinicia y `q` cierra. Sin `--flavor`, se compila la app del visitante
(`default-flavor` en `pubspec.yaml`). Las dos se pueden instalar a la vez en un mismo teléfono.

## 3.1. App del guía

Sin usuario ni contraseña ni vencimiento. Edita el contenido, lo publica en R2, lo comparte por su zona wifi y
emite los pases. Va en un celular o tableta dedicado.

1. Crear las claves (una vez; requiere `secrets/pase_privada.key` y `.env`):

```sh
dart run tool/preparar_guia.dart
```

Crea `secrets/guia.env` con el token, la dirección del contenido, la clave de los pases, la llave del
contenido y la clave para publicar. **Nunca compilar la app del visitante con ese archivo.**

2. Compilar e instalar:

```sh
flutter build apk --release --flavor guia -t lib/main_guia.dart --target-platform android-arm64 --dart-define-from-file=secrets/guia.env
adb install -r build/app/outputs/flutter-apk/app-guia-release.apk
```

3. Copiar al teléfono del guía la app del visitante, para que la reparta (sección 5):

```sh
adb push build/app/outputs/flutter-apk/app-visitante-release.apk /sdcard/Android/data/co.nevados.app.guia/files/nevados.apk
```

La carpeta existe después de abrir la app del guía una vez.

4. Descargar el modelo en la app del guía (Guía IA, con internet), para que también lo comparta.

En el parque: activar la zona wifi del teléfono, abrir **Compartir** y tocar **Encender servidor**. Los
visitantes se conectan a esa red, escanean con la cámara el QR "Instalar la app" (si no la tienen) y, desde la
app, el QR del pase.

Si se pierde un teléfono del guía: `dart run tool/preparar_guia.dart --nuevas`, actualizar el secreto del
Worker, compilar e instalar de nuevo y publicar otra vez.

## 4. Generar el pase (y entregar el modelo)

Sin un pase vigente solo abren las secciones Seguridad y Acerca. Cada pase dura **10 minutos desde que se genera**.

Requisitos: el modelo en `estacion/` (sección 2) y `secrets/pase_privada.key`.

Esta es la estación con computador. Sin computador, la app del guía hace lo mismo (sección 3.1).

El servidor entrega también el **contenido cifrado** (las secciones de `contenido/secciones/`, o
`--contenido CARPETA`). Para publicar cambios basta con editar los `.md` y pulsar **Enter**: no hace falta
recompilar. La
llave de cada día se crea en `secrets/llaves/`. Un pase `--sin-servidor` activa la app, pero no entrega fichas.

### Paso 1. Ejecutar uno de estos comandos

| Situación | Comando |
|---|---|
| Teléfono en la misma red wifi que el computador | `dart run tool/generar_pase.dart` |
| Teléfono conectado por cable USB (no gasta datos) | `dart run tool/generar_pase.dart --usb` |
| Solo el pase, sin entregar el modelo | `dart run tool/generar_pase.dart --sin-servidor` |

Con Flutter 3.50.1 sin FVM, ejecutar antes `export PATH=$HOME/herramientas/flutter/bin:$PATH`.

Esperar el mensaje **"Servidor listo"**. La terminal queda abierta entregando el modelo.

### Paso 2. Abrir el QR (en otra terminal)

```sh
xdg-open build/pases/pase.svg     # Linux
start build\pases\pase.svg        # Windows
```

### Paso 3. En el teléfono

Abrir Nevados, tocar **Escanear pase** y escanear el QR.

- Si no tiene el modelo, lo descarga.
- Si tiene el modelo de una versión anterior o dañado, descarga el actual y después borra el anterior.
- Si ya tiene el actual, no lo descarga.
- Las fichas se descargan con cada pase y se borran cuando vence.

Esperar a **"Modelo instalado"** en el inicio antes de cerrar el servidor, desconectar el cable o salir de la red.

### Otro pase y cierre

- **Enter** en la terminal del servidor: emite un pase nuevo (recargar el QR).
- **Ctrl+C**: apaga el servidor.
- Otra duración: agregar `--minutos 720` (12 horas).

### Si el puerto está ocupado

Cerrar el otro servidor con `Ctrl+C`. En Linux, para cerrarlo desde otra terminal:

```sh
ss -ltnp | grep :8000     # muestra el proceso (pid)
fuser -k 8000/tcp         # lo termina
```

También se puede usar otro puerto: `--puerto 8001`.

### Sobre las versiones del modelo

La versión del modelo la define la app. Para cambiarlo: actualizar `lib/core/ai/model_file.dart` y
`edge_llm_engine.dart`, compilar e instalar el APK nuevo y colocar el archivo nuevo en `estacion/`.

### Claves

Para generar pases en otro computador, copiar allí `secrets/pase_privada.key`, recibido por un canal privado.
`--nuevas-claves` reemplaza las claves: invalida los pases anteriores y obliga a compilar e instalar de nuevo.

## 5. Compilar el APK

APK del visitante:

```sh
flutter build apk --release --flavor visitante --target-platform android-arm64 --obfuscate --split-debug-info=build/symbols --dart-define-from-file=.env
```

`--obfuscate` dificulta la ingeniería inversa. Conservar `build/symbols/` de cada versión repartida: se
necesita para interpretar los errores. Las capturas de pantalla están bloqueadas en todas las compilaciones.

Queda en `build/app/outputs/flutter-apk/app-visitante-release.apk`. Hoy se firma con la clave de depuración del
computador que compila: un APK compilado en otro computador no actualiza al ya instalado (hay que
desinstalarlo antes).

Instalación o actualización por cable, **sin borrar los datos ni el modelo**:

```sh
adb install -r build/app/outputs/flutter-apk/app-visitante-release.apk
```

`adb` está en `platform-tools` del SDK de Android (en Linux, `~/Android/Sdk/platform-tools/adb`).
No usar `flutter install`: desinstala antes y se pierde el modelo.

## 5.1. Instalar la app por QR (estación)

Antes: APK compilado (sección 5) y requisitos de la sección 4.

1. Conectar el computador y el teléfono a la misma red wifi (o a la zona wifi de un teléfono).
2. Ejecutar `dart run tool/generar_pase.dart`. Si hay varias redes, las lista; repetir con `--ip`.
3. Escanear `build/pases/instalar.svg` con la **cámara** del teléfono, descargar la aplicación y permitir la
   instalación.
4. Seguir los pasos 2 y 3 de la sección 4 (`pase.svg` se escanea **desde la app**).

Si el teléfono no conecta: permitir el puerto 8000 en el cortafuegos (en Linux con `ufw`,
`sudo ufw allow 8000/tcp`; en Windows, aceptar el aviso) y comprobar que la red no aísle a los equipos entre sí.
Algunas redes públicas o universitarias lo hacen; en ese caso usar una zona wifi propia o `--usb`.

## 6. Pruebas y revisión del código

```sh
flutter test
flutter test test/access_test.dart    # solo el pase
flutter analyze
```

Con Flutter 3.50.1, `flutter analyze` reporta avisos de obsolescencia de `package:flutter/material.dart`.

## 7. Probar sin internet

1. Instalar la app (sección 5 o 5.1) y activarla con un pase (sección 4).
2. Activar el modo avión.
3. Recorrer las secciones y hacer preguntas en el asistente.
4. Cerrar la app, reiniciar el teléfono y repetir.

## 8. Otras herramientas

| Comando | Para qué sirve | Requisitos |
|---|---|---|
| `python3 eval/comparar_modelos.py` | Compara modelos en el computador (ver `eval/README.md`) | `llama.cpp` y los modelos descargados |
| `python3 maps/scripts/generar_mapa.py` | Regenera los datos del mapa (ver `maps/README.md`) | Datos crudos y librerías de mapas |
| `python3 tool/sync_map_assets.py` | Copia el mapa generado a `assets/map/` | Mapa generado |
| `python3 maps/scripts/generar_recorrido.py` | Genera el recorrido de 5 paradas y sus tramos (`assets/map/salida/recorrido.geojson`) desde `maps/recorrido/estaciones.csv` | Ninguno |
| `node --check cloudflare/worker.js` | Revisa la sintaxis del Worker de publicación | Node.js |

## Estado de verificación

Probado el 2026-11-26 en Linux con Flutter 3.50.1: `flutter test`, `flutter analyze`, la compilación de los APK
de depuración y release sin token y la generación del pase. La entrega de archivos del servidor está cubierta
por pruebas automáticas. **Sin probar:** el flujo completo de la estación con un teléfono y el modelo real, y el
resto de comandos.

Rama `feat/guia-rag` (2026-11-26): `flutter test` (todo pasa salvo 3 pruebas de `shell_test.dart` que ya
fallaban antes), `flutter analyze` sin observaciones y compilación de `app-visitante-release.apk` y
`app-guia-release.apk`. El visor del mapa con la sección Recorrido se revisó en el navegador. **Sin probar:**
las dos apps en teléfonos, la zona wifi real, el Worker en Cloudflare (solo se revisó su sintaxis) y la
descarga del modelo desde Hugging Face con el token.

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| "No disponible" en Contenido de la guía | Usar un pase del servidor (no `--sin-servidor`), seguir en la red de la estación y tocar **Reintentar contenido** |
| La pantalla sale negra al grabarla o capturarla | Es el bloqueo de capturas |
| Error de versión de Android Gradle Plugin | Usar Flutter 3.47.9 con FVM o agregar `--android-skip-build-dependency-validation` |
| "El modelo no está instalado" | Conectarse a la red de la estación y escanear el pase |
| "No se pudo descargar" | Revisar que el teléfono siga en la red de la estación y tocar **Reintentar descarga** |
| "Ese código no es un pase válido" | El pase se firmó con otra clave: usar la clave privada del equipo o recompilar |
| "La hora del teléfono no coincide" | Activar la hora automática en el teléfono y en el computador |
| El teléfono no aparece en `flutter devices` | Revisar la depuración USB y aceptar el permiso en el teléfono |
