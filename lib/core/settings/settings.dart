import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/widgets.dart';

import 'battery_saver.dart';

/// Escalas de texto disponibles.
final escalasTexto = <double, String>{1: 'Normal', 1.25: 'Grande', 1.5: 'Muy grande'};

/// Estado global de accesibilidad y energía.
/// Los ajustes no se guardan al cerrar la app (pendiente).
class Ajustes extends ChangeNotifier with WidgetsBindingObserver {
  Ajustes({Battery? bateria}) : _bateria = bateria ?? Battery();

  final Battery _bateria;
  Timer? _reloj;

  double _escala = 1;

  /// Elección de la persona sobre el modo ahorro; `null` es automático.
  bool? _preferenciaAhorro;
  double? _nivelBateria;
  bool _ahorroSistema = false;

  double get escala => _escala;
  double? get nivelBateria => _nivelBateria;

  ({bool activo, MotivoAhorro? motivo}) get _ahorro =>
      calcularAhorro(nivel: _nivelBateria, ahorroSistema: _ahorroSistema, preferencia: _preferenciaAhorro);
  bool get ahorroActivo => _ahorro.activo;
  MotivoAhorro? get motivoAhorro => _ahorro.motivo;

  set escala(double valor) {
    _escala = valor;
    notifyListeners();
  }

  /// La persona activa o desactiva el modo ahorro, también cuando se activó solo.
  void elegirAhorro(bool activo) {
    // Si coincide con lo automático no hace falta recordar la elección.
    _preferenciaAhorro = activo == _automatico ? null : activo;
    notifyListeners();
  }

  bool get _automatico =>
      calcularAhorro(nivel: _nivelBateria, ahorroSistema: _ahorroSistema, preferencia: null).activo;

  void iniciar() {
    WidgetsBinding.instance.addObserver(this);
    leerBateria();
    // Android avisa los cambios de nivel con poca frecuencia: se relee cada minuto.
    _reloj = Timer.periodic(const Duration(minutes: 1), (_) => leerBateria());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) leerBateria();
  }

  Future<void> leerBateria() async {
    try {
      _nivelBateria = (await _bateria.batteryLevel) / 100;
      _ahorroSistema = await _bateria.isInBatterySaveMode;
      // Haberlo desactivado vale para este episodio: con la batería recuperada vuelve a ser automático.
      if (_preferenciaAhorro == false && !_automatico) _preferenciaAhorro = null;
      notifyListeners();
    } catch (_) {
      // Sin datos de batería (por ejemplo en el navegador) no se activa el ahorro automático.
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
