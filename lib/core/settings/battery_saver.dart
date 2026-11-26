/// Por debajo de este nivel (0 a 1) se activa el modo ahorro automáticamente.
const umbralBateriaBaja = 0.2;

enum MotivoAhorro { manual, bateriaBaja, ahorroSistema }

const Map<MotivoAhorro, String> textoMotivo = {
  MotivoAhorro.manual: 'Lo activaste tú en Ajustes.',
  MotivoAhorro.bateriaBaja: 'Batería baja.',
  MotivoAhorro.ahorroSistema: 'Tu teléfono está en ahorro de energía.',
};

/// Decide si el modo ahorro está activo.
/// [nivel] va de 0 a 1; un valor negativo o null significa "no disponible".
({bool activo, MotivoAhorro? motivo}) calcularAhorro({
  required double? nivel,
  required bool ahorroSistema,
  required bool manual,
}) {
  if (manual) return (activo: true, motivo: MotivoAhorro.manual);
  if (nivel != null && nivel >= 0 && nivel <= umbralBateriaBaja) {
    return (activo: true, motivo: MotivoAhorro.bateriaBaja);
  }
  if (ahorroSistema) return (activo: true, motivo: MotivoAhorro.ahorroSistema);
  return (activo: false, motivo: null);
}

String porcentaje(double? nivel) => nivel == null || nivel < 0 ? 'no disponible' : '${(nivel * 100).round()} %';
