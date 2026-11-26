import 'package:flutter/material.dart';

import '../core/ui/palette.dart';

final appTheme = ThemeData(
  fontFamily: Fuentes.cuerpo,
  colorScheme: const ColorScheme.light(
    primary: Colores.tinta,
    onPrimary: Colors.white,
    secondary: Colores.alerta,
    onSecondary: Colores.tinta,
    surface: Colores.superficie,
    onSurface: Colores.texto,
    error: Colores.aviso,
  ),
  scaffoldBackgroundColor: temasEstacion.first.fondo,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colores.superficie,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colores.tinta, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colores.tinta, width: 3),
    ),
  ),
);
