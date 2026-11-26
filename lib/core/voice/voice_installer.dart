import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

import 'tts_exceptions.dart';
import 'voice_file.dart';

/// Datos que identifican el paquete de voz esperado.
class PaqueteVoz {
  const PaqueteVoz({required this.carpeta, required this.modelo, required this.bytes, required this.sha256});

  /// Carpeta raíz dentro del paquete.
  final String carpeta;

  /// Archivo del modelo dentro de esa carpeta.
  final String modelo;
  final int bytes;
  final String sha256;
}

const paqueteVozEspanol = PaqueteVoz(carpeta: carpetaVoz, modelo: modeloVoz, bytes: bytesVoz, sha256: sha256Voz);

/// Descarga el paquete de voz desde la estación, lo verifica y lo deja en el teléfono.
class VoiceInstaller {
  VoiceInstaller({required this.base, this.paquete = paqueteVozEspanol});

  /// Carpeta privada de la app donde se guarda la voz.
  final Future<Directory> Function() base;
  final PaqueteVoz paquete;

  /// Marca de instalación completa. Guarda la huella del modelo instalado.
  static const _marca = '.instalada';

  Future<Directory> _destino() async => Directory('${(await base()).path}/${paquete.carpeta}');

  Future<bool> instalada() async {
    final voz = await _destino();
    return await File('${voz.path}/$_marca').exists() && await File('${voz.path}/${paquete.modelo}').exists();
  }

  /// Carpeta de la voz instalada. Si el modelo está dañado la borra y lanza [CorruptVoiceModelException].
  Future<Directory> verificar() async {
    final voz = await _destino();
    if (!await instalada() ||
        await _huella(File('${voz.path}/${paquete.modelo}')) != await File('${voz.path}/$_marca').readAsString()) {
      if (await voz.exists()) await voz.delete(recursive: true);
      throw const CorruptVoiceModelException();
    }
    return voz;
  }

  /// Emite el porcentaje de avance.
  Stream<int> instalar(Uri origen) async* {
    final raiz = await base();
    final temporal = Directory('${raiz.path}/.descarga');
    if (await temporal.exists()) await temporal.delete(recursive: true);
    await temporal.create(recursive: true);
    final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final comprimido = File('${temporal.path}/voz.tar.bz2');
      final respuesta = await (await cliente.getUrl(origen)).close();
      if (respuesta.statusCode != HttpStatus.ok) {
        throw HttpException('La estación respondió ${respuesta.statusCode}', uri: origen);
      }
      final salida = comprimido.openWrite();
      var recibidos = 0;
      var avance = 0;
      yield avance;
      try {
        await for (final parte in respuesta) {
          recibidos += parte.length;
          if (recibidos > paquete.bytes) throw const CorruptVoiceModelException();
          salida.add(parte);
          // La descarga ocupa hasta el 90 %; el resto es descomprimir.
          final nuevo = recibidos * 90 ~/ paquete.bytes;
          if (nuevo > avance) yield avance = nuevo;
        }
      } finally {
        await salida.close();
      }
      if (await _huella(comprimido) != paquete.sha256) throw const CorruptVoiceModelException();

      yield 92;
      await _descomprimir(comprimido.path, temporal.path, paquete.carpeta);
      final nueva = Directory('${temporal.path}/${paquete.carpeta}');
      final modelo = File('${nueva.path}/${paquete.modelo}');
      if (!await modelo.exists()) throw const CorruptVoiceModelException();
      await File('${nueva.path}/$_marca').writeAsString(await _huella(modelo));
      final destino = await _destino();
      if (await destino.exists()) await destino.delete(recursive: true);
      await nueva.rename(destino.path);
      yield 100;
    } finally {
      cliente.close(force: true);
      if (await temporal.exists()) await temporal.delete(recursive: true);
    }
  }

  static Future<String> _huella(File archivo) async => (await sha256.bind(archivo.openRead()).first).toString();

  /// En otro hilo, y pasando por disco para no cargar el paquete entero en memoria.
  static Future<void> _descomprimir(String comprimido, String destino, String carpeta) => Isolate.run(() async {
        final tar = '$destino/voz.tar';
        final entrada = InputFileStream(comprimido);
        final salida = OutputFileStream(tar);
        BZip2Decoder().decodeStream(entrada, salida);
        await entrada.close();
        await salida.close();

        final lector = InputFileStream(tar);
        try {
          for (final archivo in TarDecoder().decodeStream(lector)) {
            final partes = archivo.name.split(RegExp(r'[/\\]'));
            // Nada puede quedar fuera de la carpeta de la voz.
            if (partes.first != carpeta || partes.contains('..') || archivo.isSymbolicLink) {
              throw const CorruptVoiceModelException();
            }
            if (!archivo.isFile) continue;
            final ruta = File('$destino/${archivo.name}');
            await ruta.parent.create(recursive: true);
            final escritura = OutputFileStream(ruta.path);
            archivo.writeContent(escritura);
            await escritura.close();
          }
        } finally {
          await lector.close();
        }
      });
}
