# Estructura inicial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Proyecto Flutter base en la raíz del repo, con pantalla de inicio navegable e interfaces de IA sin implementación.

**Architecture:** Un solo proyecto Flutter organizado por funcionalidad (`lib/features/*`). Navegación con `Navigator`. El motor de IA y la búsqueda quedan detrás de contratos en `lib/core/ai/`.

**Tech Stack:** Flutter 3.47.9 con FVM, Material, `flutter_test`. Sin dependencias nuevas en la app.

**Spec:** `Docs/superpowers/specs/2026-11-25-estructura-inicial-design.md`

## Global Constraints

- Flutter 3.47.9 (último parche 3.47.x en el repositorio oficial al 2026-11-25), fijado en `.fvmrc`. Todos los comandos usan `fvm flutter`.
- Paquete Dart `nevado_app`. Identificador de la app `co.nevados.app`.
- Android `minSdk 30`, permiso `INTERNET` en el manifiesto principal, solo `arm64-v8a` en release.
- iOS mínimo 15.0.
- Textos en español.
- Sin paquetes de IA, GPS, mapas, estado ni rutas.
- No sobrescribir `Docs/` ni las entradas existentes de `.gitignore`.
- Rama `feat/estructura-inicial`. Sin `push`. No incluir en los commits cambios previos en `Docs/El nevado hackaton.md`.
- Los mensajes de commit terminan con `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Comandos en PowerShell, desde la raíz del repo.

## Review Focus

- Texto del sistema al 200 % en pantalla pequeña: sin desbordes y todos los botones alcanzables (Tarea 2).
- Teléfono en horizontal: aviso visible y botones alcanzables (Tarea 2).
- Volver atrás desde cualquier pantalla regresa al inicio (Tarea 2).
- APK de release en un teléfono arm64: no incluye otras arquitecturas (Tarea 1).
- Compañero clona el repo sin FVM: el `README.md` explica cómo preparar la versión (Tarea 1).

---

### Task 1: Proyecto base, versión y configuración de plataformas

**Files:**
- Create: `.fvmrc`, proyecto generado (`lib/`, `test/`, `android/`, `ios/`, `web/`, `pubspec.yaml`, `pubspec.lock`), `assets/content/.gitkeep`, `README.md`
- Modify: `.gitignore`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner.xcodeproj/project.pbxproj`

**Interfaces:**
- Produces: paquete `nevado_app`, comando `fvm flutter`.

- [ ] **Step 1: Instalar FVM y la versión**

```powershell
dart pub global activate fvm
$fvm = "$env:LOCALAPPDATA\Pub\Cache\bin\fvm.bat"
& $fvm use 3.47.9 --force
& $fvm flutter --version
```

Esperado: `Flutter 3.47.9`. Si falla la descarga o los enlaces simbólicos (requieren Modo de desarrollador de Windows), detenerse y consultar. En los pasos siguientes `fvm` equivale a `& $fvm`.

- [ ] **Step 2: Generar el proyecto**

```powershell
fvm flutter create --org co.nevados --project-name nevado_app --platforms=android,ios,web .
git status --short
git diff --stat -- .gitignore Docs
```

Esperado: aparecen `lib/`, `android/`, `ios/`, `web/`. `.gitignore` sin cambios hechos por `flutter create`. En `Docs` solo el cambio que ya existía.

- [ ] **Step 3: Completar `.gitignore`** (agregar al final)

```gitignore

# Flutter / Dart / FVM
.dart_tool/
.fvm/
.flutter-plugins
.flutter-plugins-dependencies
.pub-cache/
.pub/
*.iml
**/ios/Flutter/.last_build_id
app.*.symbols
app.*.map.json
/android/app/debug
/android/app/profile
/android/app/release
```

- [ ] **Step 4: Configurar Android**

En `android/app/build.gradle.kts`:
- `applicationId = "co.nevados.app"` (dejar `namespace` como se generó).
- `minSdk = 30`.
- Agregar al final del archivo:

```kotlin
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(
            "lib/armeabi-v7a/**",
            "lib/x86/**",
            "lib/x86_64/**",
        )
    }
}
```

En `android/app/src/main/AndroidManifest.xml`, antes de `<application`:

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
```

En el mismo archivo: `android:label="Nevados"`.

- [ ] **Step 5: Configurar iOS**

```powershell
$f = (Resolve-Path ios\Runner.xcodeproj\project.pbxproj).Path
$t = [IO.File]::ReadAllText($f)
$t = $t -replace 'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;'
$t = $t.Replace('co.nevados.nevadoApp', 'co.nevados.app')
[IO.File]::WriteAllText($f, $t)
Select-String -Path $f -Pattern 'IPHONEOS_DEPLOYMENT_TARGET|PRODUCT_BUNDLE_IDENTIFIER'
```

Esperado: todos los objetivos en `15.0` e identificadores que empiezan por `co.nevados.app`. Si existe `ios/Podfile`, poner `platform :ios, '15.0'`.

- [ ] **Step 6: Contenido y README**

Crear `assets/content/.gitkeep` vacío (no declararlo aún en `pubspec.yaml`).

Reemplazar `README.md`:

````markdown
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
````

- [ ] **Step 7: Verificar**

```powershell
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
fvm flutter build apk --release
Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [IO.Compression.ZipFile]::OpenRead((Resolve-Path build\app\outputs\flutter-apk\app-release.apk).Path)
$z.Entries.FullName | Where-Object { $_ -like 'lib/*' } | ForEach-Object { $_.Split('/')[1] } | Sort-Object -Unique
$z.Dispose()
```

Esperado: sin problemas, pruebas pasan, ambos APK se generan y la lista muestra solo `arm64-v8a`.

- [ ] **Step 8: Commit**

```powershell
git add .fvmrc .gitignore .metadata README.md analysis_options.yaml pubspec.yaml pubspec.lock lib test android ios web assets
git status --short
git commit -m "chore: crear proyecto Flutter 3.47.9" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Pantalla de inicio, tema y navegación

**Files:**
- Create: `lib/app/app.dart`, `lib/app/theme.dart`, `lib/features/home/home_screen.dart`, `lib/features/emergency/emergency_screen.dart`, `lib/features/chat/chat_screen.dart`, `lib/features/location/location_screen.dart`, `lib/features/map/map_screen.dart`
- Modify: `lib/main.dart`
- Test: `test/home_test.dart` (borrar `test/widget_test.dart`)

**Interfaces:**
- Produces: `NevadoApp`, `HomeScreen`, `EmergencyScreen`, `ChatScreen`, `LocationScreen`, `MapScreen` (todos con constructor `const` sin argumentos obligatorios).

- [ ] **Step 1: Escribir la prueba** (`test/home_test.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/app/app.dart';

const labels = ['Emergencias', 'Asistente', 'Mi ubicación', 'Mapa'];

Future<void> openAndReturn(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, label), findsOneWidget);
  await tester.pageBack();
  await tester.pumpAndSettle();
  expect(find.textContaining('no reemplaza'), findsOneWidget);
}

void main() {
  testWidgets('cada botón abre su pantalla y permite volver', (tester) async {
    await tester.pumpWidget(const NevadoApp());
    expect(find.textContaining('no reemplaza'), findsOneWidget);
    for (final label in labels) {
      await openAndReturn(tester, label);
    }
  });

  for (final (name, size) in [
    ('vertical pequeña', const Size(320, 568)),
    ('horizontal', const Size(568, 320)),
  ]) {
    testWidgets('texto al 200 % en pantalla $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(const NevadoApp());
      for (final label in labels) {
        await openAndReturn(tester, label);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
```

- [ ] **Step 2: Verificar que falla**

Run: `fvm flutter test test/home_test.dart`
Esperado: FAIL, no existe `package:nevado_app/app/app.dart`.

- [ ] **Step 3: Implementar**

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';

import 'app/app.dart';

void main() => runApp(const NevadoApp());
```

`lib/app/theme.dart`:

```dart
import 'package:flutter/material.dart';

final appTheme = ThemeData(
  colorScheme: const ColorScheme.highContrastLight(),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(80),
      padding: const EdgeInsets.all(16),
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  ),
);
```

`lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'theme.dart';

class NevadoApp extends StatelessWidget {
  const NevadoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nevados',
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
```

`lib/features/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../chat/chat_screen.dart';
import '../emergency/emergency_screen.dart';
import '../location/location_screen.dart';
import '../map/map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _entries = <(String, IconData, Widget)>[
    ('Emergencias', Icons.emergency, EmergencyScreen()),
    ('Asistente', Icons.chat, ChatScreen()),
    ('Mi ubicación', Icons.my_location, LocationScreen()),
    ('Mapa', Icons.map, MapScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nevados')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              const Text(
                'Esta app orienta y no reemplaza a guías ni a '
                'Parques Nacionales Naturales.',
              ),
              for (final (label, icon, screen) in _entries)
                FilledButton.icon(
                  icon: Icon(icon, size: 32),
                  label: Text(label),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => screen),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`lib/features/emergency/emergency_screen.dart`:

```dart
import 'package:flutter/material.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Emergencias')));
  }
}
```

`lib/features/chat/chat_screen.dart`:

```dart
import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Asistente')));
  }
}
```

`lib/features/location/location_screen.dart`:

```dart
import 'package:flutter/material.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Mi ubicación')));
  }
}
```

`lib/features/map/map_screen.dart`:

```dart
import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Mapa')));
  }
}
```

Borrar `test/widget_test.dart`.

- [ ] **Step 4: Verificar que pasa**

```powershell
fvm flutter test
fvm flutter analyze
```

Esperado: 3 pruebas pasan, sin problemas.

- [ ] **Step 5: Commit**

```powershell
git add lib test
git commit -m "feat: pantalla de inicio y navegación base" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Contratos de motor y búsqueda

**Files:**
- Create: `lib/core/ai/llm_engine.dart`, `lib/core/ai/retriever.dart`

**Interfaces:**
- Produces: `LlmEngine.generate(String) -> Stream<String>`, `Retriever.retrieve(String, {int limit}) -> Future<List<Fragment>>`, `Fragment`.

Sin prueba propia: son contratos sin lógica. `analyze` los valida.

- [ ] **Step 1: Crear `lib/core/ai/llm_engine.dart`**

```dart
/// Contrato propio del motor de lenguaje.
abstract interface class LlmEngine {
  /// Emite la respuesta por partes a medida que se genera.
  Stream<String> generate(String prompt);
}
```

- [ ] **Step 2: Crear `lib/core/ai/retriever.dart`**

```dart
/// Fragmento oficial recuperado de la base de conocimiento.
class Fragment {
  const Fragment({
    required this.text,
    required this.source,
    required this.date,
    required this.score,
  });

  final String text;
  final String source;
  final DateTime date;

  /// Similitud con la consulta. Mayor es más parecido.
  final double score;
}

/// Contrato propio de búsqueda en la base de conocimiento.
abstract interface class Retriever {
  Future<List<Fragment>> retrieve(String query, {int limit = 3});
}
```

- [ ] **Step 3: Verificación final**

```powershell
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
fvm flutter build web
```

Esperado: todo pasa.

- [ ] **Step 4: Commit**

```powershell
git add lib/core
git commit -m "feat: contratos de motor LLM y búsqueda" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 5: Prueba manual (usuario)**

Abrir el repo en VS Code, iniciar el emulador, pulsar `F5` y abrir las cuatro pantallas.
