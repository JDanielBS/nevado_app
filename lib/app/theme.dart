import 'package:flutter/material.dart';

final appTheme = ThemeData(
  colorScheme: const ColorScheme.highContrastLight(),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(80),
      padding: const EdgeInsets.all(16),
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  ),
);
