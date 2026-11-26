import 'package:flutter/widgets.dart';

import '../core/content/card.dart';
import '../core/settings/settings.dart';

/// Da acceso al contenido y a los ajustes desde cualquier pantalla y la redibuja cuando cambian.
class AppScope extends InheritedNotifier<Ajustes> {
  const AppScope({super.key, required this.cards, required Ajustes settings, required super.child})
      : super(notifier: settings);

  final List<Ficha> cards;

  Ajustes get settings => notifier!;

  /// `null` cuando una pantalla se muestra sola, como en las pruebas.
  static AppScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) => cards != oldWidget.cards || super.updateShouldNotify(oldWidget);
}
