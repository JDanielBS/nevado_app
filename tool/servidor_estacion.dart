// Estación de instalación: reparte la app y el modelo por la red local y emite los pases.
//
// Uso, desde la raíz del proyecto:
//   dart run tool/servidor_estacion.dart
//
// Opciones:
//   --ip 192.168.1.20   dirección de este computador (por defecto se detecta)
//   --puerto 8000
//   --minutos 12        vigencia de los pases
//   --apk RUTA          por defecto build/app/outputs/flutter-apk/app-release.apk
//   --modelo RUTA       por defecto estacion/<archivo del modelo>
//
// El pase no se publica en la red: el personal muestra el QR desde este computador.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:nevado_app/core/ai/model_file.dart';

import 'estacion.dart';
import 'pases.dart';

Future<String> detectarIp() async {
  final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
  final privadas = [
    for (final i in interfaces)
      // Se omiten las redes virtuales (contenedores, máquinas virtuales, VPN).
      if (!RegExp(r'^(docker|br-|veth|virbr|vbox|vmnet|tun|tailscale|vEthernet)').hasMatch(i.name))
        for (final d in i.addresses)
          if (RegExp(r'^(192\.168\.|10\.|172\.(1[6-9]|2\d|3[01])\.)').hasMatch(d.address))
            (i.name, d.address),
  ];
  if (privadas.length == 1) return privadas.single.$2;
  salir(
    privadas.isEmpty
        ? 'No se encontró una red local. Conéctate al wifi de la estación o indica --ip.'
        : 'Hay varias redes; indica una con --ip:\n${privadas.map((p) => '  ${p.$2}  (${p.$1})').join('\n')}',
  );
}

Future<void> main(List<String> argumentos) async {
  final puerto = numero(argumentos, '--puerto', 8000);
  final minutos = numero(argumentos, '--minutos', minutosPorDefecto);
  final apk = File(opcion(argumentos, '--apk') ?? 'build/app/outputs/flutter-apk/app-release.apk');
  final modelo = File(opcion(argumentos, '--modelo') ?? 'estacion/$nombreModelo');

  if (!apk.existsSync()) salir('No existe el APK en ${apk.path}. Compílalo (ver COMANDOS.md).');
  if (!modelo.existsSync()) salir('No existe el modelo en ${modelo.path}. Descárgalo (ver COMANDOS.md).');

  stdout.writeln('Comprobando el modelo...');
  final huella = (await sha256.bind(modelo.openRead()).first).toString();
  if (huella != sha256Modelo) salir('El archivo del modelo está incompleto o no es el esperado.');

  final claves = await cargarClaves();
  final base = Uri.parse('http://${opcion(argumentos, '--ip') ?? await detectarIp()}:$puerto/');
  final descargas = {'/nevados.apk': apk, '/$nombreModelo': modelo};
  await iniciarServidor(descargas, puerto: puerto, registro: stdout.writeln);

  const rutaInstalar = 'build/pases/instalar.svg';
  File(rutaInstalar)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(dibujarQr('$base', 'Instalar Nevados'));
  stdout.writeln('\nServidor listo en $base');
  stdout.writeln('1) QR para instalar la app: ${File(rutaInstalar).absolute.path}');
  stdout.writeln('2) QR del pase:');
  await emitirPase(claves, minutos, modelo: base.resolve(nombreModelo));
  stdout.writeln('\nEnter: emitir un pase nuevo. Ctrl+C: salir.');

  await for (final _ in stdin) {
    await emitirPase(claves, minutos, modelo: base.resolve(nombreModelo));
  }
}
