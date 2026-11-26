import 'package:flutter/widgets.dart';

import '../core/content/card.dart';
import '../core/content/seccion.dart';
import '../core/search/search.dart';
import '../core/settings/settings.dart';

/// Da acceso al contenido y a los ajustes desde cualquier pantalla y la redibuja cuando cambian.
class AppScope extends InheritedNotifier<Ajustes> {
  AppScope({
    super.key,
    this.emergencia = const [],
    this.secciones = const [],
    IndiceGuia? indice,
    this.esGuia = false,
    required Ajustes settings,
    required super.child,
  }) : indice = indice ?? IndiceGuia.vacio,
       super(notifier: settings);

  /// Tarjetas fijas de emergencia.
  final List<Ficha> emergencia;

  /// Secciones de la guía disponibles ahora.
  final List<SeccionGuia> secciones;
  final IndiceGuia indice;

  /// Es la app del guía: sin pase y con edición del contenido.
  final bool esGuia;

  Ajustes get settings => notifier!;

  /// `null` cuando una pantalla se muestra sola, como en las pruebas.
  static AppScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      emergencia != oldWidget.emergencia ||
      secciones != oldWidget.secciones ||
      indice != oldWidget.indice ||
      esGuia != oldWidget.esGuia ||
      super.updateShouldNotify(oldWidget);
}
