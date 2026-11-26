import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../content/seccion.dart';
import '../search/hybrid_retriever.dart';
import '../search/search.dart';
import 'edge_llm_engine.dart';

/// Modelo de embeddings. Se copia por cable a la carpeta de modelos de la app (ver COMANDOS.md).
const modeloEmbeddings = 'embeddinggemma-2-text-270m.litertlm';

/// Similitud mínima para aceptar un fragmento por significado.
final umbralCoseno = double.parse(const String.fromEnvironment('UMBRAL_COSENO', defaultValue: '0.35'));

/// Búsqueda de la guía: por palabras ([IndiceGuia]) y, si está el modelo de embeddings, por significado,
/// combinadas con Reciprocal Rank Fusion.
///
/// Trabaja sobre los fragmentos que la app tiene en memoria (del paquete cifrado), no sobre archivos del APK.
/// Sin el modelo de embeddings sigue funcionando solo por palabras.
class KnowledgeBase {
  /// Texto de avance para la pantalla; vacío cuando terminó.
  final estado = ValueNotifier('');

  EmbeddingModel? _embedder;
  Future<EmbeddingModel?>? _carga;
  IndiceGuia _indice = IndiceGuia.vacio;
  final _vectores = <Fragmento, List<double>>{};
  Future<void>? _indexando;

  /// Vectoriza los fragmentos de [indice] que falten. Los vectores se guardan en disco por huella del texto:
  /// solo se recalcula lo que cambió. Se puede llamar cada vez que cambie el contenido.
  Future<void> indexar(IndiceGuia indice) {
    if (identical(indice, _indice) && _indexando != null) return _indexando!;
    _indice = indice;
    return _indexando = _indexar(indice);
  }

  Future<EmbeddingModel?> _cargarModelo() async {
    final archivo = File('${await EdgeLlmEngine.carpetaModelos()}/$modeloEmbeddings');
    if (!await archivo.exists()) {
      debugPrint('RAG sin modelo de embeddings en ${archivo.path}');
      return null;
    }
    await EdgeLlmEngine.iniciarPaquete();
    await FlutterEdgeAi.installEmbedder().modelFromFile(archivo.path).install();
    return FlutterEdgeAi.getActiveEmbedder();
  }

  Future<void> _indexar(IndiceGuia indice) async {
    try {
      final embedder = await (_carga ??= _cargarModelo());
      if (embedder == null || indice.fragmentos.isEmpty) return;
      estado.value = 'Preparando la búsqueda…';
      final reloj = Stopwatch()..start();
      final cache = File('${await EdgeLlmEngine.carpetaModelos()}/indice.json');
      var guardado = <String, dynamic>{};
      try {
        final datos = jsonDecode(await cache.readAsString()) as Map<String, dynamic>;
        if (datos['modelo'] == modeloEmbeddings) guardado = datos['vectores'] as Map<String, dynamic>;
      } catch (_) {
        // Sin índice previo o dañado: se calcula de nuevo.
      }
      final nuevo = <String, List<double>>{};
      final fragmentos = indice.fragmentos;
      for (var i = 0; i < fragmentos.length; i++) {
        if (!identical(indice, _indice)) return; // Llegó otro contenido: se descarta este índice.
        final f = fragmentos[i];
        final texto = '${f.ruta}. ${f.descripcion} ${f.texto}';
        final huella = sha256.convert(utf8.encode(texto)).toString();
        final previo = guardado[huella] as List?;
        final vector = previo != null
            ? [for (final x in previo) (x as num).toDouble()]
            : _unitario(await embedder.embed(EmbeddingInput.text(texto), taskType: TaskType.retrievalDocument));
        nuevo[huella] = vector;
        _vectores[f] = vector;
        if (i % 10 == 0) estado.value = 'Preparando la búsqueda ${i * 100 ~/ fragmentos.length} %';
      }
      // El índice guarda vectores de texto público del parque, no datos del visitante.
      await cache.writeAsString(jsonEncode({'modelo': modeloEmbeddings, 'vectores': nuevo}), flush: true);
      _embedder = embedder;
      debugPrint('RAG indice ms=${reloj.elapsedMilliseconds} fragmentos=${fragmentos.length}');
    } catch (e, s) {
      debugPrint('RAG embeddings no disponibles: $e\n$s');
    } finally {
      estado.value = '';
    }
  }

  /// Fragmentos para [pregunta]. Vacío: la app se abstiene.
  Future<List<Fragmento>> buscar(IndiceGuia indice, String pregunta, {int limite = fragmentosPorPregunta}) async {
    final reloj = Stopwatch()..start();
    final porPalabras = [for (final r in indice.buscar(pregunta, max: 20)) r.fragmento];
    final porSignificado = _embedder != null && identical(indice, _indice) ? await _porSignificado(pregunta) : <Fragmento>[];
    final r = fusionar(semanticos: porSignificado, palabras: porPalabras, limite: limite);
    debugPrint('RAG "$pregunta" ms=${reloj.elapsedMilliseconds} -> ${r.map((f) => f.ruta).join(' | ')}');
    return r;
  }

  Future<List<Fragmento>> _porSignificado(String pregunta) async {
    final q = _unitario(await _embedder!.embed(EmbeddingInput.text(pregunta), taskType: TaskType.retrievalQuery));
    final puntos = [
      for (final MapEntry(key: f, value: v) in _vectores.entries)
        if (_indice.fragmentos.contains(f)) (f: f, s: _punto(q, v)),
    ]..sort((a, b) => b.s.compareTo(a.s));
    if (puntos.isNotEmpty) debugPrint('RAG coseno max=${puntos.first.s.toStringAsFixed(3)} ${puntos.first.f.ruta}');
    return [for (final p in puntos.take(20)) if (p.s >= umbralCoseno) p.f];
  }

  static double _punto(List<double> a, List<double> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  static List<double> _unitario(List<double> v) {
    final n = sqrt(_punto(v, v));
    return [for (final x in v) x / n];
  }
}
