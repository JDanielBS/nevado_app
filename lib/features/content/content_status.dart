import 'package:flutter/material.dart';

import '../../core/content/content_controller.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import '../access/access_scope.dart';

/// Da acceso al estado del contenido desde la pantalla de inicio.
class ContentScope extends InheritedNotifier<ContentController> {
  const ContentScope({super.key, required ContentController controller, required super.child})
    : super(notifier: controller);

  static ContentController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ContentScope>()?.notifier;
}

/// Avisa si, con un pase vigente, el contenido de la guía no está disponible.
class ContentStatus extends StatelessWidget {
  const ContentStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final content = ContentScope.maybeOf(context);
    if (content == null || AccessScope.maybeOf(context)?.activo != true) return const SizedBox.shrink();

    final failed = content.estado != EstadoContenido.listo && content.estado != EstadoContenido.descargando;
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloCaja('Contenido de la guía'),
          Linea(switch (content.estado) {
            EstadoContenido.listo => 'Disponible mientras el pase esté vigente.',
            EstadoContenido.descargando => 'Descargando…',
            _ => 'No disponible. Conéctate a la red de la estación y escanea un pase de la estación.',
          }, tamano: 16),
          if (failed) ...[
            const SizedBox(height: Espacio.s),
            OutlinedButton(onPressed: content.reintentar, child: const Text('Reintentar contenido')),
          ],
        ],
      ),
    );
  }
}
