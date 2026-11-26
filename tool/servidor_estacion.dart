// Estación de instalación: reparte la app y el modelo y emite los pases.
// Normalmente se ejecuta mediante `dart run tool/generar_pase.dart`, que acepta las mismas opciones.
//
// Opciones:
//   --usb                entrega por cable USB (requiere el teléfono conectado con depuración USB)
//   --ip 192.168.1.20    dirección de este computador (por defecto se detecta)
//   --puerto 8000
//   --minutos 10         vigencia de los pases
//   --apk RUTA           por defecto build/app/outputs/flutter-apk/app-visitante-release.apk
//   --modelo RUTA        por defecto estacion/<archivo del modelo>
//   --contenido CARPETA  secciones .md a cifrar; por defecto contenido/secciones
//
// El pase no se publica en la red: el personal muestra el QR desde este computador.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:nevado_app/core/ai/model_file.dart';
import 'package:nevado_app/core/content/card.dart' show rutaSecciones;

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

/// Redirige el puerto del teléfono a este computador a través del cable USB.
Future<void> abrirPuenteUsb(int puerto) async {
  final casa = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  final sdk =
      Platform.environment['ANDROID_HOME'] ??
      (Platform.isWindows ? '$casa/AppData/Local/Android/Sdk' : '$casa/Android/Sdk');
  final instalado = File('$sdk/platform-tools/adb${Platform.isWindows ? '.exe' : ''}');
  final adb = instalado.existsSync() ? instalado.path : 'adb';
  try {
    final resultado = await Process.run(adb, ['reverse', 'tcp:$puerto', 'tcp:$puerto']);
    if (resultado.exitCode != 0) salir('No se pudo abrir el puente USB: ${resultado.stderr}');
  } on ProcessException {
    salir('No se encontró adb. Instala las herramientas de plataforma de Android.');
  }
}

Future<void> main(List<String> argumentos) async {
  final puerto = numero(argumentos, '--puerto', 8000);
  final minutos = numero(argumentos, '--minutos', minutosPorDefecto);
  final apk = File(opcion(argumentos, '--apk') ?? 'build/app/outputs/flutter-apk/app-visitante-release.apk');
  final modelo = File(opcion(argumentos, '--modelo') ?? 'estacion/$nombreModelo');

  final fichas = Directory(opcion(argumentos, '--contenido') ?? rutaSecciones);
  if (!fichas.existsSync()) salir('No existe la carpeta de secciones ${fichas.path}.');
  final paquete = File('build/estacion/contenido.nev');

  if (!modelo.existsSync()) {
    salir(
      'No existe el modelo en ${modelo.path}. Descárgalo (ver COMANDOS.md) o genera un pase sin '
      'descarga con: dart run tool/generar_pase.dart --sin-servidor',
    );
  }

  stdout.writeln('Comprobando el modelo...');
  final huella = (await sha256.bind(modelo.openRead()).first).toString();
  if (huella != sha256Modelo) salir('El archivo del modelo está incompleto o no es el esperado.');

  final claves = await cargarClaves();
  final usb = argumentos.contains('--usb');
  final ip = usb ? '127.0.0.1' : opcion(argumentos, '--ip') ?? await detectarIp();
  final base = Uri.parse('http://$ip:$puerto/');
  final descargas = {
    if (apk.existsSync()) '/nevados.apk': apk,
    '/$nombreModelo': modelo,
    '/contenido.nev': paquete,
  };
  try {
    await iniciarServidor(descargas, puerto: puerto, registro: stdout.writeln);
  } on SocketException {
    salir('El puerto $puerto está ocupado. Cierra el otro servidor o usa --puerto.');
  }
  if (usb) await abrirPuenteUsb(puerto);

  stdout.writeln('\nServidor listo en $base');
  if (apk.existsSync()) {
    const rutaInstalar = 'build/pases/instalar.svg';
    File(rutaInstalar)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(dibujarQr('$base', 'Instalar Nevados'));
    stdout.writeln('1) QR para instalar la app: ${File(rutaInstalar).absolute.path}');
  } else {
    stdout.writeln('Sin APK en ${apk.path}: no se ofrece la instalación, solo el modelo.');
  }
  stdout.writeln('2) QR del pase:');
  // Las secciones se cifran de nuevo con cada pase: así los cambios se publican sin reiniciar.
  Future<void> emitir() async {
    final llave = llaveDeLaJornada();
    try {
      await crearPaquete(fichas, paquete, llave);
    } catch (e) {
      stderr.writeln('No se pudo preparar el contenido de ${fichas.path}: $e');
      return;
    }
    await emitirPase(
      claves,
      minutos,
      modelo: base.resolve(nombreModelo),
      contenido: base.resolve('contenido.nev'),
      llave: llave,
    );
  }

  await emitir();
  stdout.writeln('\nEnter: emitir un pase nuevo. Ctrl+C: salir.');

  await for (final _ in stdin) {
    await emitir();
  }
}
