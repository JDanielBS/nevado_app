import 'dart:io';

import 'tts_engine.dart';
import 'voice_installer.dart';

/// Convierte texto en un archivo de audio, sin conexión.
abstract interface class SpeechSynth {
  Future<void> load(Directory voz);

  /// Ruta del audio generado.
  Future<String> synthesize(String text);

  Future<void> unload();
}

/// Reproduce un archivo de audio.
abstract interface class AudioOutput {
  /// Termina cuando acaba el audio o se llama a [stop].
  Future<void> play(String path);

  Future<void> stop();
}

/// Voz que funciona en el teléfono: se instala desde la estación y no usa internet.
class LocalTtsEngine implements TtsEngine {
  LocalTtsEngine({
    required this._installer,
    required this._synth,
    required this._output,
    required this.compatible,
  });

  final VoiceInstaller _installer;
  final SpeechSynth _synth;
  final AudioOutput _output;
  final bool compatible;

  bool _cargada = false;
  bool _hablando = false;

  /// Cambia con cada lectura o parada: lo anterior deja de sonar.
  int _generacion = 0;

  @override
  String? unsupportedReason() => compatible ? null : 'La voz solo está disponible en teléfonos Android.';

  @override
  Future<bool> isInstalled() => _installer.instalada();

  @override
  Stream<int> install({Uri? origen}) => origen == null
      ? Stream.error(StateError('La voz solo se descarga desde la estación.'))
      : _installer.instalar(origen);

  @override
  Future<void> load() async {
    if (_cargada) return;
    await _synth.load(await _installer.verificar());
    _cargada = true;
  }

  @override
  Future<void> unload() async {
    await stop();
    if (!_cargada) return;
    _cargada = false;
    await _synth.unload();
  }

  /// Se sintetiza frase por frase para empezar a sonar pronto y poder interrumpir.
  @override
  Future<void> speak(String text) async {
    if (!_cargada) throw StateError('La voz no está cargada.');
    await stop();
    final generacion = _generacion;
    _hablando = true;
    try {
      for (final frase in _frases(text)) {
        final audio = await _synth.synthesize(frase);
        if (generacion != _generacion) return;
        await _output.play(audio);
        if (generacion != _generacion) return;
      }
    } finally {
      if (generacion == _generacion) _hablando = false;
    }
  }

  @override
  Future<void> stop() async {
    _generacion++;
    if (!_hablando) return;
    _hablando = false;
    await _output.stop();
  }

  @override
  bool get isSpeaking => _hablando;

  /// Quita las marcas de formato que a veces escribe el modelo y separa en frases.
  static List<String> _frases(String text) => [
        for (final frase in text
            .replaceAll(RegExp(r'[*`#]'), '')
            .replaceAll('_', ' ')
            .split(RegExp(r'(?<=[.!?…])\s+|\n+')))
          if (frase.trim().isNotEmpty) frase.trim(),
      ];
}
