import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/assistant/responder.dart';
import 'package:nevado_app/core/search/search.dart';
import 'package:nevado_app/core/search/normalize.dart';
import 'package:nevado_app/core/content/card_repository.dart';
import 'package:nevado_app/core/content/card.dart';

import 'seccion_test.dart' show seccionesDelProyecto;

void main() {
  final emergencia = fichasDesdeTexto(File(rutaEmergencia).readAsStringSync());
  final indice = IndiceGuia.de(seccionesDelProyecto());

  group('normalizar y tokenizar', () {
    test('quita tildes y mayúsculas', () {
      expect(normalizar('Frailejón ÁÉÍ'), 'frailejon aei');
    });
    test('reduce plurales y descarta palabras vacías', () {
      expect(tokenizar('¿Qué son los frailejones?'), ['frailejon']);
    });
  });

  group('buscar en la guía', () {
    test('encuentra por palabra del título aunque tenga tilde distinta', () {
      expect(indice.buscar('frailejon').first.fragmento.ruta, contains('Frailejón'));
    });
    test('no devuelve nada para una consulta sin relación', () {
      expect(indice.buscar('receta de arepas'), isEmpty);
    });
    test('no devuelve nada para consulta vacía', () {
      expect(indice.buscar('   '), isEmpty);
    });
    test('devuelve como máximo los fragmentos que caben en el modelo', () {
      expect(indice.buscar('volcán glaciar roca páramo agua').length, lessThanOrEqualTo(fragmentosPorPregunta));
    });
  });

  group('capa fija', () {
    test('medicamentos se responde con un límite, sin fuentes', () {
      for (final q in ['¿qué pastilla tomo para el soroche?', '¿cuánta acetazolamida tomo?', 'dosis de ibuprofeno']) {
        final r = respuestaFija(q, emergencia);
        expect(r?.tipo, TipoRespuesta.limite, reason: q);
        expect(r?.fuentes, isEmpty);
      }
    });
    test('las demás preguntas no son fijas: van a la guía y al modelo', () {
      for (final q in ['¿qué clima hace hoy?', '¿es seguro ir al nevado?', '¿cuánto se demora la caminata?']) {
        expect(respuestaFija(q, emergencia), isNull, reason: q);
      }
    });
    test('sin fragmentos se dice que no hay información', () {
      final r = respuestaConFragmentos(const []);
      expect(r.tipo, TipoRespuesta.sinInformacion);
      expect(r.texto, mensajeSinInformacion);
    });
  });

  group('responder: emergencias', () {
    const urgencias = [
      'estoy perdido',
      'hay un herido',
      'tuvimos un accidente',
      'necesito auxilio',
      'me rompí la pierna',
      'se me quebró el brazo',
      'mi amiga se torció el tobillo',
      'creo que tengo la muñeca rota',
      'creo que es una fractura',
      'me caí por una ladera',
      'se golpeó la cabeza',
      'me corté con una piedra y sale sangre',
      'mi compañero se desmayó',
      'no puede respirar',
      'me duele mucho el pecho',
      'no puedo caminar',
      'me mordió un perro',
    ];
    for (final pregunta in urgencias) {
      test('"$pregunta" entrega la tarjeta de emergencia', () {
        final r = respuestaFija(pregunta, emergencia);
        expect(r?.tipo, TipoRespuesta.emergencia);
        expect(r?.tarjetas.first.categoria, Categoria.emergencia);
      });
    }
  });

  group('responder: sin falsas emergencias', () {
    const normales = [
      '¿se pueden romper ramas?',
      'se me rompió la carpa',
      '¿puedo caminar sin guía?',
      '¿dónde puedo dejar la basura?',
      'me duele la cabeza y tengo mareo por la altura',
      '¿qué es un frailejón?',
    ];
    for (final pregunta in normales) {
      test('"$pregunta" no se trata como emergencia', () {
        expect(respuestaFija(pregunta, emergencia)?.tipo, isNot(TipoRespuesta.emergencia));
      });
    }
  });

  group('tarjetas de emergencia', () {
    test('tienen fuente y los ids son únicos', () {
      final ids = emergencia.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final f in emergencia) {
        expect(f.fuente, isNotEmpty);
      }
    });
    test('una tarjeta verificada exige fecha de verificación', () {
      for (final f in emergencia.where((x) => x.verificada)) {
        expect(f.fechaVerificacion, isNotNull);
      }
    });
  });
}
