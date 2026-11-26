import 'dart:async';

import 'package:flutter/foundation.dart';

import '../access/access_controller.dart';
import '../access/pass.dart';
import '../search/search.dart';
import 'card.dart';
import 'content_package.dart';
import 'contenido_guia.dart';
import 'fuente_guia.dart';
import 'package_io.dart';
import 'seccion.dart';

enum EstadoContenido { bloqueado, descargando, listo, error }

/// Contenido según el pase: las tarjetas de emergencia siempre; las secciones, solo con un pase vigente.
///
/// El texto descifrado vive únicamente en memoria. Al vencer el pase se descarta y se borra el paquete.
class ContentController extends ChangeNotifier implements FuenteGuia {
  ContentController({
    required this.emergencia,
    required this.store,
    this.descargar = descargarPaquete,
    this.internet,
  });

  @override
  final List<Ficha> emergencia;
  final PackageStore store;
  final Future<Uint8List> Function(Uri) descargar;

  /// Paquete publicado en R2. Se intenta después del teléfono del guía.
  final Uri? internet;

  List<SeccionGuia> _secciones = const [];
  IndiceGuia _indice = IndiceGuia.vacio;
  EstadoContenido _estado = EstadoContenido.bloqueado;
  (EstadoAcceso, Pase?)? _visto;
  Future<void> _cola = Future.value();
  AccessController? _acceso;

  @override
  List<SeccionGuia> get secciones => _secciones;
  @override
  IndiceGuia get indice => _indice;
  EstadoContenido get estado => _estado;

  /// Termina cuando se han aplicado todos los cambios pendientes.
  Future<void> get pendiente => _cola;

  void vincular(AccessController acceso) {
    _acceso = acceso;
    acceso.addListener(_sincronizar);
    _sincronizar();
  }

  /// Descarga el paquete de internet y lo guarda cifrado, aunque todavía no haya pase: así el visitante
  /// lo trae desde casa y en el parque solo necesita escanear el pase. Sin red no hace nada.
  Future<void> predescargar() {
    final origen = internet;
    if (origen == null) return _cola;
    _cola = _cola.then((_) async {
      try {
        final paquete = await descargar(origen);
        esPaqueteDeContenido(paquete);
        // Con un pase vigente, mejor abrir la versión nueva de una vez.
        final acceso = _acceso;
        if (acceso != null && acceso.activo && acceso.pase?.llave != null) {
          final secciones = await _descifrar(paquete, acceso.pase!.llave!);
          await store.guardar(paquete);
          if (acceso.activo) _publicar(secciones, EstadoContenido.listo);
        } else {
          await store.guardar(paquete);
        }
      } catch (e) {
        debugPrint('Contenido: sin descarga previa ($e)');
      }
    });
    return _cola;
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
      case EstadoAcceso.vencido:
        _publicar(null, EstadoContenido.bloqueado);
        await store.borrar();
      case EstadoAcceso.sinPase:
        // Se conserva el paquete descargado antes de la visita: sigue cifrado y sin la llave no se abre.
        _publicar(null, EstadoContenido.bloqueado);
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

    // Primero el teléfono del guía (zona wifi, sin internet) y después R2.
    for (final origen in [?pase.contenido, ?internet]) {
      _publicar(null, EstadoContenido.descargando);
      try {
        final paquete = await descargar(origen);
        final secciones = await _descifrar(paquete, llave);
        if (!vigente()) return;
        await store.guardar(paquete);
        if (vigente()) _publicar(secciones, EstadoContenido.listo);
        return;
      } catch (e) {
        debugPrint('Contenido: no se pudo descargar de $origen ($e)');
      }
    }
    // Sin descarga: se usa el paquete guardado, si la llave del pase lo abre.
    final guardado = await store.leer();
    if (guardado != null) {
      try {
        final secciones = await _descifrar(guardado, llave);
        if (vigente()) _publicar(secciones, EstadoContenido.listo);
        return;
      } catch (e) {
        debugPrint('Contenido: el paquete guardado no corresponde a este pase');
      }
    }
    if (vigente()) _publicar(null, EstadoContenido.error);
  }

  Future<List<SeccionGuia>> _descifrar(Uint8List paquete, List<int> llave) async =>
      ContenidoGuia.decodificar(await descifrarPaquete(paquete, llave)).secciones;

  void _publicar(List<SeccionGuia>? secciones, EstadoContenido estado) {
    if (secciones == null) {
      if (_secciones.isEmpty && _estado == estado) return;
      _secciones = const [];
      _indice = IndiceGuia.vacio;
    } else {
      _secciones = secciones;
      _indice = IndiceGuia.de(secciones);
    }
    _estado = estado;
    notifyListeners();
  }
}
