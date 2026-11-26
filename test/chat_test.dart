import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/ai/device_support.dart';
import 'package:nevado_app/core/ai/llm_engine.dart';
import 'package:nevado_app/features/chat/chat_controller.dart';
import 'package:nevado_app/features/chat/chat_screen.dart';

class FakeEngine implements LlmEngine {
  FakeEngine({this.reason, this.installed = false, this.canDownload = true});

  final String? reason;
  bool installed;
  @override
  final bool canDownload;
  bool failInstall = false;
  bool failGenerate = false;
  bool corrupt = false;
  int installs = 0;
  StreamController<int> progress = StreamController<int>();

  @override
  String? unsupportedReason() => reason;

  @override
  Future<bool> isInstalled() async => installed;

  @override
  Stream<int> install() {
    installs++;
    if (failInstall) return Stream.error(Exception('sin red'));
    return progress.stream;
  }

  @override
  Future<void> load() async {
    if (corrupt) throw const CorruptModelException();
  }

  @override
  Stream<String> generate(String prompt) => failGenerate
      ? Stream.error(Exception('motor'))
      : Stream.fromIterable(['Hola ', 'mundo']);
}

Future<ChatController> open(WidgetTester tester, FakeEngine engine) async {
  final controller = ChatController(engine);
  await tester.pumpWidget(MaterialApp(home: ChatScreen(controller: controller)));
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
    expect(find.byType(TextField), findsNothing);
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

    await tester.enterText(find.byType(TextField), '¿Hola?');
    await tester.tap(find.text('Preguntar'));
    await tester.pumpAndSettle();
    expect(find.text('Hola mundo'), findsOneWidget);
  });

  testWidgets('sin token no ofrece descargar', (tester) async {
    await open(tester, FakeEngine(canDownload: false));
    expect(find.text('Descargar'), findsNothing);
    expect(find.textContaining('.env'), findsOneWidget);
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
    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.text('Preguntar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo responder'), findsOneWidget);
    expect(find.text('Preguntar'), findsOneWidget);
  });

  testWidgets('modelo dañado pide descargarlo de nuevo', (tester) async {
    await open(tester, FakeEngine(installed: true)..corrupt = true);
    await tester.pumpAndSettle();
    expect(find.textContaining('dañado'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
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
}
