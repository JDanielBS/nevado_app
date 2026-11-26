/// El archivo del modelo no coincide con su checksum y ya fue borrado.
class CorruptModelException implements Exception {
  const CorruptModelException();
}

/// Contrato propio del motor de lenguaje.
abstract interface class LlmEngine {
  /// Motivo por el que este equipo no puede usar el modelo, o `null` si puede.
  String? unsupportedReason();

  /// Si puede descargar el modelo sin que le indiquen de dónde (compilación de desarrollo con token).
  bool get canDownload;

  Future<bool> isInstalled();

  /// Descarga el modelo desde [origen], o desde su fuente pública si se omite.
  /// Emite el porcentaje de avance.
  Stream<int> install({Uri? origen});

  /// Deja el modelo en memoria. Requiere que esté instalado.
  ///
  /// Antes verifica el archivo y lanza [CorruptModelException] si está dañado.
  Future<void> load();

  /// Libera la memoria del modelo. Queda instalado en disco: [load] lo vuelve a cargar.
  ///
  /// No hace nada si no estaba cargado.
  Future<void> unload();

  /// Emite la respuesta por partes a medida que se genera.
  Stream<String> generate(String prompt);
}
