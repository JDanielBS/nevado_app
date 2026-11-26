import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum EstadoUbicacion { inactiva, pidiendo, denegada, desactivada, error, lista }

class Posicion {
  const Posicion(this.latitud, this.longitud, this.precisionM, this.marcaTiempoMs);
  final double latitud;
  final double longitud;
  final double? precisionM;
  final int marcaTiempoMs;
}

const _esperaMaxima = Duration(seconds: 25);

/// Una sola lectura de ubicación, solo en primer plano y solo cuando la persona la pide.
/// La posición no se envía a ningún lado. Funciona sin internet (usa el GPS del teléfono).
class Ubicacion extends ChangeNotifier {
  EstadoUbicacion estado = EstadoUbicacion.inactiva;
  Posicion? posicion;

  void _cambiar(EstadoUbicacion nuevo) {
    estado = nuevo;
    notifyListeners();
  }

  Future<void> obtener() async {
    _cambiar(EstadoUbicacion.pidiendo);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _cambiar(EstadoUbicacion.desactivada);
        return;
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        _cambiar(EstadoUbicacion.denegada);
        return;
      }
      final lectura = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: _esperaMaxima),
      );
      posicion = Posicion(
        lectura.latitude,
        lectura.longitude,
        lectura.accuracy,
        lectura.timestamp.millisecondsSinceEpoch,
      );
      _cambiar(EstadoUbicacion.lista);
    } catch (_) {
      _cambiar(EstadoUbicacion.error);
    }
  }
}
