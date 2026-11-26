import '../ai/retriever.dart';
import '../content/card.dart';
import 'search.dart';

/// Implementación de [Retriever] con búsqueda por palabras, sin modelo (RF-07).
///
/// Solo devuelve fichas verificadas, porque un [Fragment] exige fuente y fecha (RD-03 y RD-04).
class KeywordRetriever implements Retriever {
  const KeywordRetriever(this.cards);

  final List<Ficha> cards;

  @override
  Future<List<Fragment>> retrieve(String query, {int limit = 3}) async {
    final verified = [
      for (final c in cards)
        if (c.verificada && c.fechaVerificacion != null) c,
    ];
    return [
      for (final match in buscar(query, verified, max: limit))
        Fragment(
          id: match.ficha.id,
          text: match.ficha.texto,
          source: match.ficha.fuente,
          date: DateTime.tryParse(match.ficha.fechaVerificacion!),
          score: match.puntaje.toDouble(),
          path: match.ficha.titulo,
          title: match.ficha.titulo,
        ),
    ];
  }
}
