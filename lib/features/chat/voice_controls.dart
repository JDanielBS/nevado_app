import 'package:flutter/material.dart';

import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import 'chat_controller.dart';
import 'voice_chat_controller.dart';

/// Estado de la voz dentro de Guía IA: descarga, interruptor de lectura o motivo por el que no suena.
class PanelDeVoz extends StatelessWidget {
  const PanelDeVoz({super.key, required this.voz, required this.permitida});

  final VoiceChatController voz;

  /// `false` en modo ahorro o con la voz apagada en ajustes.
  final bool permitida;

  @override
  Widget build(BuildContext context) {
    if (!permitida) {
      return const Linea('La voz está desactivada por el modo ahorro o en los ajustes.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        ..._estado(context),
        if (voz.error != null && voz.phase != VoicePhase.unsupported)
          Linea(voz.error!, color: Colores.aviso, negrita: true),
      ],
    );
  }

  List<Widget> _estado(BuildContext context) => switch (voz.phase) {
        VoicePhase.checking => const [Linea('Revisando la voz…')],
        VoicePhase.unsupported => [Linea(voz.error ?? '')],
        VoicePhase.noModel => voz.canDownload
            ? [BotonSecundario(texto: 'Descargar voz', onPressed: voz.download)]
            : const [Linea('La voz se descarga en la estación al escanear el pase.')],
        VoicePhase.downloading => [
            Linea('Descargando la voz ${voz.progress} %'),
            LinearProgressIndicator(value: voz.progress / 100),
          ],
        VoicePhase.loading => const [Linea('Cargando la voz…'), LinearProgressIndicator()],
        VoicePhase.ready => [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Leer en voz alta'),
              subtitle: const Text('Solo las respuestas que escribe el modelo.'),
              value: voz.autoSpeak,
              activeTrackColor: TemaScope.of(context).acento,
              onChanged: voz.setAutoSpeak,
            ),
          ],
        VoicePhase.failed => [BotonSecundario(texto: 'Reintentar voz', onPressed: voz.retry)],
      };
}

/// "Repetir" o "Detener" bajo una respuesta escrita por el modelo.
class BotonDeVoz extends StatelessWidget {
  const BotonDeVoz({super.key, required this.voz, required this.turno});

  final VoiceChatController voz;
  final Turno turno;

  @override
  Widget build(BuildContext context) {
    final enCurso = voz.chat.answering && identical(voz.turnos.last, turno);
    if (voz.phase != VoicePhase.ready || enCurso || !voz.puedeLeer(turno)) return const SizedBox.shrink();
    final sonando = identical(voz.speaking, turno);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: BotonSecundario(
          texto: sonando ? 'Detener' : 'Repetir',
          onPressed: sonando ? voz.stop : () => voz.repeat(turno),
        ),
      ),
    );
  }
}
