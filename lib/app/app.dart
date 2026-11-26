import 'package:flutter/material.dart';

import '../core/content/card.dart';
import '../core/settings/settings.dart';
import '../features/home/home_screen.dart';
import 'app_scope.dart';
import 'theme.dart';

class NevadoApp extends StatefulWidget {
  const NevadoApp({super.key, this.cards = const [], this.settings});

  /// Contenido de la guía incluido en la instalación.
  final List<Ficha> cards;

  /// Ajustes ya iniciados. Si se omiten se usan unos sin lectura de batería (pruebas).
  final Ajustes? settings;

  @override
  State<NevadoApp> createState() => _NevadoAppState();
}

class _NevadoAppState extends State<NevadoApp> {
  late final Ajustes _settings = widget.settings ?? Ajustes();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nevados',
      theme: appTheme,
      // El ámbito va por encima del navegador para que todas las pantallas lo vean.
      builder: (context, child) => AppScope(
        cards: widget.cards,
        settings: _settings,
        child: ListenableBuilder(
          listenable: _settings,
          builder: (context, _) => MediaQuery(
            // Por defecto se respeta el tamaño de texto del sistema (RE-03).
            data: _settings.escala == 1
                ? MediaQuery.of(context)
                : MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_settings.escala)),
            child: child!,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
