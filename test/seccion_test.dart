import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/assistant/responder.dart';
import 'package:nevado_app/core/content/card.dart';
import 'package:nevado_app/core/content/contenido_guia.dart';
import 'package:nevado_app/core/content/seccion.dart';
import 'package:nevado_app/core/search/search.dart';

/// Ejemplo de `Docs/estrategia-informacion.md`.
const ejemplo = '''
# Naturaleza

## Frailejón
> Planta emblemática del páramo.
Estaciones: Aguacerales

### Ficha técnica
![Frailejón en Aguacerales](media/imagenes/frailejon-a1b2.webp)

#### Qué es
> Su papel en el páramo.

Planta que capta agua de la niebla.

#### Datos
- Nombre científico: Espeletia hartwegiana
- Dónde verlo: Aguacerales

Fuente: Guion Ecoturístico UTON 2024, p. 5

### Detalle

#### Adaptaciones
> Cómo resiste el frío.

Tiene hojas gruesas y vellosas. Las hojas muertas lo protegen del frío.

Fuente: Guion Ecoturístico UTON 2024, p. 5

#### Sin respaldo

Texto sin fuente.
''';

List<SeccionGuia> seccionesDelProyecto() {
  final dir = Directory(rutaSecciones);
  final orden = (jsonDecode(File('${dir.path}/orden.json').readAsStringSync()) as List).cast<String>();
  return [for (final a in orden) leerSeccion(a, File('${dir.path}/$a').readAsStringSync())];
}

void main() {
  group('lectura del Markdown', () {
    final s = leerSeccion('naturaleza.md', ejemplo);
    final tema = s.temas.single;

    test('reconoce sección, tema, descripción y estaciones', () {
      expect(s.titulo, 'Naturaleza');
      expect(tema.titulo, 'Frailejón');
      expect(tema.descripcion, 'Planta emblemática del páramo.');
      expect(tema.estaciones, ['Aguacerales']);
    });

    test('separa ficha técnica y detalle, con apartados y descripciones', () {
      expect(tema.ficha.map((a) => a.titulo), [null, 'Qué es', 'Datos']);
      expect(tema.ficha[1].descripcion, 'Su papel en el páramo.');
      expect(tema.ficha[1].texto, 'Planta que capta agua de la niebla.');
      expect(tema.detalle.map((a) => a.titulo), ['Adaptaciones', 'Sin respaldo']);
    });

    test('un apartado sin fuente toma la de su nivel', () {
      expect(tema.ficha[1].fuente, 'Guion Ecoturístico UTON 2024, p. 5');
      expect(tema.detalle[1].fuente, 'Guion Ecoturístico UTON 2024, p. 5');
    });

    test('escribir y volver a leer conserva el contenido', () {
      final otra = leerSeccion('naturaleza.md', escribirSeccion(s));
      expect(escribirSeccion(otra), escribirSeccion(s));
      expect(otra.temas.single.detalle.first.texto, tema.detalle.first.texto);
    });

    test('el texto del guía no se confunde con títulos ni fuentes', () {
      final copia = s.temas.single.copia()..detalle.first.texto = '# No es título\nFuente: inventada';
      final escrita = escribirSeccion(SeccionGuia(archivo: 'x.md', titulo: 'X', temas: [copia]));
      final leida = leerSeccion('x.md', escrita).temas.single.detalle.first;
      expect(leida.fuente, 'Guion Ecoturístico UTON 2024, p. 5');
      expect(fragmentar([leerSeccion('x.md', escrita)]).firstWhere((f) => f.ruta.endsWith('Adaptaciones')).texto, contains('Fuente: inventada'));
    });
  });

  group('fragmentos', () {
    final fragmentos = fragmentar([leerSeccion('naturaleza.md', ejemplo)]);

    test('cada apartado con fuente es un fragmento con su ruta', () {
      expect(fragmentos.map((f) => f.ruta), contains('Naturaleza > Frailejón > Detalle > Adaptaciones'));
      final adaptaciones = fragmentos.firstWhere((f) => f.ruta.endsWith('Adaptaciones'));
      expect(adaptaciones.descripcion, 'Planta emblemática del páramo. Cómo resiste el frío.');
      expect(adaptaciones.estaciones, ['Aguacerales']);
    });

    test('la imagen se indexa por su descripción', () {
      expect(fragmentos.first.texto, 'Imagen: Frailejón en Aguacerales.');
    });
  });

  group('contenido del proyecto', () {
    final secciones = seccionesDelProyecto();
    final indice = IndiceGuia.de(secciones);

    test('todas las secciones se leen y tienen fragmentos con fuente', () {
      expect(secciones, hasLength(10));
      expect(indice.cantidad, greaterThan(40));
      for (final f in fragmentar(secciones)) {
        expect(f.fuente.trim(), isNotEmpty, reason: f.ruta);
      }
    });

    test('no incluye medicamentos ni la alerta como dato actual', () {
      final todo = secciones.map(escribirSeccion).join().toLowerCase();
      expect(todo, isNot(contains('acetazolamida')));
      expect(todo, isNot(contains('alerta amarilla')));
    });

    test('ningún fragmento supera el tamaño que recibe el modelo', () {
      for (final f in fragmentar(secciones)) {
        expect(f.texto.length, lessThan(maximoPorFragmento), reason: f.ruta);
      }
    });

    for (final (pregunta, esperado) in [
      ('¿Qué es el frailejón?', 'Frailejón'),
      ('¿Por qué las rocas del Valle Lunar son rojas?', 'rojiz'),
      ('¿Qué pasó en 1985?', '1985'),
      ('¿Puedo caminar sobre las dunas?', 'dunas'),
      ('¿Qué significa Kumanday?', 'Kumanday'),
    ]) {
      test('encuentra "$esperado" para "$pregunta"', () {
        final rutas = recuperar(indice, pregunta).map((f) => f.ruta);
        expect(rutas.any((r) => r.toLowerCase().contains(esperado.toLowerCase())), isTrue, reason: '$rutas');
      });
    }

    test('el paquete cifrable conserva las secciones', () {
      final paquete = ContenidoGuia(archivos: [for (final s in secciones) (s.archivo, escribirSeccion(s))]);
      final leido = ContenidoGuia.decodificar(paquete.codificar());
      expect(leido.secciones.map((s) => s.titulo), secciones.map((s) => s.titulo));
      expect(leido.verificado, isFalse);
    });

    test('rechaza nombres de archivo peligrosos', () {
      final malo = utf8.encode(
        jsonEncode({
          'formato': formatoContenido,
          'secciones': [
            {'archivo': '../x.md', 'md': '# X'},
          ],
        }),
      );
      expect(() => ContenidoGuia.decodificar(malo), throwsFormatException);
    });
  });

  group('prompt', () {
    test('lleva instrucciones, fragmentos numerados y la pregunta', () {
      final f = fragmentar([leerSeccion('naturaleza.md', ejemplo)]);
      final prompt = armarPrompt('¿Qué es?', f.take(2).toList());
      expect(prompt, contains('Usa solo los DOCUMENTOS'));
      expect(prompt, contains('[1] Naturaleza > Frailejón'));
      expect(prompt, endsWith('CONSULTA: ¿Qué es?'));
    });

    test('con tres fragmentos largos no pasa de unos 1.000 tokens', () {
      final largo = Fragmento(ruta: 'A', descripcion: '', estaciones: const [], texto: 'palabra ' * 2000, fuente: 'F');
      // Aproximación: 4 caracteres por token en español.
      expect(armarPrompt('pregunta', [largo, largo, largo]).length / 4, lessThan(1000));
    });
  });
}
