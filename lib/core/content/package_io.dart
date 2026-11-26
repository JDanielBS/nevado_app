import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Guarda el paquete de contenido. Siempre cifrado: el texto plano no se escribe en disco.
abstract interface class PackageStore {
  Future<Uint8List?> leer();
  Future<void> guardar(Uint8List paquete);
  Future<void> borrar();
}

/// Archivo en la carpeta privada de la app.
class FilePackageStore implements PackageStore {
  Future<File> _archivo() async => File('${(await getApplicationSupportDirectory()).path}/contenido.nev');

  @override
  Future<Uint8List?> leer() async {
    final archivo = await _archivo();
    return await archivo.exists() ? archivo.readAsBytes() : null;
  }

  @override
  Future<void> guardar(Uint8List paquete) async => (await _archivo()).writeAsBytes(paquete, flush: true);

  @override
  Future<void> borrar() async {
    final archivo = await _archivo();
    if (await archivo.exists()) await archivo.delete();
  }
}

const _maximo = 5 * 1024 * 1024;

/// Descarga el paquete desde la estación.
Future<Uint8List> descargarPaquete(Uri origen) async {
  final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    Future<Uint8List> pedir() async {
      final respuesta = await (await cliente.getUrl(origen)).close();
      if (respuesta.statusCode != HttpStatus.ok) {
        throw HttpException('Respuesta ${respuesta.statusCode}', uri: origen);
      }
      final bytes = BytesBuilder(copy: false);
      await for (final parte in respuesta) {
        bytes.add(parte);
        if (bytes.length > _maximo) throw HttpException('Paquete demasiado grande', uri: origen);
      }
      return bytes.takeBytes();
    }

    return await pedir().timeout(const Duration(seconds: 30));
  } finally {
    cliente.close(force: true);
  }
}
