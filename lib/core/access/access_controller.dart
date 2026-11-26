import 'dart:async';

import 'package:flutter/widgets.dart';

import 'access_store.dart';
import 'pass.dart';

enum EstadoAcceso {
  /// Todavía se está leyendo el pase guardado.
  comprobando,
  sinPase,
  activo,
  vencido,

  /// El reloj del teléfono retrocedió respecto a la última hora vista.
  relojAtrasado,
}

enum ResultadoPase { aceptado, invalido, vencido, relojDesajustado }

/// Retroceso de reloj que se tolera (ajustes automáticos de hora).
const toleranciaRetroceso = Duration(minutes: 1);

/// Diferencia tolerada entre el reloj del equipo que emite el pase y el del teléfono.
const toleranciaEmision = Duration(minutes: 2);

/// Cada cuánto se guarda la hora mientras el estado no cambia.
const intervaloGuardado = Duration(seconds: 5);

/// Decide si la app está habilitada. No usa internet.
class AccessController extends ChangeNotifier with WidgetsBindingObserver {
  AccessController({
    required this.store,
    required this.clavePublica,
    DateTime Function()? reloj,
    Duration Function()? cronometro,
  }) : _reloj = reloj ?? DateTime.now,
       _cronometro = cronometro ?? _cronometroDelProceso();

  final AccessStore store;
  final String clavePublica;
  final DateTime Function() _reloj;

  /// Tiempo transcurrido que no cambia aunque se modifique la hora del teléfono.
  final Duration Function() _cronometro;

  static Duration Function() _cronometroDelProceso() {
    final cronometro = Stopwatch()..start();
    return () => cronometro.elapsed;
  }

  EstadoAcceso _estado = EstadoAcceso.comprobando;
  Pase? _pase;
  String? _codigo;
  Duration? _ultimoGuardado;
  DateTime? _ultimaHora;
  Duration _ultimaMarca = Duration.zero;
  Duration _restante = Duration.zero;
  Timer? _temporizador;

  EstadoAcceso get estado => _estado;
  bool get activo => _estado == EstadoAcceso.activo;

  /// Último pase aceptado, aunque ya haya vencido.
  Pase? get pase => _pase;

  /// Tiempo que le queda al pase. Cero si no está activo.
  Duration get restante => _restante;

  /// Carga el pase guardado y empieza a vigilar el vencimiento.
  Future<void> iniciar({Duration intervalo = const Duration(seconds: 1)}) async {
    final guardado = await store.leer();
    if (guardado != null) {
      _codigo = guardado.codigo;
      _pase = await leerPase(guardado.codigo, clavePublica);
      _ultimaHora = guardado.ultimaHora;
      _ultimaMarca = _cronometro();
    }
    await comprobar();
    WidgetsBinding.instance.addObserver(this);
    _temporizador = Timer.periodic(intervalo, (_) => comprobar());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => unawaited(comprobar());

  /// Reevalúa el estado con la hora actual y guarda la hora más alta vista.
  Future<void> comprobar() async {
    final pase = _pase;
    if (pase == null) return _publicar(EstadoAcceso.sinPase, Duration.zero);

    final ahora = _reloj();
    final marca = _cronometro();
    final anterior = _ultimaHora;
    var efectiva = ahora;
    var atrasado = false;
    if (anterior != null) {
      atrasado = ahora.isBefore(anterior.subtract(toleranciaRetroceso));
      // El tiempo avanza como mínimo lo que marca el cronómetro, aunque se atrase la hora.
      final minima = anterior.add(marca - _ultimaMarca);
      if (minima.isAfter(efectiva)) efectiva = minima;
    }
    _ultimaHora = efectiva;
    _ultimaMarca = marca;

    final restante = pase.vence.difference(efectiva);
    final EstadoAcceso estado;
    if (restante <= Duration.zero) {
      estado = EstadoAcceso.vencido;
    } else if (atrasado) {
      estado = EstadoAcceso.relojAtrasado;
    } else {
      estado = EstadoAcceso.activo;
    }
    final cambio = estado != _estado;
    _publicar(estado, estado == EstadoAcceso.activo ? restante : Duration.zero);

    final guardado = _ultimoGuardado;
    if (cambio || guardado == null || marca - guardado >= intervaloGuardado) await _guardar(efectiva);
  }

  Future<void> _guardar(DateTime hora) async {
    final codigo = _codigo;
    if (codigo == null) return;
    _ultimoGuardado = _cronometro();
    await store.guardar(PaseGuardado(codigo, hora));
  }

  /// Valida un código escaneado y, si sirve, habilita la app.
  Future<ResultadoPase> activar(String codigo) async {
    final nuevo = await leerPase(codigo, clavePublica);
    if (nuevo == null) return ResultadoPase.invalido;

    final ahora = _reloj();
    if (ahora.isBefore(nuevo.emitido.subtract(toleranciaEmision))) {
      return ResultadoPase.relojDesajustado;
    }
    if (!ahora.isBefore(nuevo.vence)) return ResultadoPase.vencido;

    // Un pase emitido después del anterior demuestra que el personal lo autorizó:
    // solo en ese caso se reinicia la hora guardada.
    final anterior = _pase;
    final esMasReciente = anterior == null || nuevo.emitido.isAfter(anterior.emitido);
    final ultima = _ultimaHora;
    if (!esMasReciente && ultima != null) {
      if (!ultima.isBefore(nuevo.vence)) return ResultadoPase.vencido;
      if (ahora.isBefore(ultima.subtract(toleranciaRetroceso))) return ResultadoPase.relojDesajustado;
    } else {
      _ultimaHora = null;
    }

    _pase = nuevo;
    _codigo = codigo.trim();
    _ultimaMarca = _cronometro();
    await _guardar(_ultimaHora ?? ahora);
    await comprobar();
    return ResultadoPase.aceptado;
  }

  void _publicar(EstadoAcceso estado, Duration restante) {
    // Se avisa al cambiar el estado o el segundo mostrado en pantalla.
    final cambio = estado != _estado || restante.inSeconds != _restante.inSeconds;
    _estado = estado;
    _restante = restante;
    if (cambio) notifyListeners();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
