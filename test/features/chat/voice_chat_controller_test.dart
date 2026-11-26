import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/content/card.dart';
import 'package:nevado_app/core/voice/voice_file.dart';
import 'package:nevado_app/features/chat/chat_controller.dart';
import 'package:nevado_app/features/chat/voice_chat_controller.dart';

import '../../chat_test.dart' show FakeEngine;
import '../../core/voice/fake_tts_engine.dart';

class MemoryVoiceStore implements VoiceStore {
  bool? value;

  @override
  Future<bool?> leerAutoLeer() async => value;

  @override
  Future<void> guardarAutoLeer(bool valor) async => value = valor;
}

const ficha = Ficha(
  id: 'f1',
  categoria: Categoria.flora,
  titulo: 'Frailejón',
  texto: 'El frailejón crece muy despacio.',
  palabrasClave: ['frailejon'],
  fuente: 'Parque',
  fechaVerificacion: null,
  estado: EstadoFicha.borrador,
);

void main() {
  late FakeEngine llm;
  late FakeTtsEngine tts;
  late MemoryVoiceStore store;
  late VoiceChatController voice;

  setUp(() async {
    llm = FakeEngine(installed: true);
    tts = FakeTtsEngine();
    store = MemoryVoiceStore();
    voice = VoiceChatController(ChatController(llm), tts, store: store);
    await voice.chat.start();
  });

  /// No hay ficha que la responda: contesta el modelo ("Hola mundo").
  const libre = 'cuéntame un chiste';

  /// Pregunta y deja correr la lectura, que no bloquea la respuesta.
  Future<void> preguntar([String texto = libre, bool permitida = true]) async {
    await voice.ask(texto, cards: const [ficha], permitida: permitida);
    await pumpEventQueue();
  }

  test('lee la respuesta completa del modelo, una sola vez', () async {
    await voice.start();
    await preguntar();
    expect(tts.spoken, ['Hola mundo']);
  });

  test('no dice nada que no haya generado el modelo: fichas, reglas ni emergencias', () async {
    await voice.start();
    for (final pregunta in ['frailejón', '¿puedo ir al cráter?', 'me caí y me duele la pierna']) {
      await preguntar(pregunta);
      voice.repeat(voice.turnos.last);
      await pumpEventQueue();
    }
    expect(voice.turnos, hasLength(3));
    expect(tts.spoken, isEmpty);
  });

  test('no lee con la lectura automática apagada y recuerda la elección', () async {
    await voice.start();
    await voice.setAutoSpeak(false);
    await preguntar();
    expect(tts.spoken, isEmpty);
    expect(store.value, isFalse);

    final otro = VoiceChatController(ChatController(llm), tts, store: store);
    await otro.start();
    expect(otro.autoSpeak, isFalse);
  });

  test('sin permiso (ahorro o voz apagada) no lee', () async {
    await voice.start();
    await preguntar(libre, false);
    expect(tts.spoken, isEmpty);
    expect(voice.turnos.single.generado, 'Hola mundo');
  });

  test('en modo ahorro no hay modelo de IA ni voz', () async {
    await voice.start();
    await voice.ask(libre, batterySaver: true);
    await pumpEventQueue();
    expect(voice.turnos.single.respuesta, isNotNull);
    expect(tts.spoken, isEmpty);
  });

  test('la respuesta no espera a que termine el audio y se puede detener', () async {
    tts.holdSpeech = true;
    await voice.start();
    await preguntar();
    expect(voice.speaking, same(voice.turnos.single));
    await voice.stop();
    await pumpEventQueue();
    expect(voice.speaking, isNull);
    expect(tts.stops, greaterThan(0));
  });

  test('al terminar el audio deja de estar hablando', () async {
    tts.holdSpeech = true;
    await voice.start();
    await preguntar();
    tts.finishSpeaking();
    await pumpEventQueue();
    expect(voice.speaking, isNull);
  });

  test('repetir interrumpe lo que sonaba y marca solo el turno elegido', () async {
    tts.holdSpeech = true;
    await voice.start();
    await preguntar();
    await preguntar();
    expect(voice.speaking, same(voice.turnos.last));
    voice.repeat(voice.turnos.first);
    await pumpEventQueue();
    expect(voice.speaking, same(voice.turnos.first));
    expect(tts.spoken, hasLength(3));
  });

  test('si se detiene mientras se genera la respuesta, ya no la lee', () async {
    await voice.start();
    final pregunta = voice.ask(libre);
    await voice.stop();
    await pregunta;
    await pumpEventQueue();
    expect(tts.spoken, isEmpty);
  });

  test('una pregunta vacía no repite la respuesta anterior', () async {
    await voice.start();
    await preguntar();
    await preguntar('   ');
    expect(tts.spoken, hasLength(1));
  });

  test('no lee una respuesta que falló', () async {
    llm.failGenerate = true;
    await voice.start();
    await preguntar();
    expect(tts.spoken, isEmpty);
  });

  test('un fallo de audio se informa y no deja el estado hablando', () async {
    tts.failSpeak = true;
    await voice.start();
    await preguntar();
    expect(voice.speaking, isNull);
    expect(voice.error, contains('audio'));
  });

  final estacion = Uri.parse('http://192.168.1.20:8000/Gemma.litertlm');

  test('descarga la voz de la estación que indica el pase y la carga', () async {
    tts.installed = false;
    await voice.start();
    expect(voice.phase, VoicePhase.noModel);
    expect(voice.canDownload, isFalse);
    await voice.download();
    expect(tts.installs, 0);

    voice.chat.origen = estacion;
    await voice.download();
    expect(tts.origen, Uri.parse('http://192.168.1.20:8000/$nombreVoz'));
    expect(voice.phase, VoicePhase.ready);
    expect(tts.loads, 1);
  });

  test('al activar el pase la descarga sola y libera la memoria', () async {
    tts.installed = false;
    await voice.provision(estacion);
    expect(tts.installs, 1);
    expect(voice.instalada, isTrue);
    expect(tts.unloads, 1);
    await voice.provision(estacion);
    expect(tts.installs, 1);
  });

  test('un equipo sin voz no descarga nada', () async {
    final engine = FakeTtsEngine(reason: 'Sin voz', installed: false);
    final sinVoz = VoiceChatController(ChatController(llm), engine, store: store);
    await sinVoz.provision(estacion);
    expect(engine.installs, 0);
    expect(sinVoz.phase, VoicePhase.unsupported);
  });

  test('fallo de descarga permite reintentar', () async {
    tts
      ..installed = false
      ..failInstall = true;
    await voice.provision(estacion);
    expect(voice.phase, VoicePhase.noModel);
    expect(voice.error, isNotNull);
    tts.failInstall = false;
    await voice.provision(estacion);
    expect(voice.instalada, isTrue);
  });

  test('un modelo de voz dañado pide descargarlo de nuevo', () async {
    tts.corrupt = true;
    await voice.start();
    expect(voice.phase, VoicePhase.noModel);
    expect(voice.error, contains('dañad'));
  });

  test('equipo no compatible: muestra el motivo y no carga', () async {
    final engine = FakeTtsEngine(reason: 'Sin voz');
    final sinVoz = VoiceChatController(ChatController(llm), engine, store: store);
    await sinVoz.start();
    expect(sinVoz.phase, VoicePhase.unsupported);
    expect(sinVoz.error, 'Sin voz');
    expect(engine.loads, 0);
  });

  test('release calla, libera la memoria y start vuelve a cargar', () async {
    await voice.start();
    await voice.release();
    expect(tts.unloads, 1);
    expect(voice.phase, VoicePhase.checking);
    await voice.start();
    expect(tts.loads, 2);
  });

  test('al borrar la conversación no queda ninguna respuesta', () async {
    await voice.start();
    await preguntar('frailejón');
    await preguntar();
    voice.chat.clear();
    expect(voice.turnos, isEmpty);
  });

  test('si la conversación se borra mientras se genera, no se lee ni falla', () async {
    await voice.start();
    await preguntar('frailejón');
    final pregunta = voice.ask(libre);
    voice.chat.addListener(() {
      if (voice.chat.answering) voice.chat.clear();
    });
    await pregunta;
    await pumpEventQueue();
    expect(voice.turnos, isEmpty);
    expect(tts.spoken, isEmpty);
  });
}
