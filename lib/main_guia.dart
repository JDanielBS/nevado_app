// App del guía. Se compila con: flutter build apk --flavor guia -t lib/main_guia.dart (ver COMANDOS.md).
//
// Sin pase ni vencimiento. Edita el contenido, lo publica en R2 cuando hay internet y lo comparte por la
// zona wifi del teléfono, donde también emite los pases de los visitantes.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'core/config/compilacion.dart';
import 'core/content/card_repository.dart';
import 'core/content/carpeta_contenido.dart';
import 'core/settings/settings.dart';
import 'features/chat/chat_screen.dart';
import 'features/guia/compartir_controller.dart';
import 'features/guia/compartir_screen.dart';
import 'features/guia/guia_contenido.dart';

/// Carpeta del contenido inicial, incluida solo en esta app (pubspec.yaml, sabor "guia").
const _semilla = 'contenido/secciones/';

Future<List<(String, String)>> _leerSemilla() async {
  final manifiesto = await AssetManifest.loadFromAssetBundle(rootBundle);
  final rutas = manifiesto.listAssets().where((r) => r.startsWith(_semilla)).toList();
  final orden = rutas.contains('$_semilla$archivoOrden')
      ? await rootBundle.loadString('$_semilla$archivoOrden')
      : '[]';
  final nombres = [for (final r in rutas) if (r.endsWith('.md')) r.substring(_semilla.length)];
  final listados = RegExp(r'"([^"]+\.md)"').allMatches(orden).map((m) => m[1]!).toList();
  nombres.sort((a, b) {
    int i(String n) => listados.contains(n) ? listados.indexOf(n) : listados.length;
    final c = i(a).compareTo(i(b));
    return c != 0 ? c : a.compareTo(b);
  });
  return [for (final n in nombres) (n, await rootBundle.loadString('$_semilla$n'))];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final privada = await getApplicationSupportDirectory();
  final contenido = GuiaContenido(
    emergencia: await cargarFichasDeEmergencia(),
    carpeta: Directory('${privada.path}/secciones'),
  );
  await contenido.iniciar(semilla: _leerSemilla);

  final compartir = CompartirController(
    contenido: contenido,
    carpetaTrabajo: Directory('${privada.path}/compartir'),
    clavePrivada: clavePrivadaPases,
    llave: llaveContenido,
    buscarModelo: () async {
      final ruta = await chatDeLaApp.engine.rutaInstalada();
      return ruta == null ? null : File(ruta);
    },
    // El APK del visitante se copia por cable a la carpeta de la app (ver COMANDOS.md).
    buscarApk: () async {
      final externa = await getExternalStorageDirectory();
      final apk = File('${externa?.path}/nevados.apk');
      return externa != null && apk.existsSync() ? apk : null;
    },
  );

  runApp(
    GuiaScope(
      contenido: contenido,
      compartir: compartir,
      child: NevadoApp(settings: Ajustes()..iniciar(), content: contenido, model: chatDeLaApp, esGuia: true),
    ),
  );
}
