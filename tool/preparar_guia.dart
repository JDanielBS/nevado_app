// Crea secrets/guia.env, con el que se compila la app del guía.
//
// Uso, desde la raíz del proyecto:
//   dart run tool/preparar_guia.dart            crea el archivo; conserva las claves que ya existan
//   dart run tool/preparar_guia.dart --nuevas   cambia la llave del contenido y la clave de publicación
//
// Toma el token del modelo y CONTENIDO_URL de .env, y la clave de los pases de secrets/pase_privada.key.
// Después de --nuevas: actualizar el secreto del Worker (cloudflare/README.md), compilar la app del guía y
// publicar de nuevo. Los pases y paquetes anteriores dejan de abrir.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'pases.dart';

const rutaGuia = 'secrets/guia.env';

Map<String, String> leerEnv(String ruta) {
  final archivo = File(ruta);
  if (!archivo.existsSync()) return {};
  return {
    for (final linea in archivo.readAsLinesSync())
      if (linea.contains('=') && !linea.trimLeft().startsWith('#'))
        linea.substring(0, linea.indexOf('=')).trim(): linea.substring(linea.indexOf('=') + 1).trim(),
  };
}

String azar(int bytes) {
  final r = Random.secure();
  return base64Url.encode([for (var i = 0; i < bytes; i++) r.nextInt(256)]).replaceAll('=', '');
}

Future<void> main(List<String> argumentos) async {
  final nuevas = argumentos.contains('--nuevas');
  // Comprueba que la clave privada corresponda a la pública incluida en la app.
  await cargarClaves();
  final anterior = leerEnv(rutaGuia);
  final visitante = leerEnv('.env');
  final valores = {
    'HUGGINGFACE_TOKEN': visitante['HUGGINGFACE_TOKEN'] ?? anterior['HUGGINGFACE_TOKEN'] ?? '',
    'CONTENIDO_URL': visitante['CONTENIDO_URL'] ?? anterior['CONTENIDO_URL'] ?? '',
    'PASE_PRIVADA': File(rutaPrivada).readAsStringSync().trim(),
    'LLAVE_CONTENIDO': (nuevas ? null : anterior['LLAVE_CONTENIDO']) ?? azar(32),
    'PUBLICAR_CLAVE': (nuevas ? null : anterior['PUBLICAR_CLAVE']) ?? azar(32),
  };
  File(rutaGuia)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${valores.entries.map((e) => '${e.key}=${e.value}').join('\n')}\n');
  stdout.writeln('Listo: $rutaGuia. No lo compartas ni lo subas al repositorio.');
  for (final c in ['HUGGINGFACE_TOKEN', 'CONTENIDO_URL']) {
    if (valores[c]!.isEmpty) stdout.writeln('Aviso: falta $c en .env.');
  }
  stdout.writeln('Clave para el Worker (npx wrangler secret put CLAVE_PUBLICAR): está en PUBLICAR_CLAVE.');
}
