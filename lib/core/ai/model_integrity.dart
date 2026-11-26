import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'llm_engine.dart';

Future<String> _sha256Of(String path) async =>
    (await sha256.bind(File(path).openRead()).first).toString();

/// Comprueba que el archivo en [path] tenga el SHA-256 [expected].
///
/// Si coincide deja una marca junto al archivo para no recalcularlo en cada
/// arranque. Si no coincide llama a [onCorrupt] y lanza
/// [CorruptModelException].
// ponytail: la marca no detecta daños posteriores a la primera verificación.
Future<void> verifyModelFile(
  String path,
  String expected, {
  required Future<void> Function() onCorrupt,
}) async {
  final marker = File('$path.sha256');
  if (await marker.exists() && await marker.readAsString() == expected) return;

  final watch = Stopwatch()..start();
  // En otro hilo: son cientos de MB y la pantalla no debe congelarse.
  final actual = await compute(_sha256Of, path);
  debugPrint('Integridad del modelo: ${watch.elapsedMilliseconds} ms');
  if (actual != expected) {
    await onCorrupt();
    throw const CorruptModelException();
  }
  await marker.writeAsString(expected, flush: true);
}
