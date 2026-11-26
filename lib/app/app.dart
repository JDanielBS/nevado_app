import 'package:flutter/material.dart';

import '../core/access/access_controller.dart';
import '../core/content/card.dart';
import '../core/content/content_controller.dart';
import '../core/settings/settings.dart';
import '../features/access/access_scope.dart';
import '../features/chat/chat_controller.dart';
import '../features/chat/model_provisioning.dart';
import '../features/content/content_status.dart';
import 'shell.dart';
import 'app_scope.dart';
import 'theme.dart';

class NevadoApp extends StatefulWidget {
  const NevadoApp({super.key, this.cards = const [], this.settings, this.access, this.model, this.content});

  /// Contenido de la guía incluido en la instalación.
  final List<Ficha> cards;

  /// Ajustes ya iniciados. Si se omiten se usan unos sin lectura de batería (pruebas).
  final Ajustes? settings;

  /// Control del pase de recorrido. Si se omite no se restringe nada (pruebas).
  final AccessController? access;

  /// Estado del modelo, para mostrar la descarga en el inicio.
  final ChatController? model;

  /// Fichas según el pase. Si se omite se usan [cards].
  final ContentController? content;

  @override
  State<NevadoApp> createState() => _NevadoAppState();
}

class _NevadoAppState extends State<NevadoApp> {
  late final Ajustes _settings = widget.settings ?? Ajustes();

  Widget _conContenido(Widget Function(List<Ficha> cards) construir) {
    final content = widget.content;
    if (content == null) return construir(widget.cards);
    return ContentScope(
      controller: content,
      child: ListenableBuilder(listenable: content, builder: (context, _) => construir(content.fichas)),
    );
  }

  Widget _conAcceso(Widget child) {
    final model = widget.model;
    if (model != null) child = ModelScope(controller: model, child: child);
    final access = widget.access;
    return access == null ? child : AccessScope(controller: access, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kumanday',
      theme: appTheme,
      // El ámbito va por encima del navegador para que todas las pantallas lo vean.
      builder: (context, child) => _conAcceso(
        _conContenido(
          (cards) => AppScope(
            cards: cards,
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
        ),
      ),
      home: const KumandayShell(),
    );
  }
}
