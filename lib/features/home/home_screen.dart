import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/content/card_repository.dart';
import '../../core/ui/widgets.dart';
import '../access/access_gate.dart';
import '../cards/cards_screen.dart';
import '../chat/chat_screen.dart';
import '../chat/model_provisioning.dart';
import '../content/content_status.dart';
import '../emergency/emergency_screen.dart';
import '../location/location_screen.dart';
import '../map/map_screen.dart';
import 'settings_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _entries = <(String, IconData, Widget)>[
    ('Emergencias', Icons.emergency, EmergencyScreen()),
    ('Asistente', Icons.chat, AccessGate(title: 'Asistente', child: ChatScreen())),
    ('Mi ubicación', Icons.my_location, LocationScreen()),
    ('Mapa', Icons.map, AccessGate(title: 'Mapa', child: MapScreen())),
    ('Fichas', Icons.menu_book, AccessGate(title: 'Fichas', child: CardsScreen())),
  ];

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.maybeOf(context);
    final settings = scope?.settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Nevados')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              const Text(
                'Esta app orienta y no reemplaza a guías ni a '
                'Parques Nacionales Naturales.',
              ),
              if (settings != null) AvisoAhorro(ajustes: settings),
              if (hayContenidoSinVerificar(scope?.cards ?? const []))
                const Text(
                  'El contenido es de demostración y aún no está verificado. '
                  'No lo uses para tomar decisiones de seguridad.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              const AccessCard(),
              const ContentStatus(),
              const ModelStatus(),
              for (final (label, icon, screen) in _entries)
                FilledButton.icon(
                  icon: Icon(icon, size: 32),
                  label: Text(label),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => screen),
                  ),
                ),
              if (settings != null) SettingsCard(settings: settings),
            ],
          ),
        ),
      ),
    );
  }
}
