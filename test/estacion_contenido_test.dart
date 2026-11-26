import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/app/app_scope.dart';
import 'package:nevado_app/core/settings/settings.dart';
import 'package:nevado_app/core/route/estaciones.dart';
import 'package:nevado_app/features/station/temas_de_estacion.dart';

import 'seccion_test.dart' show seccionesDelProyecto;

void main() {
  final secciones = seccionesDelProyecto();

  test('cada estación del recorrido tiene su tema en el contenido', () {
    for (final e in estaciones) {
      final temas = temasDeEstacion(secciones, e.nombre);
      expect(temas.any((t) => t.$1.archivo == 'estaciones.md'), isTrue, reason: e.nombre);
    }
  });

  test('incluye temas de otras secciones etiquetados con la estación', () {
    final temas = temasDeEstacion(secciones, 'Aguacerales');
    expect(temas.map((t) => t.$1.archivo).toSet().length, greaterThan(1));
  });

  test('la capa del recorrido marca todo como sin verificar', () {
    final capa = jsonDecode(File('assets/map/salida/recorrido.geojson').readAsStringSync()) as Map;
    final features = (capa['features'] as List).cast<Map>();
    expect(features.where((f) => f['properties']['tipo'] == 'tramo'), hasLength(4));
    expect(features.where((f) => f['properties']['tipo'] == 'estacion'), hasLength(5));
    for (final f in features) {
      expect(f['properties']['verificado'], isFalse);
    }
    for (final f in features.where((f) => f['properties']['tipo'] == 'estacion')) {
      expect(f['properties']['distancia_al_camino_m'], lessThan(300));
    }
  });

  // Fallo visto en el teléfono: la lista de la estación usa PageStorageKey y el "Ver más" leía su
  // desplazamiento como si fuera abierto o cerrado.
  testWidgets('el "Ver más" funciona al volver a una estación ya desplazada', (tester) async {
    final mostrar = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          secciones: secciones,
          settings: Ajustes(),
          child: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: mostrar,
              builder: (context, ver, _) => !ver
                  ? const SizedBox()
                  : ListView(
                      key: const PageStorageKey('Aguacerales'),
                      children: const [SizedBox(height: 50), TemasDeEstacion(estacion: 'Aguacerales')],
                    ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    mostrar.value = false;
    await tester.pump();
    mostrar.value = true;
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
