import 'package:flutter/material.dart';

import '../../core/content/card.dart';
import '../../core/ui/palette.dart';
import 'chat_controller.dart';

/// Burbuja de conversación. Las del visitante van a la derecha con el color de acento.
class Burbuja extends StatelessWidget {
  const Burbuja({
    super.key,
    required this.texto,
    this.propia = false,
    this.fuente,
    this.encabezado,
    this.fondo,
    this.borde,
  });

  final String texto;

  /// La escribió el visitante.
  final bool propia;

  /// Línea pequeña bajo el texto (de dónde sale la respuesta).
  final String? fuente;

  /// Rótulo en negrita sobre el texto (por ejemplo "EMERGENCIA").
  final String? encabezado;
  final Color? fondo;
  final Color? borde;

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    final color = fondo ?? (propia ? tema.acento : Colores.superficie);
    final textoColor = propia ? Colors.white : Colores.texto;
    return Align(
      alignment: propia ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        alignment: propia ? Alignment.centerRight : Alignment.centerLeft,
        child: Align(
          alignment: propia ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borde ?? (propia ? tema.acento : Colores.borde), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (encabezado != null)
                  Text(encabezado!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textoColor)),
                SelectableText(texto, style: TextStyle(fontSize: 15, height: 1.45, color: textoColor)),
                if (fuente != null) ...[
                  const SizedBox(height: 4),
                  Text(fuente!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textoColor)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pregunta y respuesta de un turno.
class TurnoView extends StatelessWidget {
  const TurnoView({super.key, required this.turno, required this.respondiendo});

  final Turno turno;

  /// El modelo aún está escribiendo esta respuesta.
  final bool respondiendo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Burbuja(texto: turno.pregunta, propia: true),
        if (turno.respuesta case final r?)
          ReplyView(reply: r)
        else if (turno.generado.isNotEmpty)
          Burbuja(texto: turno.generado, fuente: 'Respuesta del modelo, sin fuente verificada')
        else if (respondiendo)
          const Burbuja(texto: '…')
        else if (turno.fallo)
          const Burbuja(texto: 'Sin respuesta.', fuente: 'Intenta de nuevo o consulta a tu guía'),
      ],
    );
  }
}

/// Respuesta de las reglas de seguridad o de las fichas, con sus fuentes.
class ReplyView extends StatelessWidget {
  const ReplyView({super.key, required this.reply});

  final Respuesta reply;

  @override
  Widget build(BuildContext context) {
    final fuente = reply.fuentes.isEmpty
        ? (reply.tipo == TipoRespuesta.sinInformacion ? 'Sin respuesta en las fichas del parque' : null)
        : 'Fuente: ${reply.fuentes.map((f) => f.titulo).join(' · ')}'
            '${reply.fuentes.every((f) => f.verificada) ? '' : ' (sin verificar)'}';
    return switch (reply.tipo) {
      TipoRespuesta.emergencia => Burbuja(
          texto: reply.texto,
          encabezado: 'EMERGENCIA',
          fuente: fuente,
          fondo: Colores.emergenciaFondo,
          borde: Colores.tinta,
        ),
      TipoRespuesta.limite => Burbuja(
          texto: reply.texto,
          encabezado: 'Límite de esta guía',
          fuente: fuente,
          fondo: Colores.avisoFondo,
          borde: Colores.aviso,
        ),
      _ => Burbuja(texto: reply.texto, fuente: fuente),
    };
  }
}
