import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'card.dart';

/// Tarjetas de emergencia: van en la app, sin cifrar, para que estén siempre disponibles.
const rutaEmergencia = 'assets/content/emergencia.json';

Future<List<Ficha>> cargarFichasDeEmergencia() async =>
    fichasDesdeTexto(await rootBundle.loadString(rutaEmergencia));

List<Ficha> fichasDesdeTexto(String texto) => [
  for (final f in jsonDecode(texto) as List) Ficha.desdeJson(f as Map<String, dynamic>),
];
