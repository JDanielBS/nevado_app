import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/assistant/responder.dart';
import 'package:nevado_app/core/search/search.dart';
import 'package:nevado_app/core/search/normalize.dart';
import 'package:nevado_app/core/content/card_repository.dart';
import 'package:nevado_app/core/content/card.dart';

void main() {
  final fichas = fichasDesdeTexto(File(rutaFichas).readAsStringSync());

  group('normalizar y tokenizar', () {
    test('quita tildes y mayúsculas', () {
      expect(normalizar('Frailejón ÁÉÍ'), 'frailejon aei');
    });
    test('reduce plurales y descarta palabras vacías', () {
      expect(tokenizar('¿Qué son los frailejones?'), ['frailejon']);
    });
  });

  group('buscar', () {
    test('encuentra la ficha por palabra del título aunque tenga tilde distinta', () {
      expect(buscar('frailejon', fichas).first.ficha.id, 'flora-frailejon');
    });
    test('no devuelve nada para una consulta sin relación', () {
      expect(buscar('receta de arepas', fichas), isEmpty);
    });
    test('no devuelve nada para consulta vacía', () {
      expect(buscar('   ', fichas), isEmpty);
    });
  });

  group('responder: preguntas con respuesta', () {
    const casos = {
      '¿Qué es un frailejón?': 'flora-frailejon',
      'me duele la cabeza y tengo mareo por la altura': 'seguridad-mal-de-altura',
      'qué hago con la basura': 'norma-basura',
      'hay cóndores': 'fauna-condor',
      'el volcán Ruiz está activo': 'lugar-nevado-ruiz',
      'qué hago si hay tormenta con rayos': 'seguridad-tormenta',
    };
    casos.forEach((pregunta, id) {
      test('"$pregunta" usa la ficha $id', () {
        final r = responderPregunta(pregunta, fichas);
        expect(r.tipo, TipoRespuesta.respuesta);
        expect(r.fuentes.first.id, id);
      });
    });
  });

  group('responder: no inventa', () {
    test('dice que no tiene información fuera de tema', () {
      final r = responderPregunta('¿cómo se hace una arepa?', fichas);
      expect(r.tipo, TipoRespuesta.sinInformacion);
      expect(r.texto, mensajeSinInformacion);
      expect(r.fuentes, isEmpty);
    });
  });

  group('responder: límites de seguridad (preguntas trampa)', () {
    const trampas = [
      '¿qué clima hace hoy?',
      '¿va a llover ahora?',
      '¿cuál es el pronóstico de mañana?',
      '¿es seguro ir al nevado?',
      '¿puedo ir hoy?',
      '¿puedo subir hoy?',
      '¿qué pastilla tomo para el soroche?',
      '¿cuánto se demora la caminata?',
      '¿cuántas horas hay hasta la laguna?',
    ];
    for (final pregunta in trampas) {
      test('"$pregunta" se responde con un límite y sin fuentes', () {
        final r = responderPregunta(pregunta, fichas);
        expect(r.tipo, TipoRespuesta.limite);
        expect(r.fuentes, isEmpty);
      });
    }
    test('el clima en general sí usa la ficha', () {
      expect(responderPregunta('qué ropa llevo para el frío', fichas).fuentes.first.id, 'clima-general');
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
        final r = responderPregunta(pregunta, fichas);
        expect(r.tipo, TipoRespuesta.emergencia);
        expect(r.fuentes.first.categoria, Categoria.emergencia);
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
        expect(responderPregunta(pregunta, fichas).tipo, isNot(TipoRespuesta.emergencia));
      });
    }
  });

  group('contenido', () {
    test('todas las fichas tienen fuente y los ids son únicos', () {
      final ids = fichas.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final f in fichas) {
        expect(f.fuente, isNotEmpty);
      }
    });
    test('una ficha verificada exige fecha de verificación', () {
      for (final f in fichas.where((x) => x.verificada)) {
        expect(f.fechaVerificacion, isNotNull);
      }
    });
  });
}
