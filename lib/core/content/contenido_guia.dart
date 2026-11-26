/// Paquete de contenido que el guía entrega al visitante. Dart puro.
///
/// Es un JSON con las secciones en Markdown, en el orden en que se muestran. Viaja cifrado
/// (ver `content_package.dart`) y el visitante solo lo descifra en memoria.
library;

import 'dart:convert';

import 'seccion.dart';

const formatoContenido = 1;

class ContenidoGuia {
  const ContenidoGuia({required this.archivos, this.publicado, this.verificado = false});

  /// Nombre del archivo y su Markdown, en orden de pantalla.
  final List<(String, String)> archivos;
  final DateTime? publicado;

  /// Todo el paquete fue revisado. Hoy siempre es falso.
  final bool verificado;

  List<SeccionGuia> get secciones => [
    for (final (archivo, md) in archivos) leerSeccion(archivo, md, verificada: verificado),
  ];

  List<int> codificar() => utf8.encode(
    jsonEncode({
      'formato': formatoContenido,
      if (publicado != null) 'publicado': publicado!.toIso8601String(),
      'verificado': verificado,
      'secciones': [
        for (final (archivo, md) in archivos) {'archivo': archivo, 'md': md},
      ],
    }),
  );

  /// Lanza [FormatException] si no es un paquete de este formato.
  factory ContenidoGuia.decodificar(List<int> bytes) {
    final datos = jsonDecode(utf8.decode(bytes));
    if (datos is! Map<String, dynamic> || datos['formato'] != formatoContenido) {
      throw const FormatException('El contenido no tiene el formato esperado.');
    }
    final publicado = datos['publicado'] as String?;
    return ContenidoGuia(
      archivos: [
        for (final s in datos['secciones'] as List)
          (_archivoSeguro((s as Map)['archivo'] as String), s['md'] as String),
      ],
      publicado: publicado == null ? null : DateTime.parse(publicado),
      verificado: datos['verificado'] == true,
    );
  }
}

/// Solo un nombre `.md` simple: el nombre llega de la red y el guía lo usa como archivo.
String _archivoSeguro(String nombre) {
  if (!RegExp(r'^[a-z0-9][a-z0-9_-]*\.md$').hasMatch(nombre)) {
    throw FormatException('Nombre de sección no válido: $nombre');
  }
  return nombre;
}

/// Nombre de archivo para una sección nueva a partir de su título.
String archivoParaTitulo(String titulo, Iterable<String> existentes) {
  const tildes = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};
  final base = titulo
      .toLowerCase()
      .split('')
      .map((c) => tildes[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final raiz = base.isEmpty ? 'seccion' : base;
  var nombre = '$raiz.md';
  for (var i = 2; existentes.contains(nombre); i++) {
    nombre = '$raiz-$i.md';
  }
  return nombre;
}
