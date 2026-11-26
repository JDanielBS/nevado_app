import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'battery_saver.dart';

/// Escalas de texto disponibles.
final escalasTexto = <double, String>{1: 'Normal', 1.25: 'Grande', 1.5: 'Muy grande'};

/// Dónde se guardan los ajustes que se conservan al cerrar la app.
abstract interface class AjustesStore {
  Future<bool?> leerVozActiva();
  Future<void> guardarVozActiva(bool valor);
}

/// Almacenamiento local del teléfono.
class PreferencesAjustesStore implements AjustesStore {
  static const _claveVoz = 'ajustes.voz';

  // Se crea al usarlo: en pruebas puede no existir el almacenamiento.
  late final _preferencias = SharedPreferencesAsync();

  @override
  Future<bool?> leerVozActiva() => _preferencias.getBool(_claveVoz);

  @override
  Future<void> guardarVozActiva(bool valor) => _preferencias.setBool(_claveVoz, valor);
}

/// Estado global de accesibilidad, voz y energía.
/// Solo la voz se guarda al cerrar la app; el resto está pendiente.
class Ajustes extends ChangeNotifier with WidgetsBindingObserver {
  Ajustes({Battery? bateria, AjustesStore? store})
      : _bateria = bateria ?? Battery(),
        _store = store ?? PreferencesAjustesStore();

  final Battery _bateria;
  final AjustesStore _store;
  bool _vozActiva = true;
  Timer? _reloj;

  double _escala = 1;

  /// Elección de la persona sobre el modo ahorro; `null` es automático.
  bool? _preferenciaAhorro;
  double? _nivelBateria;
  bool _ahorroSistema = false;

  double get escala => _escala;
  double? get nivelBateria => _nivelBateria;

  /// Respuestas con audio en la Guía IA. El modo ahorro las apaga igualmente.
  bool get vozActiva => _vozActiva;

  set vozActiva(bool valor) {
    _vozActiva = valor;
    notifyListeners();
    unawaited(_guardarVoz(valor));
  }

  Future<void> _guardarVoz(bool valor) async {
    try {
      await _store.guardarVozActiva(valor);
    } catch (e) {
      debugPrint('Ajustes: $e');
    }
  }

  Future<void> leerPreferencias() async {
    try {
      _vozActiva = await _store.leerVozActiva() ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Ajustes: $e');
    }
  }

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
    unawaited(leerPreferencias());
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
