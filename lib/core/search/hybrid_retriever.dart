import '../ai/retriever.dart';
import 'normalize.dart';

/// Fragmentos ordenados por significado, ya filtrados por similitud mínima.
typedef Embedder = Future<List<Fragment>> Function(String query);

/// Puntaje mínimo por palabras: una coincidencia en la ruta, o varias en descripción y texto.
const umbralPalabras = 3;

/// Combina búsqueda por palabras y por significado (Reciprocal Rank Fusion).
/// Sin ningún resultado sobre los umbrales devuelve lista vacía: la app se abstiene.
class HybridRetriever implements Retriever {
  HybridRetriever({required this.lexical, this.embedder});

  final List<Fragment> lexical;
  final Embedder? embedder;

  @override
  Future<List<Fragment>> retrieve(String query, {int limit = 5}) async {
    final semanticos = embedder == null ? <Fragment>[] : await embedder!(query);
    final palabras = _porPalabras(query);
    final puntos = <String, double>{};
    final fragmentos = <String, Fragment>{};
    void sumar(List<Fragment> lista, double peso) {
      for (var i = 0; i < lista.length && i < 20; i++) {
        final f = lista[i];
        fragmentos[f.id] = f;
        puntos[f.id] = (puntos[f.id] ?? 0) + peso / (60 + i + 1);
      }
    }

    sumar(semanticos, 1.5);
    sumar(palabras, 1);
    final orden = fragmentos.keys.toList()..sort((a, b) => puntos[b]!.compareTo(puntos[a]!));
    return [for (final id in orden.take(limit)) fragmentos[id]!];
  }

  List<Fragment> _porPalabras(String query) {
    final terminos = tokenizar(query).toSet();
    final resultados = <({Fragment f, int puntos, int i})>[];
    for (var i = 0; i < lexical.length; i++) {
      final f = lexical[i];
      final ruta = tokenizar(f.path).toSet();
      final descripcion = tokenizar(f.description).toSet();
      final texto = tokenizar(f.text).toSet();
      var puntos = 0;
      for (final t in terminos) {
        if (ruta.contains(t)) puntos += 3;
        if (descripcion.contains(t)) puntos += 2;
        if (texto.contains(t)) puntos += 1;
      }
      if (puntos >= umbralPalabras) resultados.add((f: f, puntos: puntos, i: i));
    }
    resultados.sort((a, b) => a.puntos != b.puntos ? b.puntos - a.puntos : a.i - b.i);
    return [for (final r in resultados) r.f];
  }
}
