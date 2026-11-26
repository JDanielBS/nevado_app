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

Solo para desarrollo, sin estación: crear `.env` con `HUGGINGFACE_TOKEN=hf_...` y agregar
`--dart-define-from-file=.env` a `flutter run`. Ese token queda dentro del APK: **no repartir un APK compilado
así**.

## 3. Ejecutar en el teléfono (desarrollo)

Activar la depuración USB en el teléfono y conectarlo. Requiere Android 11 o superior; el modelo, además,
arm64 y 4 GB de RAM.

```sh
flutter devices
flutter run
```

Mientras corre: `r` recarga, `R` reinicia y `q` cierra.

## 4. Generar el pase (y entregar el modelo)

Sin un pase vigente solo abren las secciones Seguridad y Acerca. Cada pase dura **10 minutos desde que se genera**.

Requisitos: el modelo en `estacion/` (sección 2) y `secrets/pase_privada.key`.

El servidor entrega también las **fichas cifradas** (`contenido/fichas.demo.json`, o `--contenido RUTA`). Para
publicar cambios en las fichas basta con editar el archivo y pulsar **Enter**: no hace falta recompilar. La
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

APK que reparte la estación (sin token):

```sh
flutter build apk --release --target-platform android-arm64 --obfuscate --split-debug-info=build/symbols
```

`--obfuscate` dificulta la ingeniería inversa. Conservar `build/symbols/` de cada versión repartida: se
necesita para interpretar los errores. Las capturas de pantalla están bloqueadas en todas las compilaciones.

Queda en `build/app/outputs/flutter-apk/app-release.apk`. Hoy se firma con la clave de depuración del
computador que compila: un APK compilado en otro computador no actualiza al ya instalado (hay que
desinstalarlo antes).

Instalación o actualización por cable, **sin borrar los datos ni el modelo**:

```sh
adb install -r build/app/outputs/flutter-apk/app-release.apk
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

## Estado de verificación

Probado el 2026-11-26 en Linux con Flutter 3.50.1: `flutter test`, `flutter analyze`, la compilación de los APK
de depuración y release sin token y la generación del pase. La entrega de archivos del servidor está cubierta
por pruebas automáticas. **Sin probar:** el flujo completo de la estación con un teléfono y el modelo real, y el
resto de comandos.

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
