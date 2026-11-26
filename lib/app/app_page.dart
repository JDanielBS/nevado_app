import 'package:flutter/material.dart';

import '../core/ui/palette.dart';
import '../core/ui/widgets.dart';
import '../features/emergency/emergency_screen.dart';
import 'app_scope.dart';

/// Estructura común de las pantallas: barra superior con acceso a emergencias y aviso de ahorro.
class AppPage extends StatelessWidget {
  const AppPage({super.key, required this.title, required this.body, this.showEmergency = true});

  final String title;
  final Widget body;
  final bool showEmergency;

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.maybeOf(context)?.settings;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [if (showEmergency) const _EmergencyButton()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (settings != null) AvisoAhorro(ajustes: settings),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/// Acceso a emergencias desde cualquier pantalla.
class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton.filled(
        tooltip: 'Ir a emergencias',
        style: IconButton.styleFrom(
          backgroundColor: Colores.emergencia,
          foregroundColor: Colors.white,
          minimumSize: const Size(altoMinimo, altoMinimo),
        ),
        icon: const Icon(Icons.sos),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EmergencyScreen()),
        ),
      ),
    );
  }
}
