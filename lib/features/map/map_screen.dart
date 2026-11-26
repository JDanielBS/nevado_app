import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/ui/palette.dart';
// El mapa es el visor web de maps/visor (MapLibre GL JS) empaquetado como recurso de la app.
// En Android se muestra en una vista web servida desde el propio teléfono; en el navegador,
// en un iframe. En ambos casos no se usa internet.
import 'map_view_io.dart' if (dart.library.js_interop) 'map_view_web.dart';

/// Mapa a pantalla completa, abierto desde "Ampliar mapa" en la ruta.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    // En modo ahorro el mapa se abre sin relieve.
    final flat = AppScope.maybeOf(context)?.settings.ahorroActivo ?? false;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: tema.encabezado,
        foregroundColor: tema.encabezadoTexto,
        title: Text('Mapa de la ruta', style: estiloTitulo(24, color: tema.encabezadoTexto)),
        shape: Border(bottom: BorderSide(color: tema.linea, width: 4)),
      ),
      body: SafeArea(child: MapView(flat: flat)),
    );
  }
}
