import 'dart:math';

import '../content/seccion.dart';
import 'normalize.dart';

const _pesoRuta = 3;
const _pesoEstacion = 2;
const _pesoDescripcion = 2;
const _pesoTexto = 1;

/// Puntaje mínimo para considerar que un fragmento responde la consulta.
const umbralMinimo = 2;

/// Fragmentos que se entregan al modelo. Pocos, porque el contexto del modelo es corto (2048 tokens).
const fragmentosPorPregunta = 3;

class Resultado {
  const Resultado(this.fragmento, this.puntaje);
  final Fragmento fragmento;

  /// Coincidencias ponderadas por la rareza de cada palabra (IDF). Mayor es más relevante.
  final double puntaje;
}

/// Índice de búsqueda por palabras sobre los fragmentos de la guía. Sin red.
///
/// Las palabras que aparecen en pocos fragmentos pesan más (IDF, como en BM25): en "¿por qué las rocas
/// del Valle Lunar son rojas?", "rojas" decide más que "valle", que está en muchos fragmentos.
///
/// Se construye una vez por versión del contenido. Para pasar a embeddings, conservar [buscar].
class IndiceGuia {
  IndiceGuia(List<Fragmento> fragmentos)
    : _entradas = [
        for (final f in fragmentos)
          (
            fragmento: f,
            ruta: tokenizar(f.ruta).toSet(),
            estaciones: f.estaciones.expand(tokenizar).toSet(),
            descripcion: tokenizar(f.descripcion).toSet(),
            texto: tokenizar(f.texto).toSet(),
          ),
      ] {
    final apariciones = <String, int>{};
    for (final e in _entradas) {
      for (final p in {...e.ruta, ...e.estaciones, ...e.descripcion, ...e.texto}) {
        apariciones[p] = (apariciones[p] ?? 0) + 1;
      }
    }
    final n = _entradas.length;
    _idf = {for (final MapEntry(:key, :value) in apariciones.entries) key: log(1 + (n - value + 0.5) / (value + 0.5))};
  }

  late final Map<String, double> _idf;

  factory IndiceGuia.de(Iterable<SeccionGuia> secciones) => IndiceGuia(fragmentar(secciones));

  static final vacio = IndiceGuia(const []);

  final List<
    ({Fragmento fragmento, Set<String> ruta, Set<String> estaciones, Set<String> descripcion, Set<String> texto})
  >
  _entradas;

  int get cantidad => _entradas.length;

  List<Resultado> buscar(String consulta, {int max = fragmentosPorPregunta, int umbral = umbralMinimo}) {
    final palabras = tokenizar(consulta).toSet();
    if (palabras.isEmpty) return [];

    final resultados = <Resultado>[];
    for (final e in _entradas) {
      // El umbral usa el conteo simple; el orden, el conteo ponderado por rareza.
      var coincidencias = 0;
      var puntaje = 0.0;
      for (final p in palabras) {
        var peso = 0;
        if (e.ruta.contains(p)) peso += _pesoRuta;
        if (e.estaciones.contains(p)) peso += _pesoEstacion;
        if (e.descripcion.contains(p)) peso += _pesoDescripcion;
        if (e.texto.contains(p)) peso += _pesoTexto;
        coincidencias += peso;
        puntaje += peso * (_idf[p] ?? 0);
      }
      if (coincidencias >= umbral) resultados.add(Resultado(e.fragmento, puntaje));
    }
    // Orden estable: a igual puntaje, primero el que aparece antes en la guía.
    final ordenados = resultados.indexed.toList()
      ..sort((a, b) {
        final c = b.$2.puntaje.compareTo(a.$2.puntaje);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });
    return [for (final (_, r) in ordenados.take(max)) r];
  }
}
