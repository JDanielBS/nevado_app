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

## 4. Generar el pase del recorrido

Sin un pase vigente solo abren Emergencias y Mi ubicación.

```sh
dart run tool/generar_pase.dart                 # 12 minutos (pruebas)
dart run tool/generar_pase.dart --minutos 720   # 12 horas
```

Abrir `build/pases/pase.svg` en un navegador (en Linux, `xdg-open build/pases/pase.svg`; en Windows,
`start build\pases\pase.svg`) y escanearlo desde la app con **Escanear pase**.

**Antes de usarlo en otro computador:** copiar `secrets/pase_privada.key`, recibido por un canal privado. Sin
ese archivo el comando se detiene.

`dart run tool/generar_pase.dart --nuevas-claves` reemplaza las claves. Invalida los pases anteriores y obliga
a compilar e instalar la app de nuevo. Usarlo solo si el equipo lo acuerda.

## 5. Compilar el APK

APK que reparte la estación (sin token):

```sh
flutter build apk --release --target-platform android-arm64
```

Queda en `build/app/outputs/flutter-apk/app-release.apk`. Hoy se firma con la clave de depuración del
computador que compila: un APK compilado en otro computador no actualiza al ya instalado (hay que
desinstalarlo antes).

Instalación por cable:

```sh
flutter install --release
```

## 5.1. Estación de instalación

Antes: modelo en `estacion/` (sección 2), APK compilado (sección 5) y `secrets/pase_privada.key`.

1. Conectar el computador a la red wifi de la estación (o a la zona wifi de un teléfono).
2. Ejecutar:

```sh
dart run tool/servidor_estacion.dart
```

Si hay varias redes, el comando las lista; repetirlo con `--ip`. Opciones: `--puerto`, `--minutos`, `--apk` y
`--modelo`.

3. En el teléfono, conectado a la **misma red**:
   1. Escanear `build/pases/instalar.svg` con la cámara, descargar la aplicación y permitir la instalación.
   2. Abrir Nevados, tocar **Escanear pase** y escanear `build/pases/pase.svg`.
   3. Esperar a "Modelo instalado" en la pantalla de inicio.
4. **Enter** en la terminal emite un pase nuevo. **Ctrl+C** apaga el servidor.

Los pases solo se muestran en el computador de la estación; el servidor no los publica.

Si el teléfono no conecta: permitir el puerto 8000 en el cortafuegos del computador (en Linux con `ufw`,
`sudo ufw allow 8000/tcp`; en Windows, aceptar el aviso), apagar los datos móviles del teléfono y comprobar que
la red no aísle a los equipos entre sí.

## 6. Pruebas y revisión del código

```sh
flutter test
flutter test test/access_test.dart    # solo el pase
flutter analyze
```

Con Flutter 3.50.1, `flutter analyze` reporta avisos de obsolescencia de `package:flutter/material.dart`.

## 7. Probar sin internet

1. Instalar y activar desde la estación (sección 5.1).
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
| Error de versión de Android Gradle Plugin | Usar Flutter 3.47.9 con FVM o agregar `--android-skip-build-dependency-validation` |
| "El modelo no está instalado" | Conectarse a la red de la estación y escanear el pase |
| "No se pudo descargar" | Revisar que el teléfono siga en la red de la estación y tocar **Reintentar descarga** |
| "Ese código no es un pase válido" | El pase se firmó con otra clave: usar la clave privada del equipo o recompilar |
| "La hora del teléfono no coincide" | Activar la hora automática en el teléfono y en el computador |
| El teléfono no aparece en `flutter devices` | Revisar la depuración USB y aceptar el permiso en el teléfono |
