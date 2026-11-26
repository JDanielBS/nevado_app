enum NivelPrecision { buena, regular, mala }

/// Traduce la precisión del GPS (metros) a algo que una persona entienda.
({String texto, NivelPrecision nivel}) describirPrecision(double? metros) {
  if (metros == null || !metros.isFinite) return (texto: 'Precisión desconocida', nivel: NivelPrecision.mala);
  final redondeado = metros.round();
  if (redondeado <= 20) return (texto: 'Buena (±$redondeado m)', nivel: NivelPrecision.buena);
  if (redondeado <= 100) return (texto: 'Regular (±$redondeado m)', nivel: NivelPrecision.regular);
  return (texto: 'Mala (±$redondeado m)', nivel: NivelPrecision.mala);
}

/// Qué tan vieja es la lectura. Una ubicación vieja puede ya no ser real.
String describirAntiguedad(int marcaTiempoMs, int ahoraMs) {
  final segundos = ((ahoraMs - marcaTiempoMs) / 1000).round().clamp(0, 1 << 31);
  if (segundos < 10) return 'ahora mismo';
  if (segundos < 60) return 'hace $segundos s';
  final minutos = segundos ~/ 60;
  if (minutos < 60) return 'hace $minutos min';
  return 'hace ${minutos ~/ 60} h';
}

String formatearCoordenadas(double latitud, double longitud) {
  final lat = '${latitud.abs().toStringAsFixed(5)}° ${latitud >= 0 ? 'N' : 'S'}';
  final lon = '${longitud.abs().toStringAsFixed(5)}° ${longitud >= 0 ? 'E' : 'O'}';
  return '$lat, $lon';
}
