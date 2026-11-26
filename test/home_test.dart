import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/app/app.dart';

const labels = ['Emergencias', 'Asistente', 'Mi ubicación', 'Mapa'];

Future<void> openAndReturn(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  expect(find.widgetWithText(AppBar, label), findsOneWidget);
  await tester.pageBack();
  await tester.pumpAndSettle();
  expect(find.textContaining('no reemplaza'), findsOneWidget);
}

void main() {
  testWidgets('cada botón abre su pantalla y permite volver', (tester) async {
    await tester.pumpWidget(const NevadoApp());
    expect(find.textContaining('no reemplaza'), findsOneWidget);
    for (final label in labels) {
      await openAndReturn(tester, label);
    }
  });

  for (final (name, size) in [
    ('vertical pequeña', const Size(320, 568)),
    ('horizontal', const Size(568, 320)),
  ]) {
    testWidgets('texto al 200 % en pantalla $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(const NevadoApp());
      for (final label in labels) {
        await openAndReturn(tester, label);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
