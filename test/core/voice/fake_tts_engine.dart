import 'dart:async';

import 'package:nevado_app/core/voice/tts_engine.dart';
import 'package:nevado_app/core/voice/tts_exceptions.dart';

/// Motor de voz controlado por la prueba. Registra lo que se le pide.
class FakeTtsEngine implements TtsEngine {
  FakeTtsEngine({this.reason, this.installed = true});

  final String? reason;
  bool installed;
  bool failInstall = false;
  bool failSpeak = false;
  bool corrupt = false;

  /// Con `true`, [speak] no termina hasta [stop] o [finishSpeaking].
  bool holdSpeech = false;
  Completer<void>? _speech;

  final List<String> spoken = [];
  int installs = 0;
  int loads = 0;
  int unloads = 0;
  int stops = 0;
  Uri? origen;

  @override
  String? unsupportedReason() => reason;

  @override
  Future<bool> isInstalled() async => installed;

  @override
  Stream<int> install({Uri? origen}) async* {
    this.origen = origen;
    installs++;
    if (failInstall) throw Exception('sin red');
    yield 50;
    installed = true;
    yield 100;
  }

  @override
  Future<void> load() async {
    loads++;
    if (corrupt) throw const CorruptVoiceModelException();
  }

  @override
  Future<void> unload() async => unloads++;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    if (failSpeak) throw Exception('audio');
    if (holdSpeech) await (_speech = Completer<void>()).future;
  }

  void finishSpeaking() {
    final speech = _speech;
    _speech = null;
    speech?.complete();
  }

  @override
  Future<void> stop() async {
    stops++;
    finishSpeaking();
  }

  @override
  bool get isSpeaking => _speech != null;
}
