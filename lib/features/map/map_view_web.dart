import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Versión para el navegador: el visor se abre en un iframe desde los recursos de la app.
class MapView extends StatelessWidget {
  const MapView({super.key, required this.flat, this.compact = false});

  /// Abre el mapa sin relieve (por ejemplo en modo ahorro).
  final bool flat;

  /// Muestra solo el terreno, sin controles ni nombres superpuestos.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      tagName: 'iframe',
      onElementCreated: (elemento) {
        final iframe = elemento as web.HTMLIFrameElement
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        iframe.src = 'assets/assets/map/visor/index.html?app=1${flat ? '&plano=1' : ''}${compact ? '&mini=1' : ''}';
      },
    );
  }
}
