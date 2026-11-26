import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../access/access_controller.dart';
import '../access/pass.dart';
import 'card.dart';
import 'card_repository.dart';
import 'content_package.dart';
import 'package_io.dart';

enum EstadoContenido { bloqueado, descargando, listo, error }

/// Fichas disponibles según el pase: las de emergencia siempre; las demás solo con un pase vigente.
///
/// El texto descifrado vive únicamente en memoria. Al vencer el pase se descarta y se borra el paquete.
class ContentController extends ChangeNotifier {
  ContentController({required this.emergencia, required this.store, this.descargar = descargarPaquete})
    : _fichas = emergencia;

  final List<Ficha> emergencia;
  final PackageStore store;
  final Future<Uint8List> Function(Uri) descargar;

  List<Ficha> _fichas;
  EstadoContenido _estado = EstadoContenido.bloqueado;
  (EstadoAcceso, Pase?)? _visto;
  Future<void> _cola = Future.value();
  AccessController? _acceso;

  List<Ficha> get fichas => _fichas;
  EstadoContenido get estado => _estado;

  /// Termina cuando se han aplicado todos los cambios pendientes.
  Future<void> get pendiente => _cola;

  void vincular(AccessController acceso) {
    _acceso = acceso;
    acceso.addListener(_sincronizar);
    _sincronizar();
  }

  /// Vuelve a intentar la descarga con el pase actual.
  Future<void> reintentar() {
    _visto = null;
    _sincronizar();
    return _cola;
  }

  void _sincronizar() {
    final acceso = _acceso!;
    final actual = (acceso.estado, acceso.pase);
    // El control de acceso avisa cada segundo: solo interesan los cambios de estado o de pase.
    if (actual == _visto || acceso.estado == EstadoAcceso.comprobando) return;
    _visto = actual;
    // Al dejar de estar activo, el texto se descarta de inmediato, sin esperar a la cola.
    if (!acceso.activo) _publicar(null, EstadoContenido.bloqueado);
    _cola = _cola.then((_) => _aplicar(acceso)).catchError((Object e) {
      debugPrint('Contenido: $e');
      _publicar(null, EstadoContenido.error);
    });
  }

  Future<void> _aplicar(AccessController acceso) async {
    switch (acceso.estado) {
      case EstadoAcceso.vencido || EstadoAcceso.sinPase:
        _publicar(null, EstadoContenido.bloqueado);
        await store.borrar();
      case EstadoAcceso.activo:
        await _abrir(acceso, acceso.pase!);
      case EstadoAcceso.relojAtrasado || EstadoAcceso.comprobando:
        _publicar(null, EstadoContenido.bloqueado);
    }
  }

  Future<void> _abrir(AccessController acceso, Pase pase) async {
    final llave = pase.llave;
    if (llave == null) return _publicar(null, EstadoContenido.bloqueado);
    bool vigente() => acceso.activo && identical(acceso.pase, pase);

    final origen = pase.contenido;
    if (origen != null) {
      _publicar(null, EstadoContenido.descargando);
      try {
        final paquete = await descargar(origen);
        final fichas = await _descifrar(paquete, llave);
        if (!vigente()) return;
        await store.guardar(paquete);
        if (vigente()) _publicar(fichas, EstadoContenido.listo);
        return;
      } catch (e) {
        debugPrint('Contenido: no se pudo descargar ($e)');
      }
    }
    // Sin descarga: se usa el paquete guardado, si la llave del pase lo abre.
    final guardado = await store.leer();
    if (guardado != null) {
      try {
        final fichas = await _descifrar(guardado, llave);
        if (vigente()) _publicar(fichas, EstadoContenido.listo);
        return;
      } catch (e) {
        debugPrint('Contenido: el paquete guardado no corresponde a este pase');
      }
    }
    if (vigente()) _publicar(null, EstadoContenido.error);
  }

  Future<List<Ficha>> _descifrar(Uint8List paquete, List<int> llave) async =>
      fichasDesdeTexto(utf8.decode(await descifrarPaquete(paquete, llave)));

  void _publicar(List<Ficha>? reservadas, EstadoContenido estado) {
    if (reservadas == null) {
      if (identical(_fichas, emergencia) && _estado == estado) return;
      _fichas = emergencia;
    } else {
      final ids = {for (final f in emergencia) f.id};
      _fichas = [...emergencia, ...reservadas.where((f) => !ids.contains(f.id))];
    }
    _estado = estado;
    notifyListeners();
  }
}
