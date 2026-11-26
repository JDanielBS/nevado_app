import 'dart:io';

import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show EagerGestureRecognizer, OneSequenceGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/ui/palette.dart';

/// Servidor HTTP local (solo 127.0.0.1) que entrega los archivos del mapa empaquetados en la app.
/// Hace falta porque el visor carga sus datos con peticiones HTTP; nada sale del teléfono.
abstract final class ServidorMapa {
  static Future<Uri>? _direccion;

  static const _tipos = {
    'html': 'text/html; charset=utf-8',
    'js': 'text/javascript; charset=utf-8',
    'css': 'text/css; charset=utf-8',
    'geojson': 'application/geo+json',
    'json': 'application/json',
    'png': 'image/png',
    'jpg': 'image/jpeg',
  };

  static Future<Uri> direccion() => _direccion ??= _iniciar();

  static Future<Uri> _iniciar() async {
    final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((peticion) async {
      final respuesta = peticion.response;
      final ruta = Uri.decodeComponent(peticion.uri.path);
      try {
        if (ruta.contains('..')) throw const FormatException('ruta no permitida');
        final datos = await rootBundle.load('assets/map$ruta');
        final extension = ruta.split('.').last;
        respuesta.headers.set(HttpHeaders.contentTypeHeader, _tipos[extension] ?? 'application/octet-stream');
        respuesta.add(datos.buffer.asUint8List(datos.offsetInBytes, datos.lengthInBytes));
      } catch (_) {
        respuesta.statusCode = HttpStatus.notFound;
      }
      await respuesta.close();
    });
    return Uri.parse('http://127.0.0.1:${servidor.port}/visor/index.html');
  }
}

class MapView extends StatefulWidget {
  const MapView({super.key, required this.flat});

  /// Abre el mapa sin relieve (por ejemplo en modo ahorro).
  final bool flat;

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late final WebViewController _controlador;
  bool _disponible = false;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Sin implementación de vista web (por ejemplo en las pruebas) se muestra un aviso.
    if (WebViewPlatform.instance == null) {
      _error = 'El mapa no está disponible en este equipo.';
      return;
    }
    _controlador = WebViewController();
    _disponible = true;
    _abrir();
  }

  Future<void> _abrir() async {
    try {
      final base = await ServidorMapa.direccion();
      final direccion = base.replace(queryParameters: {'app': '1', if (widget.flat) 'plano': '1'});
      await _controlador.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controlador.setBackgroundColor(const Color(0xFFE7ECE9));
      await _controlador.setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => mounted ? setState(() => _cargando = false) : null,
        // El mapa no navega a ningún sitio externo.
        onNavigationRequest: (solicitud) => solicitud.url.startsWith(base.origin)
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
      ));
      await _controlador.loadRequest(direccion);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo abrir el mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null || !_disponible) {
      return Center(child: Padding(padding: const EdgeInsets.all(Espacio.l), child: Text(_error!, textAlign: TextAlign.center)));
    }
    return Stack(
      children: [
        // El mapa toma los gestos dentro de su marco aunque esté dentro de una lista desplazable.
        WebViewWidget(
          controller: _controlador,
          gestureRecognizers: {Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new)},
        ),
        if (_cargando) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
