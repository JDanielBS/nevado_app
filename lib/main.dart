import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/access/access_controller.dart';
import 'core/access/access_store.dart';
import 'core/access/public_key.dart';
import 'core/content/card_repository.dart';
import 'core/content/content_controller.dart';
import 'core/content/package_io.dart';
import 'core/settings/settings.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/model_provisioning.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = ContentController(emergencia: await cargarFichasDeEmergencia(), store: FilePackageStore());
  final access = AccessController(store: SecureAccessStore(), clavePublica: clavePublicaPases);
  content.vincular(access);
  vincularModeloConPase(access, chatDeLaApp, chatDeVozDeLaApp);
  // Sin pase vigente no se conserva ninguna respuesta en pantalla.
  access.addListener(() {
    if (!access.activo) chatDeLaApp.clear();
  });
  // No se espera: la app abre de inmediato y la sección Seguridad queda disponible mientras se comprueba.
  unawaited(access.iniciar());
  runApp(NevadoApp(
    settings: Ajustes()..iniciar(),
    access: access,
    content: content,
    model: chatDeLaApp,
    voice: chatDeVozDeLaApp,
  ));
}
