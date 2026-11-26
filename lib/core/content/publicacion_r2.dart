/// Publicación del contenido en Cloudflare R2 a través del Worker de `cloudflare/`. Dart puro (dart:io).
///
/// El paquete viaja y se guarda cifrado: R2 nunca ve el texto. El visitante descarga sin cuenta; solo el
/// guía publica, con la clave compartida del Worker.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const rutaPaqueteR2 = 'contenido.nev';
const rutaManifiestoR2 = 'manifiesto.json';
const _maximo = 20 * 1024 * 1024;

class ManifiestoR2 {
  const ManifiestoR2({required this.version, required this.publicado, required this.bytes, required this.sha256});

  final int version;
  final DateTime publicado;
  final int bytes;
  final String sha256;

  factory ManifiestoR2.desdeJson(Map<String, dynamic> json) => ManifiestoR2(
    version: json['version'] as int,
    publicado: DateTime.parse(json['publicado'] as String),
    bytes: json['bytes'] as int,
    sha256: json['sha256'] as String,
  );
}

/// Otro guía publicó antes: hay que descargar su versión y repetir.
class ConflictoDeVersion implements Exception {
  const ConflictoDeVersion(this.actual);
  final int actual;

  @override
  String toString() => 'Ya existe la versión $actual.';
}

class ClienteR2 {
  ClienteR2(this.base, {this.clave, HttpClient? cliente}) : _cliente = cliente ?? HttpClient();

  /// Dirección del Worker, por ejemplo `https://nevados-contenido.<cuenta>.workers.dev/`.
  final Uri base;

  /// Clave para publicar. Solo la tiene la app del guía.
  final String? clave;
  final HttpClient _cliente;

  static const _espera = Duration(seconds: 20);

  /// `null` si todavía no se ha publicado nada.
  Future<ManifiestoR2?> manifiesto() async {
    final (estado, cuerpo) = await _pedir('GET', rutaManifiestoR2);
    if (estado == HttpStatus.notFound) return null;
    _exigir(estado, HttpStatus.ok);
    return ManifiestoR2.desdeJson(jsonDecode(utf8.decode(cuerpo)) as Map<String, dynamic>);
  }

  Future<Uint8List> descargar() async {
    final (estado, cuerpo) = await _pedir('GET', rutaPaqueteR2);
    _exigir(estado, HttpStatus.ok);
    return cuerpo;
  }

  /// Sube [paquete] como la versión siguiente a [versionBase]. Lanza [ConflictoDeVersion] si alguien
  /// publicó antes.
  Future<ManifiestoR2> publicar(Uint8List paquete, {required int versionBase}) async {
    final (estado, cuerpo) = await _pedir('PUT', rutaPaqueteR2, cuerpo: paquete, versionBase: versionBase);
    if (estado == HttpStatus.conflict) {
      final datos = jsonDecode(utf8.decode(cuerpo)) as Map<String, dynamic>;
      throw ConflictoDeVersion(datos['version'] as int);
    }
    if (estado == HttpStatus.unauthorized || estado == HttpStatus.forbidden) {
      throw const HttpException('La clave de publicación no es válida.');
    }
    _exigir(estado, HttpStatus.ok);
    return ManifiestoR2.desdeJson(jsonDecode(utf8.decode(cuerpo)) as Map<String, dynamic>);
  }

  void cerrar() => _cliente.close(force: true);

  void _exigir(int estado, int esperado) {
    if (estado != esperado) throw HttpException('Respuesta $estado del servidor de contenido.');
  }

  Future<(int, Uint8List)> _pedir(String metodo, String ruta, {Uint8List? cuerpo, int? versionBase}) async {
    Future<(int, Uint8List)> hacer() async {
      final peticion = await _cliente.openUrl(metodo, base.resolve(ruta));
      if (clave != null && metodo != 'GET') peticion.headers.set(HttpHeaders.authorizationHeader, 'Bearer $clave');
      if (versionBase != null) peticion.headers.set('x-version-base', '$versionBase');
      if (cuerpo != null) {
        peticion.headers.contentType = ContentType.binary;
        peticion.contentLength = cuerpo.length;
        peticion.add(cuerpo);
      }
      final respuesta = await peticion.close();
      final bytes = BytesBuilder(copy: false);
      await for (final parte in respuesta) {
        bytes.add(parte);
        if (bytes.length > _maximo) throw const HttpException('Respuesta demasiado grande.');
      }
      return (respuesta.statusCode, bytes.takeBytes());
    }

    return hacer().timeout(_espera);
  }
}
