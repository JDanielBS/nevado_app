import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/access/access_controller.dart';
import 'core/access/access_store.dart';
import 'core/access/public_key.dart';
import 'core/content/card_repository.dart';
import 'core/settings/settings.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/model_provisioning.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cards = await cargarFichas();
  final access = AccessController(store: PreferencesAccessStore(), clavePublica: clavePublicaPases);
  vincularModeloConPase(access, chatDeLaApp);
  // No se espera: la app abre de inmediato y la sección Seguridad queda disponible mientras se comprueba.
  unawaited(access.iniciar());
  runApp(NevadoApp(cards: cards, settings: Ajustes()..iniciar(), access: access, model: chatDeLaApp));
}
