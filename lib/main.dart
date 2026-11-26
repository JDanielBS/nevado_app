import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/content/card_repository.dart';
import 'core/settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cards = await cargarFichas();
  runApp(NevadoApp(cards: cards, settings: Ajustes()..iniciar()));
}
