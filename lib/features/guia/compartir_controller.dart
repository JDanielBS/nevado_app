import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

import '../../core/access/pass.dart';
import '../../core/ai/model_file.dart';
import '../../core/station/servidor.dart';
import 'guia_contenido.dart';

/// Duración del pase que emite el guía. Corta para poder probar; subirla para el uso en el recorrido.
const minutosPase = 10;

const puertoGuia = 8000;

/// Una dirección local de este teléfono y la interfaz a la que pertenece.
typedef RedLocal = ({String interfaz, String ip});

/// Interfaces que no sirven para compartir: datos móviles, VPN y redes virtuales.
final _descartadas = RegExp(r'^(rmnet|ccmni|tun|ppp|dummy|lo|docker|veth|br-|virbr|vbox|vmnet|tailscale)');

/// Direcciones privadas por las que los visitantes pueden llegar. La zona wifi suele ser la única.
Future<List<RedLocal>> redesLocales() async {
  final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  return [
    for (final i in interfaces)
      if (!_descartadas.hasMatch(i.name))
        for (final d in i.addresses)
          if (RegExp(r'^(192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(d.address))
            (interfaz: i.name, ip: d.address),
  ];
}

/// Comparte la app, el modelo y el contenido por la zona wifi del guía y emite los pases. Sin internet.
class CompartirController extends ChangeNotifier {
  CompartirController({
    required this.contenido,
    required this.carpetaTrabajo,
    required this.clavePrivada,
    required this.llave,
    required this.buscarModelo,
    required this.buscarApk,
    this.buscarRedes = redesLocales,
  });

  final GuiaContenido contenido;

  /// Donde se escribe el paquete cifrado que se entrega.
  final Directory carpetaTrabajo;

  /// Semilla Ed25519 en base64url. Vacía si la app se compiló sin `secrets/guia.env`.
  final String clavePrivada;

  /// Llave del contenido. La misma del paquete publicado en R2.
  final List<int>? llave;
  final Future<File?> Function() buscarModelo;
  final Future<File?> Function() buscarApk;
  final Future<List<RedLocal>> Function() buscarRedes;

  HttpServer? _servidor;
  List<RedLocal> redes = const [];
  String? ip;
  String? codigoPase;
  DateTime? vence;
  String? error;
  bool hayModelo = false;
  bool hayApk = false;
  bool ocupado = false;

  bool get encendido => _servidor != null;
  bool get configurado => clavePrivada.isNotEmpty && llave != null;
  Uri? get base => ip == null ? null : Uri.parse('http://$ip:${_servidor?.port ?? puertoGuia}/');

  final _registro = <String>[];

  /// Últimas descargas atendidas, de la más reciente a la más antigua.
  List<String> get registro => List.unmodifiable(_registro.reversed);

  File get _paquete => File('${carpetaTrabajo.path}/contenido.nev');

  Future<void> actualizarRedes() async {
    redes = await buscarRedes();
    if (ip == null || !redes.any((r) => r.ip == ip)) ip = redes.length == 1 ? redes.single.ip : null;
    notifyListeners();
  }

  void elegirRed(String nueva) {
    ip = nueva;
    // El pase lleva la dirección: uno emitido con otra red ya no sirve.
    codigoPase = null;
    notifyListeners();
  }

  Future<void> encender({int puerto = puertoGuia}) async {
    if (encendido || ocupado) return;
    ocupado = true;
    error = null;
    notifyListeners();
    try {
      if (!configurado) throw StateError('La app se compiló sin las claves del guía (secrets/guia.env).');
      await _prepararPaquete();
      final modelo = await buscarModelo();
      final apk = await buscarApk();
      hayModelo = modelo != null;
      hayApk = apk != null;
      _servidor = await iniciarServidor(
        {'/contenido.nev': _paquete, '/$nombreModelo': ?modelo, '/nevados.apk': ?apk},
        puerto: puerto,
        registro: (linea) {
          _registro.add(linea);
          if (_registro.length > 20) _registro.removeAt(0);
          notifyListeners();
        },
      );
      await actualizarRedes();
      if (ip != null) await emitirPase();
    } on SocketException catch (e) {
      error = 'No se pudo abrir el puerto $puerto ($e).';
    } catch (e) {
      error = '$e';
    } finally {
      ocupado = false;
      notifyListeners();
    }
  }

  Future<void> apagar() async {
    await _servidor?.close(force: true);
    _servidor = null;
    codigoPase = null;
    notifyListeners();
  }

  /// Escribe el paquete cifrado con el contenido actual. Se rehace con cada pase, para entregar los cambios.
  Future<void> _prepararPaquete() async {
    carpetaTrabajo.createSync(recursive: true);
    final temporal = File('${_paquete.path}.tmp')..writeAsBytesSync(await contenido.paqueteCifrado(llave!));
    temporal.renameSync(_paquete.path);
  }

  /// Emite un pase de [minutos] con la dirección de este teléfono en la red elegida.
  Future<void> emitirPase({int minutos = minutosPase, DateTime? ahora}) async {
    final direccion = base;
    if (!encendido || direccion == null) return;
    await _prepararPaquete();
    final emitido = ahora ?? DateTime.now();
    final claves = await Ed25519().newKeyPairFromSeed(base64Url.decode(base64Url.normalize(clavePrivada)));
    vence = emitido.add(Duration(minutes: minutos));
    codigoPase = await firmarPase(
      Pase(
        emitido: emitido,
        vence: vence!,
        modelo: hayModelo ? direccion.resolve(nombreModelo) : null,
        contenido: direccion.resolve('contenido.nev'),
        llave: llave,
      ),
      claves,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _servidor?.close(force: true);
    super.dispose();
  }
}
