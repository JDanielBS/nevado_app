// Genera pases de recorrido y reparte el modelo a los teléfonos que lo necesiten.
//
// Uso, desde la raíz del proyecto:
//   dart run tool/generar_pase.dart          pase con descarga del modelo, por la red local
//   dart run tool/generar_pase.dart --usb    igual, por cable USB
//
// El comando queda sirviendo el modelo: Enter emite otro pase y Ctrl+C termina.
//
// Opciones:
//   --minutos 10      vigencia del pase
//   --sin-servidor    solo genera el pase (sin descarga del modelo) y termina
//   --ip, --puerto, --apk, --modelo   ver tool/servidor_estacion.dart
//
// La primera vez crea las claves. La privada queda en secrets/ (no se versiona) y la
// pública en lib/core/access/public_key.dart; después de crearlas hay que compilar la app.
import 'pases.dart';
import 'servidor_estacion.dart' as estacion;

Future<void> main(List<String> argumentos) async {
  final nuevas = argumentos.contains('--nuevas-claves');
  if (!nuevas && !argumentos.contains('--sin-servidor')) return estacion.main(argumentos);
  final minutos = numero(argumentos, '--minutos', minutosPorDefecto);
  final claves = await cargarClaves(nuevas: nuevas);
  await emitirPase(claves, minutos);
}
