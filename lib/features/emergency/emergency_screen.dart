import 'package:flutter/material.dart';

import '../../app/app_page.dart';
import '../../app/app_scope.dart';
import '../../core/content/card_repository.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';

/// Contenido fijo, sin búsqueda ni modelo. Siempre disponible.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = AppScope.maybeOf(context)?.cards ?? const [];
    return AppPage(
      title: 'Emergencias',
      showEmergency: false,
      body: ColoredBox(
        color: Colores.emergenciaFondo,
        child: ListView(
          padding: const EdgeInsets.all(Espacio.m),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: Espacio.m),
              padding: const EdgeInsets.all(Espacio.m),
              decoration: BoxDecoration(color: Colores.emergencia, borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'Esta guía no es un servicio de emergencias. Busca a un guía o funcionario del parque.',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, height: 1.4),
              ),
            ),
            for (final card in fichasDeEmergencia(cards)) FichaTarjeta(ficha: card),
          ],
        ),
      ),
    );
  }
}
