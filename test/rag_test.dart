import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/ai/retriever.dart';
import 'package:nevado_app/core/content/markdown_fragments.dart';
import 'package:nevado_app/core/search/hybrid_retriever.dart';

void main() {
  test('fragmenta Markdown heredando ruta, descripción y estación', () {
    final fragments = parseMarkdownFragments('''
# Naturaleza
## Frailejón
> Planta emblemática.
Estaciones: Aguacerales, Brisas
### Detalle
#### Función con el agua
> Atrapa humedad.

Sus hojas retienen agua.

Fuente: Guion UTON, p. 2
''', path: 'secciones/naturaleza.md');

    expect(fragments, hasLength(1));
    final fragment = fragments.single;
    expect(
      fragment.path,
      'Naturaleza > Frailejón > Detalle > Función con el agua',
    );
    expect(fragment.description, contains('Planta emblemática'));
    expect(fragment.stations, ['Aguacerales', 'Brisas']);
    expect(fragment.text, contains('Sus hojas retienen agua'));
    expect(fragment.source, 'Guion UTON, p. 2');
  });

  test('excluye fragmentos sin fuente y vencidos', () {
    final fragments = parseMarkdownFragments(
      '''
# Avisos
## Aviso
#### Vigente
Texto.
Fuente: Entidad
#### Vencido
Texto.
Vence: 2020-01-01
Fuente: Entidad
#### Sin fuente
Texto.
''',
      path: 'secciones/avisos.md',
      today: DateTime(2026, 11, 26),
    );

    expect(fragments.map((fragment) => fragment.title), ['Vigente']);
  });

  test('la búsqueda léxica usa la ruta y combina rankings con RRF', () async {
    const first = Fragment(
      id: 'a',
      text: 'agua',
      source: 'Fuente A',
      date: null,
      score: 0,
      path: 'Naturaleza > Frailejón > Detalle > Agua',
      title: 'Agua',
    );
    const second = Fragment(
      id: 'b',
      text: 'vegetación',
      source: 'Fuente B',
      date: null,
      score: 0,
      path: 'Naturaleza > Páramo > Detalle > Vegetación',
      title: 'Vegetación',
    );
    final retriever = HybridRetriever(
      lexical: [first, second],
      embedder: (query) async => query == 'agua' ? [second, first] : [],
    );

    final results = await retriever.retrieve('agua', limit: 2);
    expect(results, hasLength(2));
    expect(
      results.map((fragment) => fragment.id),
      containsAllInOrder(['a', 'b']),
    );
  });
}
