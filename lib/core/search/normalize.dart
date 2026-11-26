const _palabrasVacias = {
  'a', 'al', 'algo', 'como', 'con', 'cual', 'cuales', 'cuando', 'cuanto', 'de', 'del', 'donde', //
  'el', 'ella', 'en', 'es', 'esta', 'este', 'esto', 'hay', 'la', 'las', 'lo', 'los', 'me', 'mi', //
  'mis', 'no', 'para', 'por', 'que', 'quien', 'se', 'si', 'sobre', 'son', 'su', 'sus', 'te', 'un', //
  'una', 'unas', 'uno', 'unos', 'y', 'ya', 'puedo', 'debo', 'tengo', 'hago', 'hacer', 'hace', 'hacen',
};

const _sinTilde = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', 'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', //
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', 'ñ': 'n', 'ç': 'c',
};

/// Minúsculas y sin tildes, para comparar sin importar cómo escriba la persona.
String normalizar(String texto) {
  final buffer = StringBuffer();
  for (final caracter in texto.toLowerCase().split('')) {
    buffer.write(_sinTilde[caracter] ?? caracter);
  }
  return buffer.toString();
}

/// Reducción mínima de plurales: "frailejones" -> "frailejon", "normas" -> "norma".
String _singular(String palabra) {
  if (palabra.length > 5 && palabra.endsWith('es')) return palabra.substring(0, palabra.length - 2);
  if (palabra.length > 3 && palabra.endsWith('s')) return palabra.substring(0, palabra.length - 1);
  return palabra;
}

List<String> tokenizar(String texto) => normalizar(texto)
    .split(RegExp(r'[^a-z0-9]+'))
    .where((t) => t.length > 1 && !_palabrasVacias.contains(t))
    .map(_singular)
    .toList();
