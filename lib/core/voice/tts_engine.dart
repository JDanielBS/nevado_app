/// Contrato propio del motor de voz (texto a audio).
abstract interface class TtsEngine {
  /// Motivo por el que este equipo no puede usar la voz, o `null` si puede.
  String? unsupportedReason();

  Future<bool> isInstalled();

  /// Descarga el modelo de voz desde [origen], o desde su fuente pública si se omite.
  /// Emite el porcentaje de avance.
  Stream<int> install({Uri? origen});

  /// Deja el modelo en memoria. Requiere que esté instalado.
  ///
  /// Antes verifica el archivo y lanza `CorruptVoiceModelException` si está dañado.
  Future<void> load();

  /// Libera la memoria del modelo. Queda instalado en disco.
  Future<void> unload();

  /// Sintetiza y reproduce [text]. Termina cuando acaba el audio o se llama a [stop].
  Future<void> speak(String text);

  /// Interrumpe el audio. No hace nada si no está sonando.
  Future<void> stop();

  bool get isSpeaking;
}
