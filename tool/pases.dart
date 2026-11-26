// Funciones comunes para emitir pases. Las usan generar_pase.dart y servidor_estacion.dart.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:nevado_app/core/access/pass.dart';
import 'package:nevado_app/core/access/public_key.dart';
import 'package:qr/qr.dart';

/// Valor corto para pruebas. Subirlo para el uso en el recorrido.
const minutosPorDefecto = 12;

const rutaPrivada = 'secrets/pase_privada.key';
const rutaPublica = 'lib/core/access/public_key.dart';
const rutaSalida = 'build/pases/pase.svg';

Never salir(String mensaje) {
  stderr.writeln(mensaje);
  exit(1);
}

/// Valor que sigue a [nombre] en la línea de comandos, o `null` si la opción no está.
String? opcion(List<String> argumentos, String nombre) {
  final i = argumentos.indexOf(nombre);
  if (i < 0) return null;
  if (i + 1 >= argumentos.length) salir('Falta el valor de $nombre.');
  return argumentos[i + 1];
}

int numero(List<String> argumentos, String nombre, int porDefecto) {
  final texto = opcion(argumentos, nombre);
  if (texto == null) return porDefecto;
  final valor = int.tryParse(texto);
  if (valor == null || valor <= 0) salir('$nombre necesita un número entero mayor que cero.');
  return valor;
}

Future<SimpleKeyPair> cargarClaves({bool nuevas = false}) async {
  final algoritmo = Ed25519();
  final privada = File(rutaPrivada);
  if (privada.existsSync() && !nuevas) {
    final claves = await algoritmo.newKeyPairFromSeed(base64Url.decode(privada.readAsStringSync().trim()));
    final publica = base64Url.encode((await claves.extractPublicKey()).bytes);
    if (publica != clavePublicaPases) {
      salir(
        'La clave privada no corresponde a la clave pública de la app. '
        'Pide la clave correcta al equipo o usa --nuevas-claves.',
      );
    }
    return claves;
  }
  if (clavePublicaPases.isNotEmpty && !nuevas) {
    salir(
      'La app ya tiene una clave pública, pero falta $rutaPrivada.\n'
      'Pide ese archivo al equipo por un canal privado. Si quieres reemplazar las claves '
      '(invalida los pases y los APK anteriores), usa generar_pase.dart --nuevas-claves.',
    );
  }
  final claves = await algoritmo.newKeyPair();
  privada.parent.createSync(recursive: true);
  privada.writeAsStringSync(base64Url.encode(await claves.extractPrivateKeyBytes()));
  final publica = base64Url.encode((await claves.extractPublicKey()).bytes);
  File(rutaPublica).writeAsStringSync(
    '// Generado por tool/generar_pase.dart: no editar a mano.\n\n'
    '/// Clave pública con la que se verifican los pases. Vacía: ningún pase es válido.\n'
    "const clavePublicaPases = '$publica';\n",
  );
  stdout.writeln('Claves nuevas creadas. Compila la app de nuevo antes de usar los pases.');
  return claves;
}

String dibujarQr(String contenido, String leyenda) {
  final imagen = QrImage(QrCode(payload: QrPayload.fromString(contenido)));
  const margen = 4;
  final lado = imagen.moduleCount + margen * 2;
  final modulos = StringBuffer();
  for (var fila = 0; fila < imagen.moduleCount; fila++) {
    for (var columna = 0; columna < imagen.moduleCount; columna++) {
      if (imagen.isDark(fila, columna)) modulos.write('M${columna + margen} ${fila + margen}h1v1h-1z');
    }
  }
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $lado ${lado + 4}" '
      'width="600" height="${600 * (lado + 4) ~/ lado}">'
      '<rect width="100%" height="100%" fill="#fff"/><path d="$modulos" fill="#000"/>'
      '<text x="${lado / 2}" y="${lado + 1}" font-size="2" text-anchor="middle" '
      'font-family="sans-serif">$leyenda</text></svg>';
}

/// Emite un pase, guarda su QR en [rutaSalida] y lo muestra en la consola.
/// Con [modelo], la app descarga el modelo desde esa dirección al activar el pase.
Future<void> emitirPase(SimpleKeyPair claves, int minutos, {Uri? modelo}) async {
  final emitido = DateTime.now();
  final vence = emitido.add(Duration(minutes: minutos));
  final codigo = await firmarPase(Pase(emitido: emitido, vence: vence, modelo: modelo), claves);

  String hora(DateTime f) => f.toString().substring(0, 16);
  File(rutaSalida)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(dibujarQr(codigo, 'Pase Nevados. Vence ${hora(vence)}'));

  stdout.writeln('Vigencia: $minutos minutos (hasta ${hora(vence)}).');
  if (modelo != null) stdout.writeln('Modelo: $modelo');
  stdout.writeln('QR del pase: ${File(rutaSalida).absolute.path}');
  stdout.writeln('Código: $codigo');
}
