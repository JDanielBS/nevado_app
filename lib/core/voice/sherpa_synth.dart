import 'dart:io';
import 'dart:isolate';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'local_tts_engine.dart';
import 'voice_file.dart';

/// Síntesis con sherpa-onnx (voces Piper) en un hilo propio, para no frenar la pantalla.
/// Único archivo que importa el paquete.
class SherpaSynth implements SpeechSynth {
  Isolate? _hilo;
  SendPort? _ordenes;
  Directory? _salida;
  int _numero = 0;

  @override
  Future<void> load(Directory voz) async {
    await unload();
    final inicio = ReceivePort();
    _hilo = await Isolate.spawn(_trabajador, inicio.sendPort);
    _ordenes = await inicio.first as SendPort;
    _salida = await Directory.systemTemp.createTemp('voz');
    try {
      await _pedir(('cargar', voz.path, ''));
    } catch (_) {
      await unload();
      rethrow;
    }
  }

  @override
  Future<String> synthesize(String text) async {
    final ruta = '${_salida!.path}/${_numero++}.wav';
    await _pedir(('decir', text, ruta));
    return ruta;
  }

  @override
  Future<void> unload() async {
    if (_ordenes != null) await _pedir(('liberar', '', ''));
    _hilo?.kill();
    _hilo = null;
    _ordenes = null;
    final salida = _salida;
    _salida = null;
    if (salida != null && await salida.exists()) await salida.delete(recursive: true);
  }

  Future<void> _pedir((String, String, String) orden) async {
    final ordenes = _ordenes;
    if (ordenes == null) throw StateError('La voz no está cargada.');
    final respuesta = ReceivePort();
    ordenes.send((orden, respuesta.sendPort));
    final error = await respuesta.first;
    if (error != null) throw Exception(error);
  }

  static void _trabajador(SendPort inicio) {
    final ordenes = ReceivePort();
    inicio.send(ordenes.sendPort);
    sherpa.OfflineTts? tts;
    ordenes.listen((mensaje) {
      final ((accion, dato, ruta), SendPort respuesta) = mensaje as ((String, String, String), SendPort);
      try {
        switch (accion) {
          case 'cargar':
            sherpa.initBindings();
            tts = sherpa.OfflineTts(sherpa.OfflineTtsConfig(
              model: sherpa.OfflineTtsModelConfig(
                vits: sherpa.OfflineTtsVitsModelConfig(
                  model: '$dato/$modeloVoz',
                  tokens: '$dato/tokens.txt',
                  dataDir: '$dato/espeak-ng-data',
                ),
                numThreads: 2,
                debug: false,
              ),
            ));
          case 'decir':
            final audio = tts!.generate(text: dato);
            if (!sherpa.writeWave(filename: ruta, samples: audio.samples, sampleRate: audio.sampleRate)) {
              throw StateError('No se pudo escribir el audio.');
            }
          case 'liberar':
            tts?.free();
            tts = null;
        }
        respuesta.send(null);
      } catch (e) {
        respuesta.send('$e');
      }
    });
  }
}
