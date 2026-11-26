import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/app/app.dart';
import 'package:nevado_app/app/app_scope.dart';
import 'package:nevado_app/core/access/access_controller.dart';
import 'package:nevado_app/core/access/pass.dart';
import 'package:nevado_app/core/settings/settings.dart';
import 'package:nevado_app/features/chat/chat_controller.dart';
import 'package:nevado_app/features/chat/chat_screen.dart';
import 'package:nevado_app/features/chat/model_provisioning.dart';
import 'package:nevado_app/features/chat/voice_chat_controller.dart';

import '../../chat_test.dart' show FakeEngine;
import '../../core/voice/fake_tts_engine.dart';
import '../../voice_settings_test.dart' show MemorySettingsStore;
import 'voice_chat_controller_test.dart' show MemoryVoiceStore, ficha;

/// Pase ya activo que trae la dirección de la estación.
class PaseActivo extends ChangeNotifier implements AccessController {
  @override
  Pase? pase;

  @override
  bool activo = false;

  void encender() {
    activo = true;
    pase = Pase(
      emitido: DateTime(2026),
      vence: DateTime(2027),
      modelo: Uri.parse('http://192.168.1.20:8000/Gemma.litertlm'),
    );
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeEngine llm;
  late FakeTtsEngine tts;
  late VoiceChatController voice;
  late Ajustes settings;

  setUp(() {
    llm = FakeEngine(installed: true);
    tts = FakeTtsEngine();
    voice = VoiceChatController(ChatController(llm), tts, store: MemoryVoiceStore());
    settings = Ajustes(store: MemorySettingsStore());
  });

  const libre = 'cuéntame un chiste';

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(AppScope(
      cards: const [ficha],
      settings: settings,
      child: MaterialApp(home: Scaffold(body: ChatScreen(voz: voice))),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> preguntar(WidgetTester tester, [String texto = libre]) async {
    await tester.enterText(find.byType(TextField), texto);
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
  }

  testWidgets('responde en texto y lo lee en voz alta; se puede detener y repetir', (tester) async {
    tts.holdSpeech = true;
    await abrir(tester);
    await preguntar(tester);
    expect(find.text('Hola mundo'), findsOneWidget);
    expect(tts.spoken, ['Hola mundo']);

    await tester.tap(find.text('Detener'));
    await tester.pumpAndSettle();
    expect(find.text('Detener'), findsNothing);

    await tester.tap(find.text('Repetir'));
    await tester.pumpAndSettle();
    expect(tts.spoken, ['Hola mundo', 'Hola mundo']);
    expect(find.text('Detener'), findsOneWidget);
  });

  testWidgets('las respuestas de fichas se ven en texto, sin voz ni botón', (tester) async {
    await abrir(tester);
    await preguntar(tester, 'frailejón');
    expect(find.text(ficha.texto), findsOneWidget);
    expect(tts.spoken, isEmpty);
    expect(find.text('Repetir'), findsNothing);
  });

  testWidgets('el interruptor apaga la lectura automática', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Leer en voz alta'));
    await tester.pumpAndSettle();
    await preguntar(tester);
    expect(tts.spoken, isEmpty);
    expect(find.text('Repetir'), findsOneWidget);
  });

  testWidgets('sin la voz descargada indica que se baja en la estación', (tester) async {
    tts.installed = false;
    await abrir(tester);
    expect(find.textContaining('estación'), findsOneWidget);
    expect(find.text('Descargar voz'), findsNothing);

    await tester.runAsync(() => voice.chat.provision(Uri.parse('http://192.168.1.20:8000/Gemma.litertlm')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descargar voz'));
    await tester.pumpAndSettle();
    expect(tts.installs, 1);
    expect(find.text('Leer en voz alta'), findsOneWidget);
  });

  testWidgets('sin voz en el equipo explica el motivo y sigue respondiendo en texto', (tester) async {
    voice = VoiceChatController(voice.chat, FakeTtsEngine(reason: 'Sin voz en este equipo'), store: MemoryVoiceStore());
    await abrir(tester);
    expect(find.text('Sin voz en este equipo'), findsOneWidget);
    await preguntar(tester);
    expect(find.text('Hola mundo'), findsOneWidget);
    expect(find.text('Repetir'), findsNothing);
  });

  testWidgets('en modo ahorro no carga la voz', (tester) async {
    settings.elegirAhorro(true);
    await abrir(tester);
    await preguntar(tester);
    expect(tts.loads, 0);
    expect(tts.spoken, isEmpty);
  });

  testWidgets('apagar la voz en ajustes calla y libera el modelo; encenderla lo recarga', (tester) async {
    tts.holdSpeech = true;
    await abrir(tester);
    await preguntar(tester);
    settings.vozActiva = false;
    await tester.pumpAndSettle();
    expect(tts.stops, 1);
    expect(tts.unloads, 1);
    expect(find.text('Repetir'), findsNothing);
    expect(find.textContaining('voz está desactivada'), findsOneWidget);
    settings.vozActiva = true;
    await tester.pumpAndSettle();
    expect(tts.loads, 2);
  });

  testWidgets('al salir de Guía IA calla y libera la voz', (tester) async {
    tts.holdSpeech = true;
    await abrir(tester);
    await preguntar(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tts.stops, 1);
    expect(tts.unloads, 1);
  });

  testWidgets('la voz está dentro de Guía IA, sin otra entrada en la barra', (tester) async {
    await tester.pumpWidget(const NevadoApp());
    await tester.pumpAndSettle();
    expect(find.text('Chat voz'), findsNothing);
    await tester.tap(find.text('Guía IA'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('al activar el pase se descarga el modelo y después la voz', (tester) async {
    llm = FakeEngine();
    tts.installed = false;
    voice = VoiceChatController(ChatController(llm), tts, store: MemoryVoiceStore());
    final access = PaseActivo();
    vincularModeloConPase(access, voice.chat, voice);
    access.encender();
    await tester.pumpAndSettle();
    expect(llm.installs, 1);
    expect(tts.installs, 0, reason: 'la voz espera a que termine el modelo');
    await tester.runAsync(llm.progress.close);
    await tester.pumpAndSettle();
    expect(tts.installs, 1);
    expect(tts.origen?.path, endsWith('.tar.bz2'));
  });

  testWidgets('el estado de descarga no deja salir de la red hasta tener la voz', (tester) async {
    final chat = voice.chat
      ..origen = Uri.parse('http://192.168.1.20:8000/Gemma.litertlm')
      ..instalado = true;
    Widget app() => MaterialApp(
          home: Scaffold(body: VoiceScope(controller: voice, child: ModelScope(controller: chat, child: const ModelStatus()))),
        );
    await tester.pumpWidget(app());
    expect(find.textContaining('Ya puedes salir'), findsNothing);
    tts.installed = true;
    await tester.runAsync(() => voice.provision(chat.origen!));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ya puedes salir'), findsOneWidget);
  });
}
