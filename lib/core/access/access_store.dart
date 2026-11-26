import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Registro del pase activado en este teléfono.
class PaseGuardado {
  const PaseGuardado({
    required this.codigo,
    required this.ultimaHora,
    required this.emitido,
    required this.vence,
  });

  /// Código completo, que incluye la llave del contenido. `null` una vez vencido: la llave se destruye.
  final String? codigo;

  /// Hora más alta vista desde la activación.
  final DateTime ultimaHora;

  // Se conservan tras el vencimiento para que un pase antiguo no vuelva a servir.
  final DateTime emitido;
  final DateTime vence;
}

abstract interface class AccessStore {
  Future<PaseGuardado?> leer();
  Future<void> guardar(PaseGuardado pase);
}

/// Almacén cifrado con una clave protegida por Android Keystore.
class SecureAccessStore implements AccessStore {
  static const _storage = FlutterSecureStorage();
  static const _clave = 'pase';

  @override
  Future<PaseGuardado?> leer() async {
    try {
      final texto = await _storage.read(key: _clave);
      if (texto == null) return null;
      final datos = jsonDecode(texto) as Map<String, dynamic>;
      DateTime fecha(String campo) => DateTime.fromMillisecondsSinceEpoch(datos[campo] as int);
      return PaseGuardado(
        codigo: datos['codigo'] as String?,
        ultimaHora: fecha('ultimaHora'),
        emitido: fecha('emitido'),
        vence: fecha('vence'),
      );
    } catch (e) {
      // Almacén ilegible (por ejemplo, la clave del sistema cambió): se pide un pase nuevo.
      debugPrint('Pase: no se pudo leer ($e)');
      return null;
    }
  }

  @override
  Future<void> guardar(PaseGuardado pase) => _storage.write(
    key: _clave,
    value: jsonEncode({
      'codigo': pase.codigo,
      'ultimaHora': pase.ultimaHora.millisecondsSinceEpoch,
      'emitido': pase.emitido.millisecondsSinceEpoch,
      'vence': pase.vence.millisecondsSinceEpoch,
    }),
  );
}
