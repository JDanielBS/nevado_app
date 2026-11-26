import 'dart:convert';
import 'dart:io';

import 'contenido_guia.dart';

/// Archivo con el orden de las secciones dentro de la carpeta de contenido.
const archivoOrden = 'orden.json';

/// Lee una carpeta de secciones `.md`. El orden sale de `orden.json`; las que no figuran van al final,
/// por nombre.
ContenidoGuia leerCarpeta(Directory carpeta, {DateTime? publicado}) {
  final orden = File('${carpeta.path}/$archivoOrden');
  final listadas = orden.existsSync()
      ? (jsonDecode(orden.readAsStringSync()) as List).cast<String>()
      : <String>[];
  final presentes = {
    for (final f in carpeta.listSync().whereType<File>())
      if (f.path.endsWith('.md')) f.uri.pathSegments.last,
  };
  final nombres = [
    for (final n in listadas)
      if (presentes.contains(n)) n,
    ...(presentes.difference(listadas.toSet()).toList()..sort()),
  ];
  return ContenidoGuia(
    archivos: [for (final n in nombres) (n, File('${carpeta.path}/$n').readAsStringSync())],
    publicado: publicado,
  );
}

/// Escribe el contenido en [carpeta]: un `.md` por sección y `orden.json`. Borra las secciones que ya no
/// están. Cada archivo se escribe aparte y se renombra, para no dejar uno a medias.
void escribirCarpeta(Directory carpeta, ContenidoGuia contenido) {
  carpeta.createSync(recursive: true);
  void escribir(String nombre, String texto) {
    final temporal = File('${carpeta.path}/$nombre.tmp')..writeAsStringSync(texto, flush: true);
    temporal.renameSync('${carpeta.path}/$nombre');
  }

  final nombres = {for (final (n, _) in contenido.archivos) n};
  for (final (nombre, md) in contenido.archivos) {
    escribir(nombre, md);
  }
  escribir(archivoOrden, jsonEncode(nombres.toList()));
  for (final f in carpeta.listSync().whereType<File>()) {
    final nombre = f.uri.pathSegments.last;
    if (nombre.endsWith('.md') && !nombres.contains(nombre)) f.deleteSync();
  }
}
