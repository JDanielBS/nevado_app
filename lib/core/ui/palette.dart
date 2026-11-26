import 'package:flutter/material.dart';

abstract final class Colores {
  static const fondo = Color(0xFFF4F7F5);
  static const superficie = Color(0xFFFFFFFF);
  static const texto = Color(0xFF1B2A22);
  static const textoSuave = Color(0xFF5A6B62);
  static const primario = Color(0xFF2F6B4F);
  static const borde = Color(0xFFD5DFD9);
  static const emergencia = Color(0xFFB3261E);
  static const emergenciaFondo = Color(0xFFFDECEA);
  static const aviso = Color(0xFF8A5A00);
  static const avisoFondo = Color(0xFFFFF4D6);
}

abstract final class Espacio {
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
}

/// Altura mínima de los controles, para uso con dedos o guantes finos.
const altoMinimo = 48.0;

/// Tarjeta blanca con borde, usada en todas las pantallas.
class Caja extends StatelessWidget {
  const Caja({super.key, required this.child, this.color = Colores.superficie, this.borde = Colores.borde});

  final Widget child;
  final Color color;
  final Color borde;

  // Se usa Material (no un fondo decorado) para que los controles internos muestren su efecto al tocarlos.
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: Espacio.m),
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borde),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Espacio.m),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      );
}
