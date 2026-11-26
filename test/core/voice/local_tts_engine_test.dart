import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/voice/local_tts_engine.dart';
import 'package:nevado_app/core/voice/voice_installer.dart';

class FakeInstaller implements VoiceInstaller {
  bool lista = true;
  Uri? origen;

  @override
  PaqueteVoz get paquete => paqueteVozEspanol;

  @override
  Future<Directory> Function() get base => verificar;

  @override
  Future<bool> instalada() async => lista;

  @override
  Stream<int> instalar(Uri origen) {
    this.origen = origen;
    return Stream.value(100);
  }

  @override
  Future<Directory> verificar() async => Directory('voz');
}

class FakeSynth implements SpeechSynth {
  final List<String> textos = [];
  bool cargado = false;

  @override
  Future<void> load(Directory voz) async => cargado = true;

  @override
  Future<String> synthesize(String text) async {
    textos.add(text);
    return '$text.wav';
  }

  @override
  Future<void> unload() async => cargado = false;
}

class FakeOutput implements AudioOutput {
  final List<String> sonaron = [];
  bool esperar = false;
  Completer<void>? _actual;
  int stops = 0;

  @override
  Future<void> play(String path) async {
    sonaron.add(path);
    if (esperar) await (_actual = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    _actual?.complete();
    _actual = null;
  }
}

void main() {
  late FakeInstaller installer;
  late FakeSynth synth;
  late FakeOutput output;
  late LocalTtsEngine engine;

  setUp(() {
    installer = FakeInstaller();
    synth = FakeSynth();
    output = FakeOutput();
    engine = LocalTtsEngine(installer: installer, synth: synth, output: output, compatible: true);
  });

  test('lee frase por frase, en orden', () async {
    await engine.load();
    await engine.speak('Hola. El frailejón crece despacio.\n¿Lo ves? Mide 1.5 metros.');
    expect(synth.textos, ['Hola.', 'El frailejón crece despacio.', '¿Lo ves?', 'Mide 1.5 metros.']);
    expect(output.sonaron, hasLength(4));
    expect(engine.isSpeaking, isFalse);
  });

  test('no pronuncia las marcas de formato del modelo', () async {
    await engine.load();
    await engine.speak('**Frailejón**: `planta` #1_a');
    expect(synth.textos, ['Frailejón: planta 1 a']);
  });

  test('detener corta la frase actual y no sigue con las demás', () async {
    output.esperar = true;
    await engine.load();
    final lectura = engine.speak('Uno. Dos. Tres.');
    await pumpEventQueue();
    expect(engine.isSpeaking, isTrue);
    await engine.stop();
    await lectura;
    expect(synth.textos, ['Uno.']);
    expect(engine.isSpeaking, isFalse);
  });

  test('sin cargar no habla', () async {
    await expectLater(engine.speak('Hola.'), throwsStateError);
    expect(synth.textos, isEmpty);
  });

  test('unload libera el modelo', () async {
    await engine.load();
    expect(synth.cargado, isTrue);
    await engine.unload();
    expect(synth.cargado, isFalse);
  });

  test('solo se descarga desde la estación', () async {
    await expectLater(engine.install().drain<void>(), throwsStateError);
    final origen = Uri.parse('http://192.168.1.20:8000/voz.tar.bz2');
    await engine.install(origen: origen).drain<void>();
    expect(installer.origen, origen);
  });

  test('en un equipo no compatible explica el motivo', () {
    final otro = LocalTtsEngine(installer: installer, synth: synth, output: output, compatible: false);
    expect(otro.unsupportedReason(), contains('voz'));
    expect(engine.unsupportedReason(), isNull);
  });
}
