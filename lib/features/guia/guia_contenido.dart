import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/content/card.dart';
import '../../core/content/carpeta_contenido.dart';
import '../../core/content/content_package.dart';
import '../../core/content/contenido_guia.dart';
import '../../core/content/fuente_guia.dart';
import '../../core/content/publicacion_r2.dart';
import '../../core/content/seccion.dart';
import '../../core/search/search.dart';

/// Contenido que edita el guía. Vive en una carpeta privada de su teléfono, un `.md` por sección.
///
/// La primera vez se llena con el contenido inicial incluido en la app del guía. Desde ahí, el guía lo
/// edita, lo publica en R2 cuando tiene internet y lo comparte por su zona wifi.
class GuiaContenido extends ChangeNotifier implements FuenteGuia {
  GuiaContenido({required this.emergencia, required this.carpeta});

  @override
  final List<Ficha> emergencia;
  final Directory carpeta;

  List<SeccionGuia> _secciones = const [];
  IndiceGuia _indice = IndiceGuia.vacio;
  _Estado _estado = const _Estado(version: 0, sinPublicar: false);

  @override
  List<SeccionGuia> get secciones => _secciones;
  @override
  IndiceGuia get indice => _indice;

  /// Versión de R2 en la que se basa el contenido local. 0: nunca se publicó ni descargó.
  int get version => _estado.version;

  /// Hay cambios guardados en el teléfono que no se han publicado en internet.
  bool get sinPublicar => _estado.sinPublicar;

  File get _archivoEstado => File('${carpeta.path}/estado.json');

  /// Carga la carpeta. Si está vacía, la llena con [semilla] (archivo y Markdown).
  Future<void> iniciar({Future<List<(String, String)>> Function()? semilla}) async {
    final vacia = !carpeta.existsSync() || !carpeta.listSync().any((f) => f.path.endsWith('.md'));
    if (vacia && semilla != null) {
      escribirCarpeta(carpeta, ContenidoGuia(archivos: await semilla()));
    }
    if (_archivoEstado.existsSync()) {
      _estado = _Estado.desdeJson(jsonDecode(_archivoEstado.readAsStringSync()) as Map<String, dynamic>);
    }
    _recargar();
  }

  void _recargar() {
    _secciones = carpeta.existsSync() ? leerCarpeta(carpeta).secciones : const [];
    _indice = IndiceGuia.de(_secciones);
    notifyListeners();
  }

  void _guardarEstado(_Estado estado) {
    _estado = estado;
    carpeta.createSync(recursive: true);
    _archivoEstado.writeAsStringSync(jsonEncode(estado.json()));
  }

  /// Contenido actual, listo para cifrar.
  ContenidoGuia contenido() => ContenidoGuia(
    archivos: [for (final s in _secciones) (s.archivo, escribirSeccion(s))],
    publicado: DateTime.now(),
  );

  Future<Uint8List> paqueteCifrado(List<int> llave) => cifrarPaquete(contenido().codificar(), llave);

  void _escribir(List<SeccionGuia> secciones) {
    escribirCarpeta(
      carpeta,
      ContenidoGuia(archivos: [for (final s in secciones) (s.archivo, escribirSeccion(s))]),
    );
    _guardarEstado(_Estado(version: _estado.version, sinPublicar: true));
    _recargar();
  }

  SeccionGuia _buscar(String archivo) => _secciones.firstWhere((s) => s.archivo == archivo);

  /// Guarda [tema] en la sección: reemplaza el de la posición [posicion] o lo agrega al final.
  void guardarTema(String archivo, Tema tema, {int? posicion}) {
    final s = _buscar(archivo);
    if (posicion == null) {
      s.temas.add(tema);
    } else {
      s.temas[posicion] = tema;
    }
    _escribir(_secciones);
  }

  void borrarTema(String archivo, int posicion) {
    _buscar(archivo).temas.removeAt(posicion);
    _escribir(_secciones);
  }

  /// Crea una sección vacía al final y devuelve su archivo.
  String crearSeccion(String titulo, {String? descripcion}) {
    final archivo = archivoParaTitulo(titulo, _secciones.map((s) => s.archivo));
    _escribir([
      ..._secciones,
      SeccionGuia(archivo: archivo, titulo: titulo.trim(), descripcion: descripcion),
    ]);
    return archivo;
  }

  void editarSeccion(String archivo, {required String titulo, String? descripcion}) {
    _buscar(archivo)
      ..titulo = titulo.trim()
      ..descripcion = descripcion;
    _escribir(_secciones);
  }

  /// Las secciones de avisos, estaciones y emergencias no se borran.
  bool sePuedeBorrar(String archivo) => !seccionesFijas.contains(archivo);

  void borrarSeccion(String archivo) {
    if (!sePuedeBorrar(archivo)) throw StateError('La sección $archivo no se puede borrar.');
    _escribir([..._secciones.where((s) => s.archivo != archivo)]);
  }

  void moverSeccion(String archivo, int delta) {
    final lista = [..._secciones];
    final i = lista.indexWhere((s) => s.archivo == archivo);
    final j = (i + delta).clamp(0, lista.length - 1);
    if (i < 0 || i == j) return;
    lista.insert(j, lista.removeAt(i));
    _escribir(lista);
  }

  /// Publica en R2. Lanza [ConflictoDeVersion] si otro guía publicó antes.
  Future<ManifiestoR2> publicar(ClienteR2 cliente, List<int> llave) async {
    final manifiesto = await cliente.publicar(await paqueteCifrado(llave), versionBase: _estado.version);
    _guardarEstado(_Estado(version: manifiesto.version, sinPublicar: false));
    notifyListeners();
    return manifiesto;
  }

  /// Trae la versión publicada si es más nueva. Devuelve `null` si ya estaba al día.
  ///
  /// Reemplaza el contenido local: quien llama debe advertir si hay cambios [sinPublicar].
  Future<ManifiestoR2?> actualizar(ClienteR2 cliente, List<int> llave) async {
    final manifiesto = await cliente.manifiesto();
    if (manifiesto == null || manifiesto.version <= _estado.version && !_estado.sinPublicar) return null;
    final abierto = ContenidoGuia.decodificar(await descifrarPaquete(await cliente.descargar(), llave));
    escribirCarpeta(carpeta, abierto);
    _guardarEstado(_Estado(version: manifiesto.version, sinPublicar: false));
    _recargar();
    return manifiesto;
  }
}

class _Estado {
  const _Estado({required this.version, required this.sinPublicar});
  final int version;
  final bool sinPublicar;

  factory _Estado.desdeJson(Map<String, dynamic> j) =>
      _Estado(version: j['version'] as int? ?? 0, sinPublicar: j['sinPublicar'] as bool? ?? false);

  Map<String, Object> json() => {'version': version, 'sinPublicar': sinPublicar};
}
