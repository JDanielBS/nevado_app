/// El archivo del modelo no coincide con su checksum y ya fue borrado.
class CorruptModelException implements Exception {
  const CorruptModelException();
}

/// Contrato propio del motor de lenguaje.
abstract interface class LlmEngine {
  /// Motivo por el que este equipo no puede usar el modelo, o `null` si puede.
  String? unsupportedReason();

  /// Si la app se compiló con lo necesario para descargar el modelo.
  bool get canDownload;

  Future<bool> isInstalled();

  /// Descarga el modelo. Emite el porcentaje de avance.
  Stream<int> install();

  /// Deja el modelo en memoria. Requiere que esté instalado.
  ///
  /// Antes verifica el archivo y lanza [CorruptModelException] si está dañado.
  Future<void> load();

  /// Emite la respuesta por partes a medida que se genera.
  Stream<String> generate(String prompt);
}
