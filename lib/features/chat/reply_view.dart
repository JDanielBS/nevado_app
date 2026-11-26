import 'package:flutter/material.dart';

import '../../core/content/card.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';

/// Respuesta de las reglas de seguridad o de las fichas, con sus fuentes.
class ReplyView extends StatelessWidget {
  const ReplyView({super.key, required this.reply});

  final Respuesta reply;

  @override
  Widget build(BuildContext context) {
    final emergency = reply.tipo == TipoRespuesta.emergencia;
    return Caja(
      color: emergency ? Colores.emergenciaFondo : Colores.superficie,
      borde: emergency ? Colores.emergencia : Colores.borde,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (emergency) const Linea('EMERGENCIA', color: Colores.emergencia, negrita: true, tamano: 18),
          if (reply.tipo == TipoRespuesta.limite)
            const Linea('Límite de esta guía', color: Colores.aviso, negrita: true),
          Linea(reply.texto, tamano: 18),
          if (reply.fuentes.isNotEmpty) ...[
            const SizedBox(height: Espacio.s),
            const Linea('Basado en:', color: Colores.textoSuave),
            for (final card in reply.fuentes) FichaTarjeta(ficha: card, compacta: true),
          ],
        ],
      ),
    );
  }
}
