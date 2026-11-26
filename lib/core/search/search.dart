import '../content/card.dart';
import 'normalize.dart';

const _pesoTitulo = 3;
const _pesoClave = 3;
const _pesoTexto = 1;

/// Puntaje mínimo para considerar que una ficha responde la consulta.
const umbralMinimo = 2;

/// Búsqueda local por coincidencia de palabras. Sin red.
/// Para reemplazarla por SQLite FTS5 o embeddings, conservar esta firma.
List<Coincidencia> buscar(String consulta, List<Ficha> fichas, {int max = 3, int umbral = umbralMinimo}) {
  final palabras = tokenizar(consulta).toSet();
  if (palabras.isEmpty) return [];

  final resultados = <Coincidencia>[];
  for (final ficha in fichas) {
    final enTitulo = tokenizar(ficha.titulo).toSet();
    final enClaves = ficha.palabrasClave.expand(tokenizar).toSet();
    final enTexto = tokenizar(ficha.texto).toSet();

    var puntaje = 0;
    for (final p in palabras) {
      if (enTitulo.contains(p)) puntaje += _pesoTitulo;
      if (enClaves.contains(p)) puntaje += _pesoClave;
      if (enTexto.contains(p)) puntaje += _pesoTexto;
    }
    if (puntaje >= umbral) resultados.add(Coincidencia(ficha, puntaje));
  }

  // Orden estable: a igual puntaje se conserva el orden original de las fichas.
  final indexados = resultados.indexed.toList()
    ..sort((a, b) {
      final porPuntaje = b.$2.puntaje.compareTo(a.$2.puntaje);
      return porPuntaje != 0 ? porPuntaje : a.$1.compareTo(b.$1);
    });
  return indexados.map((e) => e.$2).take(max).toList();
}
