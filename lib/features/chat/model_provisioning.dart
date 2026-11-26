import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/access/access_controller.dart';
import '../../core/access/pass.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import 'chat_controller.dart';
import 'voice_chat_controller.dart';

/// Descarga de la estación el modelo y, cuando está listo, la voz.
Future<void> descargarDeEstacion(Uri origen, ChatController chat, VoiceChatController? voz) async {
  await chat.provision(origen);
  if (chat.instalado) await voz?.provision(origen);
}

/// Al activar un pase que trae la dirección del modelo, descarga lo que falte.
void vincularModeloConPase(AccessController access, ChatController chat, [VoiceChatController? voz]) {
  Pase? atendido;
  access.addListener(() {
    final pase = access.pase;
    final origen = pase?.modelo;
    // Volver a escanear crea otro objeto: así se puede reintentar con el mismo QR.
    if (!access.activo || origen == null || identical(pase, atendido)) return;
    atendido = pase;
    unawaited(descargarDeEstacion(origen, chat, voz));
  });
}

/// Da acceso al estado del modelo desde la pantalla de inicio.
class ModelScope extends InheritedNotifier<ChatController> {
  const ModelScope({super.key, required ChatController controller, required super.child})
    : super(notifier: controller);

  static ChatController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ModelScope>()?.notifier;
}

/// Da acceso al estado de la voz desde la pantalla de inicio.
class VoiceScope extends InheritedNotifier<VoiceChatController> {
  const VoiceScope({super.key, required VoiceChatController controller, required super.child})
    : super(notifier: controller);

  static VoiceChatController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VoiceScope>()?.notifier;
}

/// Avance de la descarga del modelo y de la voz. No ocupa espacio si no se pidió ninguna.
class ModelStatus extends StatelessWidget {
  const ModelStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = ModelScope.maybeOf(context);
    final origen = chat?.origen;
    if (chat == null || origen == null) return const SizedBox.shrink();

    final voz = VoiceScope.maybeOf(context);
    // Con el modelo listo todavía puede faltar la voz.
    final faltaVoz = chat.instalado && voz != null && !voz.instalada && voz.phase != VoicePhase.unsupported;
    final reason = chat.phase == ChatPhase.unsupported ? chat.error : null;
    final failed = faltaVoz
        ? voz.error != null && (voz.phase == VoicePhase.noModel || voz.phase == VoicePhase.failed)
        : chat.error != null && (chat.phase == ChatPhase.noModel || chat.phase == ChatPhase.failed);
    final progreso = faltaVoz
        ? (voz.phase == VoicePhase.downloading ? voz.progress : null)
        : (chat.phase == ChatPhase.downloading ? chat.progress : null);
    final message = faltaVoz
        ? (failed
            ? voz.error!
            : progreso != null
            ? 'Descargando la voz $progreso %. No salgas de la red de la estación.'
            : 'Preparando la voz. No salgas de la red de la estación.')
        : switch (chat.phase) {
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
          if (progreso != null) LinearProgressIndicator(value: progreso / 100),
          if (failed) ...[
            const SizedBox(height: Espacio.s),
            FilledButton(
              onPressed: () => descargarDeEstacion(origen, chat, voz),
              child: const Text('Reintentar descarga'),
            ),
          ],
        ],
      ),
    );
  }
}
