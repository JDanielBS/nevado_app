import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/access/access_controller.dart';
import '../../core/access/pass.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import 'chat_controller.dart';

/// Al activar un pase que trae la dirección del modelo, lo descarga si falta.
void vincularModeloConPase(AccessController access, ChatController chat) {
  Pase? atendido;
  access.addListener(() {
    final pase = access.pase;
    final origen = pase?.modelo;
    // Volver a escanear crea otro objeto: así se puede reintentar con el mismo QR.
    if (!access.activo || origen == null || identical(pase, atendido)) return;
    atendido = pase;
    unawaited(chat.provision(origen));
  });
}

/// Da acceso al estado del modelo desde la pantalla de inicio.
class ModelScope extends InheritedNotifier<ChatController> {
  const ModelScope({super.key, required ChatController controller, required super.child})
    : super(notifier: controller);

  static ChatController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ModelScope>()?.notifier;
}

/// Avance de la descarga del modelo. No ocupa espacio si no se pidió ninguna.
class ModelStatus extends StatelessWidget {
  const ModelStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = ModelScope.maybeOf(context);
    final origen = chat?.origen;
    if (chat == null || origen == null) return const SizedBox.shrink();

    final reason = chat.phase == ChatPhase.unsupported ? chat.error : null;
    final failed = chat.error != null && (chat.phase == ChatPhase.noModel || chat.phase == ChatPhase.failed);
    final message = switch (chat.phase) {
      ChatPhase.downloading => 'Descargando ${chat.progress} %. No salgas de la red de la estación.',
      ChatPhase.loading => 'Comprobando el modelo…',
      _ when reason != null => reason,
      _ when failed => chat.error!,
      _ when chat.instalado => 'Modelo instalado. Ya puedes salir de la red.',
      _ => 'Preparando el modelo…',
    };

    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TituloCaja('Modelo del asistente'),
          Linea(message, tamano: 16),
          if (chat.phase == ChatPhase.downloading) LinearProgressIndicator(value: chat.progress / 100),
          if (failed) ...[
            const SizedBox(height: Espacio.s),
            FilledButton(onPressed: () => chat.provision(origen), child: const Text('Reintentar descarga')),
          ],
        ],
      ),
    );
  }
}
