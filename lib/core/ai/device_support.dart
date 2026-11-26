/// Un teléfono "de 4 GB" reporta algo menos de 4 000 000 kB.
// ponytail: umbral fijo, calibrar cuando se prueben más teléfonos.
const minMemTotalKb = 3500000;

/// Motivo de incompatibilidad, o `null` si el equipo puede usar el modelo.
/// [memInfo] es el contenido de `/proc/meminfo`.
String? supportReason({required bool androidArm64, required String memInfo}) {
  if (!androidArm64) {
    return 'El asistente solo funciona en teléfonos Android de 64 bits (arm64).';
  }
  final match = RegExp(r'MemTotal:\s+(\d+) kB').firstMatch(memInfo);
  final total = int.tryParse(match?.group(1) ?? '');
  if (total == null || total < minMemTotalKb) {
    return 'Este teléfono no tiene memoria suficiente para el asistente '
        '(se necesitan 4 GB de RAM).';
  }
  return null;
}
