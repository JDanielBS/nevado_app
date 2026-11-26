import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/app/app.dart';
import 'package:nevado_app/core/route/estaciones.dart';

Future<void> tapText(WidgetTester tester, String text) async {
  await mostrar(tester, text);
  final finder = find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Desplaza la lista principal hasta que el texto esté construido.
Future<void> mostrar(WidgetTester tester, String text) async {
  // Las listas construyen sus elementos a demanda: si el texto no existe aún,
  // se busca desde el inicio de la lista hacia abajo.
  if (find.text(text).evaluate().isNotEmpty) return;
  final lista = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
  tester.state<ScrollableState>(lista).position.jumpTo(0);
  await tester.pump();
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(find.text(text), 200, scrollable: lista, maxScrolls: 30);
  }
}

/// Recorre las secciones del mockup: ruta, ficha con pestañas, guía IA, seguridad y acerca.
Future<void> recorrer(WidgetTester tester) async {
  await tester.pumpWidget(const NevadoApp());
  await tester.pumpAndSettle();
  expect(find.text('Kumanday'), findsOneWidget);
  await mostrar(tester, 'Perfil de elevación · m s. n. m. (aprox.)');
  expect(find.text('Perfil de elevación · m s. n. m. (aprox.)'), findsOneWidget);

  await tapText(tester, 'Valle Lunar');
  expect(find.text('← Volver a la ruta'), findsOneWidget);
  for (final p in Pestana.values) {
    await tapText(tester, p.etiqueta);
  }
  await tapText(tester, '← Volver a la ruta');
  await mostrar(tester, 'Perfil de elevación · m s. n. m. (aprox.)');
  expect(find.text('Perfil de elevación · m s. n. m. (aprox.)'), findsOneWidget);

  await tapText(tester, 'Guía IA');
  expect(find.textContaining('Guía virtual'), findsOneWidget);

  await tapText(tester, 'Seguridad');
  expect(find.text('Seguridad y normas'), findsOneWidget);

  await tapText(tester, 'i');
  expect(find.text('PNN Los Nevados'), findsOneWidget);

  await tapText(tester, 'Ruta');
  await mostrar(tester, 'Fuera del recorrido habilitado');
  expect(find.text('Fuera del recorrido habilitado'), findsOneWidget);
}

void main() {
  testWidgets('navega por todas las secciones', recorrer);

  testWidgets('"Estoy aquí" cambia la paleta de la estación', (tester) async {
    await tester.pumpWidget(const NevadoApp());
    await tester.pumpAndSettle();
    expect(find.text('Brisas · Páramo dorado'), findsOneWidget);

    await tapText(tester, 'Arenales');
    await tapText(tester, 'Estoy aquí');
    expect(find.text('Arenales · Ceniza volcánica'), findsOneWidget);
    expect(find.text('✓ Marcada como tu estación actual'), findsOneWidget);
  });

  testWidgets('pasar a la siguiente estación cambia la paleta', (tester) async {
    await tester.pumpWidget(const NevadoApp());
    await tester.pumpAndSettle();

    await tapText(tester, 'Brisas');
    expect(find.text('Brisas · Páramo dorado'), findsOneWidget);
    expect(find.textContaining('‹ '), findsNothing);

    await tapText(tester, '${estaciones[1].nombre} ›');
    expect(find.text('Aguacerales · Verde esmeralda'), findsOneWidget);

    await tapText(tester, '‹ ${estaciones[0].nombre}');
    expect(find.text('Brisas · Páramo dorado'), findsOneWidget);

    // Al volver a la ruta se recuperan los colores de la estación actual.
    await tapText(tester, '${estaciones[1].nombre} ›');
    await tapText(tester, '← Volver a la ruta');
    expect(find.text('Brisas · Páramo dorado'), findsOneWidget);
  });

  testWidgets('las fotos que faltan dejan su espacio reservado', (tester) async {
    await tester.pumpWidget(const NevadoApp());
    await tester.pumpAndSettle();
    await tapText(tester, 'Brisas');
    await tester.pumpAndSettle();
    expect(find.textContaining('FOTO PENDIENTE DE CARGAR'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('cada estación tiene texto propio en las cuatro pestañas', () {
    final vistos = <String>{};
    for (final e in estaciones) {
      for (final p in Pestana.values) {
        final textos = contenidoDe(e, p).whereType<BloqueTexto>().map((b) => b.texto).toList();
        expect(textos, isNotEmpty, reason: '${e.nombre} · ${p.etiqueta}');
        for (final t in textos) {
          expect(vistos.add(t), isTrue, reason: 'Texto repetido en ${e.nombre} · ${p.etiqueta}: $t');
        }
      }
    }
  });

  test('formatoMiles separa los miles con punto', () {
    expect(formatoMiles(4100), '4.100');
    expect(formatoMiles(950), '950');
    expect(formatoMiles(12345), '12.345');
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

      await recorrer(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
