import 'package:flutter/material.dart';

import '../settings/battery_saver.dart';
import '../settings/settings.dart';
import '../content/card.dart';
import 'palette.dart';

/// Aviso de modo ahorro visible arriba de todas las pantallas.
class AvisoAhorro extends StatelessWidget {
  const AvisoAhorro({super.key, required this.ajustes});

  final Ajustes ajustes;

  @override
  Widget build(BuildContext context) {
    final motivo = ajustes.motivoAhorro;
    if (!ajustes.ahorroActivo || motivo == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: Espacio.m),
        decoration: const BoxDecoration(
          color: Colores.avisoFondo,
          border: Border(bottom: BorderSide(color: Colores.aviso)),
        ),
        child: Text(
          'Modo ahorro activo. ${textoMotivo[motivo]}',
          style: const TextStyle(color: Colores.aviso, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class FichaTarjeta extends StatelessWidget {
  const FichaTarjeta({super.key, required this.ficha, this.compacta = false});

  final Ficha ficha;

  /// En modo compacto no se repite el texto (se usa bajo las respuestas del asistente).
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (etiquetaCategoria[ficha.categoria] ?? ficha.categoria.name).toUpperCase(),
            style: const TextStyle(fontSize: 12, color: Colores.primario, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(ficha.titulo,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colores.texto)),
          if (!compacta) ...[
            const SizedBox(height: Espacio.s),
            Text(ficha.texto, style: const TextStyle(fontSize: 15, color: Colores.texto, height: 1.4)),
          ],
          const SizedBox(height: Espacio.s),
          Text('Fuente: ${ficha.fuente}', style: const TextStyle(fontSize: 12, color: Colores.textoSuave)),
          const SizedBox(height: 2),
          Text(
            ficha.verificada
                ? 'Verificada el ${ficha.fechaVerificacion}'
                : 'Contenido de demostración, sin verificar',
            style: TextStyle(fontSize: 12, color: ficha.verificada ? Colores.textoSuave : Colores.aviso),
          ),
        ],
      ),
    );
  }
}

class TituloCaja extends StatelessWidget {
  const TituloCaja(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Espacio.s),
        child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colores.texto)),
      );
}

class Linea extends StatelessWidget {
  const Linea(this.texto, {super.key, this.color = Colores.texto, this.negrita = false, this.tamano = 14});
  final String texto;
  final Color color;
  final bool negrita;
  final double tamano;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: tamano,
            color: color,
            height: 1.4,
            fontWeight: negrita ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );
}
