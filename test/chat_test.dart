import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/ai/device_support.dart';
import 'package:nevado_app/core/ai/llm_engine.dart';
import 'package:nevado_app/core/content/card.dart';
import 'package:nevado_app/app/app_scope.dart';
import 'package:nevado_app/core/content/card_repository.dart';
import 'package:nevado_app/core/search/search.dart';
import 'package:nevado_app/core/settings/settings.dart';
import 'package:nevado_app/features/chat/chat_controller.dart';
import 'package:nevado_app/features/chat/chat_screen.dart';

import 'seccion_test.dart' show seccionesDelProyecto;

final indiceDelProyecto = IndiceGuia.de(seccionesDelProyecto());

class FakeEngine implements LlmEngine {
  FakeEngine({this.reason, this.installed = false, this.canDownload = true});

  final String? reason;
  bool installed;
  @override
  final bool canDownload;
  bool failInstall = false;

  /// Falla solo la descarga desde internet (sin origen).
  bool failInternet = false;
  String? lastPrompt;
  final origenes = <Uri?>[];
  bool failGenerate = false;
  bool corrupt = false;
  int installs = 0;
  int loads = 0;
  int unloads = 0;
  StreamController<int> progress = StreamController<int>();

  @override
  String? unsupportedReason() => reason;

  @override
  Future<bool> isInstalled() async => installed;

  @override
  Future<String?> rutaInstalada() async => installed ? '/modelo' : null;

  Uri? origen;

  @override
  Stream<int> install({Uri? origen}) {
    this.origen = origen;
    origenes.add(origen);
    installs++;
    if (failInstall || (failInternet && origen == null)) return Stream.error(Exception('sin red'));
    return progress.stream;
  }

  @override
  Future<void> load() async {
    loads++;
    if (corrupt) throw const CorruptModelException();
  }

  @override
  Future<void> unload() async {
    unloads++;
  }

  @override
  Stream<String> generate(String prompt) {
    lastPrompt = prompt;
    return failGenerate ? Stream.error(Exception('motor')) : Stream.fromIterable(['Hola ', 'mundo']);
  }
}

Future<ChatController> open(WidgetTester tester, FakeEngine engine) async {
  final controller = ChatController(engine);
  await tester.pumpWidget(
    MaterialApp(
      home: AppScope(
        indice: indiceDelProyecto,
        settings: Ajustes(),
        child: ChatScreen(controller: controller),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  expect(find.textContaining('Experimental'), findsOneWidget);
  return controller;
}

void main() {
  group('compatibilidad', () {
    const motoG60 = 'MemTotal:        3738404 kB\nMemFree: 1 kB';

    test('arm64 con RAM suficiente es compatible', () {
      expect(supportReason(androidArm64: true, memInfo: motoG60), isNull);
    });

    test('rechaza otra arquitectura, poca RAM o RAM desconocida', () {
      expect(supportReason(androidArm64: false, memInfo: motoG60), isNotNull);
      expect(
        supportReason(androidArm64: true, memInfo: 'MemTotal: 2900000 kB'),
        isNotNull,
      );
      expect(supportReason(androidArm64: true, memInfo: ''), isNotNull);
    });
  });

  testWidgets('teléfono no compatible muestra el motivo', (tester) async {
    await open(tester, FakeEngine(reason: 'Poca memoria'));
    expect(find.text('Poca memoria'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('descarga, muestra progreso, carga y responde', (tester) async {
    final engine = FakeEngine();
    await open(tester, engine);

    await tester.tap(find.text('Descargar'));
    await tester.pump();
    engine.progress.add(40);
    await tester.pump();
    expect(find.textContaining('40 %'), findsOneWidget);

    await engine.progress.close();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '¿Qué es el frailejón?');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola mundo'), findsOneWidget);
    expect(find.textContaining('IA, según Guion'), findsOneWidget);
  });

  test('si internet falla, descarga el modelo desde el teléfono del guía', () async {
    final engine = FakeEngine()..failInternet = true;
    final controller = ChatController(engine)..origen = Uri.parse('http://192.168.43.1:8000/modelo');
    await controller.start();
    final descarga = controller.download();
    await pumpEventQueue();
    await engine.progress.close();
    await descarga;
    expect(engine.origenes, [null, controller.origen]);
    expect(controller.phase, ChatPhase.ready);
    expect(controller.fuenteDescarga, 'guía');
  });

  testWidgets('sin origen de descarga pide escanear el pase', (tester) async {
    await open(tester, FakeEngine(canDownload: false));
    expect(find.text('Descargar'), findsNothing);
    expect(find.textContaining('escanea el pase'), findsOneWidget);
  });

  testWidgets('fallo de descarga permite reintentar', (tester) async {
    final engine = FakeEngine()..failInstall = true;
    await open(tester, engine);
    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo descargar'), findsOneWidget);

    engine.failInstall = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(engine.installs, 2);
  });

  testWidgets('fallo al responder se informa y deja preguntar', (tester) async {
    final engine = FakeEngine(installed: true)..failGenerate = true;
    await open(tester, engine);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '¿Qué es el frailejón?');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo responder'), findsOneWidget);
    expect(find.text('Enviar'), findsOneWidget);
  });

  testWidgets('modelo dañado pide descargarlo de nuevo', (tester) async {
    await open(tester, FakeEngine(installed: true)..corrupt = true);
    await tester.pumpAndSettle();
    expect(find.textContaining('dañado'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  group('reglas fijas y RAG', () {
    final emergencia = fichasDesdeTexto(File(rutaEmergencia).readAsStringSync());

    Future<(ChatController, FakeEngine)> ready() async {
      final engine = FakeEngine(installed: true);
      final controller = ChatController(engine);
      await controller.start();
      return (controller, engine);
    }

    Future<void> preguntar(ChatController c, String q, {bool ahorro = false}) =>
        c.ask(q, emergencia: emergencia, indice: indiceDelProyecto, batterySaver: ahorro);

    for (final (question, type) in [
      ('me rompí la pierna', TipoRespuesta.emergencia),
      ('¿qué pastilla tomo y en qué dosis?', TipoRespuesta.limite),
    ]) {
      test('"$question" no usa el modelo', () async {
        final (controller, engine) = await ready();
        await preguntar(controller, question);
        expect(controller.reply?.tipo, type);
        expect(engine.lastPrompt, isNull);
      });
    }

    test('el modelo responde con los fragmentos recuperados y se citan sus fuentes', () async {
      final (controller, engine) = await ready();
      await preguntar(controller, '¿Qué es el frailejón?');
      expect(controller.reply, isNull);
      expect(controller.answer, 'Hola mundo');
      expect(engine.lastPrompt, contains('Naturaleza > Frailejón'));
      expect(engine.lastPrompt, contains('CONSULTA: ¿Qué es el frailejón?'));
      expect(controller.turnos.last.fuentes, contains('Guion Ecoturístico UTON 2024, p. 5'));
      expect(controller.turnos.last.verificada, isFalse);
    });

    test('los límites que no son fijos van en las instrucciones del modelo', () async {
      final (controller, engine) = await ready();
      await preguntar(controller, '¿Puedo subir hoy al Valle de las Tumbas?');
      expect(engine.lastPrompt, contains('No digas que un lugar es seguro'));
      expect(engine.lastPrompt, contains('el clima de hoy'));
    });

    test('sin fragmentos no llama al modelo y dice que no hay información', () async {
      final (controller, engine) = await ready();
      await preguntar(controller, '¿cómo se hace una arepa?');
      expect(controller.reply?.tipo, TipoRespuesta.sinInformacion);
      expect(engine.lastPrompt, isNull);
    });

    test('en modo ahorro muestra el fragmento sin modelo', () async {
      final (controller, engine) = await ready();
      await preguntar(controller, '¿Qué es el frailejón?', ahorro: true);
      expect(controller.reply?.tipo, TipoRespuesta.respuesta);
      expect(controller.reply?.fuentes.single, startsWith('Guion'));
      expect(engine.lastPrompt, isNull);
    });

    test('sin modelo responde con el fragmento', () async {
      final controller = ChatController(FakeEngine());
      await controller.start();
      await preguntar(controller, '¿Qué es el frailejón?');
      expect(controller.reply?.tipo, TipoRespuesta.respuesta);
    });
  });

  test('salir y volver no inicia otra descarga', () async {
    final engine = FakeEngine();
    final controller = ChatController(engine);
    await controller.start();
    unawaited(controller.download());
    unawaited(controller.download());
    await controller.start();
    expect(engine.installs, 1);
    expect(controller.phase, ChatPhase.downloading);
  });

  group('liberar memoria del modelo', () {
    test('release lo descarga de memoria y start lo vuelve a cargar', () async {
      final engine = FakeEngine(installed: true);
      final controller = ChatController(engine);
      await controller.start();
      expect(controller.phase, ChatPhase.ready);
      expect(engine.loads, 1);

      await controller.release();
      expect(engine.unloads, 1);
      expect(controller.phase, ChatPhase.checking);

      await controller.start();
      expect(engine.loads, 2);
      expect(controller.phase, ChatPhase.ready);
    });

    test('release no descarga nada si el modelo no está cargado', () async {
      final engine = FakeEngine(installed: true);
      final controller = ChatController(engine);
      await controller.release();
      expect(engine.unloads, 0);
      expect(engine.loads, 0);
    });

    test('tras release no se usa el modelo sin volver a cargarlo', () async {
      final engine = FakeEngine(installed: true);
      final controller = ChatController(engine);
      await controller.start();
      await controller.release();
      await controller.ask('¿cómo se hace una arepa?');
      expect(controller.answer, isEmpty);
      expect(engine.loads, 1);
    });
  });
}
