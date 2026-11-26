/// Contrato propio del motor de lenguaje.
abstract interface class LlmEngine {
  /// Emite la respuesta por partes a medida que se genera.
  Stream<String> generate(String prompt);
}
