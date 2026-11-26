import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_page.dart';
import '../../core/location/location.dart';
import '../../core/location/location_format.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Mi ubicación',
      body: SingleChildScrollView(padding: EdgeInsets.all(Espacio.m), child: _LocationCard()),
    );
  }
}

class _LocationCard extends StatefulWidget {
  const _LocationCard();

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  final _location = Ubicacion();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _location.addListener(_onChange);
  }

  void _onChange() {
    // Reloj para que "hace X s" se actualice mientras se mira la pantalla.
    if (_location.posicion != null) {
      _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => setState(() {}));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _location.estado;
    final position = _location.posicion;
    final now = DateTime.now().millisecondsSinceEpoch;
    final accuracy = position == null ? null : describirPrecision(position.precisionM);
    final old = position != null && now - position.marcaTiempoMs > 5 * 60000;

    final message = switch (state) {
      EstadoUbicacion.inactiva =>
        'Usa el GPS del teléfono, sin internet. Solo se lee cuando tú lo pides y no se comparte con nadie.',
      EstadoUbicacion.pidiendo => 'Buscando señal GPS... puede tardar. Mejor al aire libre.',
      EstadoUbicacion.denegada => 'Sin permiso de ubicación. Puedes activarlo en los ajustes del teléfono.',
      EstadoUbicacion.desactivada => 'La ubicación del teléfono está apagada. Actívala y reintenta.',
      EstadoUbicacion.error => 'No se pudo obtener la ubicación. Sal a un lugar abierto y reintenta.',
      EstadoUbicacion.lista => null,
    };

    return Caja(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null) Linea(message, tamano: 16),
          if (position != null && accuracy != null) ...[
            // Seleccionable para copiar y dictar las coordenadas a un guardaparques (RF-05b).
            SelectableText(
              formatearCoordenadas(position.latitud, position.longitud),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Linea('Precisión: ${accuracy.texto}',
                color: accuracy.nivel == NivelPrecision.mala ? Colores.emergencia : Colores.texto),
            Linea(
              'Lectura ${describirAntiguedad(position.marcaTiempoMs, now)}'
              '${old ? ' (puede estar desactualizada)' : ''}',
              color: old ? Colores.emergencia : Colores.texto,
            ),
          ],
          const SizedBox(height: Espacio.m),
          FilledButton(
            onPressed: state == EstadoUbicacion.pidiendo ? null : _location.obtener,
            child: Text(position == null ? 'Obtener mi ubicación' : 'Actualizar ubicación'),
          ),
        ],
      ),
    );
  }
}
