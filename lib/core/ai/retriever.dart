/// Fragmento oficial recuperado de la base de conocimiento.
class Fragment {
  const Fragment({
    required this.text,
    required this.source,
    required this.date,
    required this.score,
    this.id = '',
    this.path = '',
    this.title = '',
    this.description = '',
    this.stations = const [],
    this.expires,
  });

  final String id;
  final String text;
  final String source;
  final DateTime? date;
  final DateTime? expires;
  final double score;
  final String path;
  final String title;
  final String description;
  final List<String> stations;
}

/// Contrato propio de búsqueda en la base de conocimiento.
abstract interface class Retriever {
  Future<List<Fragment>> retrieve(String query, {int limit = 3});
}
