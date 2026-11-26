import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'local_tts_engine.dart';

/// Reproducción con el altavoz del teléfono.
class AudioPlayerOutput implements AudioOutput {
  // Se crea al usarlo: en pruebas no hay reproductor.
  late final _reproductor = AudioPlayer();
  Completer<void>? _actual;

  @override
  Future<void> play(String path) async {
    final fin = _actual = Completer<void>();
    final aviso = _reproductor.onPlayerComplete.listen((_) {
      if (!fin.isCompleted) fin.complete();
    });
    try {
      await _reproductor.play(DeviceFileSource(path));
      await fin.future;
    } finally {
      await aviso.cancel();
    }
  }

  @override
  Future<void> stop() async {
    final actual = _actual;
    _actual = null;
    if (actual == null) return;
    await _reproductor.stop();
    if (!actual.isCompleted) actual.complete();
  }
}
