import 'package:flutter/material.dart';

import '../chat/chat_screen.dart';
import '../emergency/emergency_screen.dart';
import '../location/location_screen.dart';
import '../map/map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _entries = <(String, IconData, Widget)>[
    ('Emergencias', Icons.emergency, EmergencyScreen()),
    ('Asistente', Icons.chat, ChatScreen()),
    ('Mi ubicación', Icons.my_location, LocationScreen()),
    ('Mapa', Icons.map, MapScreen()),
  ];

  @override
  Widget build(BuildContext context) {
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
              for (final (label, icon, screen) in _entries)
                FilledButton.icon(
                  icon: Icon(icon, size: 32),
                  label: Text(label),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => screen),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
