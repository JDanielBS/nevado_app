// Genera un pase de recorrido firmado, como código y como QR.
//
// Uso, desde la raíz del proyecto:
//   dart run tool/generar_pase.dart               vigencia por defecto
//   dart run tool/generar_pase.dart --minutos 720 vigencia de 12 horas
//
// En la estación se usa tool/servidor_estacion.dart, que además reparte la app y el modelo.
//
// La primera vez crea las claves. La privada queda en secrets/ (no se versiona) y la
// pública en lib/core/access/public_key.dart; después de crearlas hay que compilar la app.
import 'pases.dart';

Future<void> main(List<String> argumentos) async {
  final minutos = numero(argumentos, '--minutos', minutosPorDefecto);
  final claves = await cargarClaves(nuevas: argumentos.contains('--nuevas-claves'));
  await emitirPase(claves, minutos);
}
