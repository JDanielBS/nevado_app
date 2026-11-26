import 'package:shared_preferences/shared_preferences.dart';

/// Pase activado en este teléfono y la hora más alta vista desde entonces.
class PaseGuardado {
  const PaseGuardado(this.codigo, this.ultimaHora);

  final String codigo;
  final DateTime ultimaHora;
}

abstract interface class AccessStore {
  Future<PaseGuardado?> leer();
  Future<void> guardar(PaseGuardado pase);
}

/// Almacenamiento local del teléfono.
class PreferencesAccessStore implements AccessStore {
  final _preferencias = SharedPreferencesAsync();

  static const _claveCodigo = 'pase.codigo';
  static const _claveHora = 'pase.ultimaHora';

  @override
  Future<PaseGuardado?> leer() async {
    final codigo = await _preferencias.getString(_claveCodigo);
    final hora = await _preferencias.getInt(_claveHora);
    if (codigo == null || hora == null) return null;
    return PaseGuardado(codigo, DateTime.fromMillisecondsSinceEpoch(hora));
  }

  @override
  Future<void> guardar(PaseGuardado pase) async {
    await _preferencias.setString(_claveCodigo, pase.codigo);
    await _preferencias.setInt(_claveHora, pase.ultimaHora.millisecondsSinceEpoch);
  }
}
