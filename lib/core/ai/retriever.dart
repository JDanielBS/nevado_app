/// Fragmento oficial recuperado de la base de conocimiento.
class Fragment {
  const Fragment({
    required this.text,
    required this.source,
    required this.date,
    required this.score,
  });

  final String text;
  final String source;
  final DateTime date;

  /// Similitud con la consulta. Mayor es más parecido.
  final double score;
}

/// Contrato propio de búsqueda en la base de conocimiento.
abstract interface class Retriever {
  Future<List<Fragment>> retrieve(String query, {int limit = 3});
}
