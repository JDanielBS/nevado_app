import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../content/markdown_fragments.dart';
import '../search/hybrid_retriever.dart';
import 'edge_llm_engine.dart';
import 'retriever.dart';

const _carpeta = 'assets/conocimiento/';
const _modelo = 'embeddinggemma-2-text-270m.litertlm';

/// Similitud mínima para aceptar un fragmento por significado.
final umbralCoseno = double.parse(const String.fromEnvironment('UMBRAL_COSENO', defaultValue: '0.35'));

/// Conocimiento de la guía: los `.md` empaquetados y su índice por significado.
/// Sin el modelo de embeddings sigue funcionando solo por palabras.
class KnowledgeBase implements Retriever {
  List<Fragment> fragmentos = const [];
  String plantilla = '';

  /// Texto de avance para la pantalla; vacío cuando terminó.
  final estado = ValueNotifier('');

  EmbeddingModel? _embedder;
  final _vectores = <String, List<double>>{};
  Future<void>? _carga;
  Future<void>? _indice;

  Future<void> cargar() => _carga ??= _cargar();

  Future<void> _cargar() async {
    final lista = await AssetManifest.loadFromAssetBundle(rootBundle);
    final rutas = lista.listAssets().where((r) => r.startsWith('${_carpeta}secciones/') && r.endsWith('.md')).toList()
      ..sort();
    fragmentos = [
      for (final r in rutas) ...parseMarkdownFragments(await rootBundle.loadString(r), path: r),
    ];
    if (rutas.isNotEmpty) plantilla = await rootBundle.loadString('${_carpeta}prompt_sistema.md');
    debugPrint('RAG fragmentos=${fragmentos.length}');
  }

  /// Carga el modelo de embeddings y vectoriza lo que falte. Se puede llamar varias veces.
  Future<void> indexar() => _indice ??= _indexar();

  Future<void> _indexar() async {
    try {
      await cargar();
      final archivo = File('${EdgeLlmEngine.carpetaModelos}/$_modelo');
      if (!await archivo.exists()) {
        debugPrint('RAG sin modelo de embeddings en ${archivo.path}');
        return;
      }
      estado.value = 'Preparando la búsqueda…';
      final reloj = Stopwatch()..start();
      await EdgeLlmEngine.iniciarPaquete();
      await FlutterEdgeAi.installEmbedder().modelFromFile(archivo.path).install();
      final embedder = await FlutterEdgeAi.getActiveEmbedder();
      debugPrint('RAG embedder ms=${reloj.elapsedMilliseconds}');

      // Los vectores se guardan en disco por huella del texto: solo se recalcula lo que cambie.
      final cache = File('${EdgeLlmEngine.carpetaModelos}/indice.json');
      var guardado = <String, dynamic>{};
      try {
        final datos = jsonDecode(await cache.readAsString()) as Map<String, dynamic>;
        if (datos['modelo'] == _modelo) guardado = datos['vectores'] as Map<String, dynamic>;
      } catch (_) {
        // Sin índice previo o dañado: se calcula de nuevo.
      }
      final nuevo = <String, List<double>>{};
      reloj.reset();
      for (var i = 0; i < fragmentos.length; i++) {
        final f = fragmentos[i];
        final texto = '${f.path}. ${f.description} ${f.text}';
        final huella = sha256.convert(utf8.encode(texto)).toString();
        final previo = guardado[huella] as List?;
        final vector = previo != null
            ? [for (final x in previo) (x as num).toDouble()]
            : _unitario(await embedder.embed(EmbeddingInput.text(texto), taskType: TaskType.retrievalDocument));
        nuevo[huella] = vector;
        _vectores[f.id] = vector;
        if (i % 10 == 0) estado.value = 'Preparando la búsqueda ${i * 100 ~/ fragmentos.length} %';
      }
      await cache.writeAsString(jsonEncode({'modelo': _modelo, 'vectores': nuevo}), flush: true);
      _embedder = embedder;
      debugPrint('RAG indice ms=${reloj.elapsedMilliseconds}');
    } catch (e, s) {
      debugPrint('RAG embeddings no disponibles: $e\n$s');
    } finally {
      estado.value = '';
    }
  }

  @override
  Future<List<Fragment>> retrieve(String query, {int limit = 5}) async {
    await cargar();
    final reloj = Stopwatch()..start();
    final r = await HybridRetriever(lexical: fragmentos, embedder: _embedder == null ? null : _porSignificado)
        .retrieve(query, limit: limit);
    debugPrint('RAG "$query" ms=${reloj.elapsedMilliseconds} -> ${r.map((f) => f.path).join(' | ')}');
    return r;
  }

  Future<List<Fragment>> _porSignificado(String query) async {
    final q = _unitario(await _embedder!.embed(EmbeddingInput.text(query), taskType: TaskType.retrievalQuery));
    final puntos = [
      for (final f in fragmentos)
        if (_vectores[f.id] case final v?) (f: f, s: _punto(q, v)),
    ]..sort((a, b) => b.s.compareTo(a.s));
    if (puntos.isNotEmpty) debugPrint('RAG coseno max=${puntos.first.s.toStringAsFixed(3)} ${puntos.first.f.path}');
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
