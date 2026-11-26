import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'card.dart';

/// Ruta del paquete de contenido. Hoy es contenido de demostración; cuando exista
/// contenido revisado, cambiar solo esta ruta para leer el paquete verificado.
const rutaFichas = 'assets/content/fichas.demo.json';

/// Fuente única de fichas de la app.
Future<List<Ficha>> cargarFichas() async => fichasDesdeTexto(await rootBundle.loadString(rutaFichas));

List<Ficha> fichasDesdeTexto(String texto) =>
    [for (final f in jsonDecode(texto) as List) Ficha.desdeJson(f as Map<String, dynamic>)];

List<Ficha> fichasDeEmergencia(List<Ficha> fichas) =>
    fichas.where((f) => f.categoria == Categoria.emergencia).toList();

bool hayContenidoSinVerificar(List<Ficha> fichas) => fichas.any((f) => !f.verificada);
