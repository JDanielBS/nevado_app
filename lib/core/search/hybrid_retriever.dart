import '../content/seccion.dart';

/// Combina búsqueda por significado y por palabras (Reciprocal Rank Fusion). El significado pesa más.
///
/// Las listas ya vienen filtradas por sus umbrales; si ambas están vacías devuelve vacío y la app se
/// abstiene.
List<Fragmento> fusionar({
  required List<Fragmento> semanticos,
  required List<Fragmento> palabras,
  required int limite,
}) {
  final puntos = <Fragmento, double>{};
  void sumar(List<Fragmento> lista, double peso) {
    for (var i = 0; i < lista.length && i < 20; i++) {
      puntos[lista[i]] = (puntos[lista[i]] ?? 0) + peso / (60 + i + 1);
    }
  }

  sumar(semanticos, 1.5);
  sumar(palabras, 1);
  final orden = puntos.keys.toList()..sort((a, b) => puntos[b]!.compareTo(puntos[a]!));
  return orden.take(limite).toList();
}
