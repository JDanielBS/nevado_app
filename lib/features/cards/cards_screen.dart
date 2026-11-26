import 'package:flutter/material.dart';

import '../../app/app_page.dart';
import '../../app/app_scope.dart';
import '../../core/content/card.dart';
import '../../core/search/search.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';

/// Listado de las fichas de la guía, con búsqueda y filtro por categoría.
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  Categoria? _category;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cards = AppScope.maybeOf(context)?.cards ?? const <Ficha>[];
    final matches = _query.trim().isEmpty
        ? cards
        : [for (final c in buscar(_query, cards, max: cards.length, umbral: 1)) c.ficha];
    final visible = _category == null ? matches : matches.where((c) => c.categoria == _category).toList();

    return AppPage(
      title: 'Fichas',
      body: ListView(
        padding: const EdgeInsets.all(Espacio.m),
        children: [
          TextField(
            onChanged: (text) => setState(() => _query = text),
            decoration: const InputDecoration(
              labelText: 'Buscar en las fichas',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: Espacio.s),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('Todas', null),
              for (final category in {for (final c in cards) c.categoria})
                _chip(etiquetaCategoria[category] ?? category.name, category),
            ],
          ),
          const SizedBox(height: Espacio.m),
          if (visible.isEmpty) const Text('No hay fichas para esa búsqueda.'),
          for (final card in visible) FichaTarjeta(ficha: card),
        ],
      ),
    );
  }

  Widget _chip(String label, Categoria? category) => ChoiceChip(
        label: Text(label),
        selected: _category == category,
        onSelected: (_) => setState(() => _category = category),
      );
}
