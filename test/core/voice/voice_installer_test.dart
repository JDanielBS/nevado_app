import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/voice/tts_exceptions.dart';
import 'package:nevado_app/core/voice/voice_installer.dart';

import '../../../tool/estacion.dart';

/// Paquete de voz de mentira con la misma forma que el real.
List<int> paquete(Map<String, String> archivos) {
  final archive = Archive();
  archivos.forEach((nombre, texto) => archive.addFile(ArchiveFile.bytes(nombre, utf8.encode(texto))));
  return BZip2Encoder().encodeBytes(TarEncoder().encodeBytes(archive));
}

const contenido = {
  'voz/modelo.onnx': 'pesos',
  'voz/tokens.txt': 'a 1',
  'voz/espeak-ng-data/es_dict': 'dict',
};

void main() {
  late Directory carpeta;
  HttpServer? servidor;

  setUp(() => carpeta = Directory.systemTemp.createTempSync('voz'));
  tearDown(() async {
    await servidor?.close(force: true);
    carpeta.deleteSync(recursive: true);
  });

  Future<Uri> publicar(List<int> bytes) async {
    final archivo = File('${carpeta.path}/publicado.tar.bz2')..writeAsBytesSync(bytes);
    servidor = await iniciarServidor({'/voz.tar.bz2': archivo}, puerto: 0);
    return Uri.parse('http://127.0.0.1:${servidor!.port}/voz.tar.bz2');
  }

  VoiceInstaller instalador(List<int> esperado) => VoiceInstaller(
        base: () async => Directory('${carpeta.path}/telefono'),
        paquete: PaqueteVoz(
          carpeta: 'voz',
          modelo: 'modelo.onnx',
          bytes: esperado.length,
          sha256: sha256.convert(esperado).toString(),
        ),
      );

  test('descarga de la estación, descomprime y queda instalada', () async {
    final bytes = paquete(contenido);
    final installer = instalador(bytes);
    expect(await installer.instalada(), isFalse);

    final avance = await installer.instalar(await publicar(bytes)).toList();

    expect(avance.last, 100);
    expect(avance, orderedEquals([...avance]..sort()));
    expect(await installer.instalada(), isTrue);
    final voz = await installer.verificar();
    expect(File('${voz.path}/espeak-ng-data/es_dict').readAsStringSync(), 'dict');
    // El paquete comprimido no se conserva.
    expect(Directory('${carpeta.path}/telefono').listSync(recursive: true).where((f) => f.path.contains('.tar')), isEmpty);
  });

  test('rechaza un paquete que no es el esperado', () async {
    final installer = instalador(paquete(contenido));
    final otro = await publicar(paquete({...contenido, 'voz/modelo.onnx': 'otros pesos'}));
    await expectLater(installer.instalar(otro).drain<void>(), throwsA(isA<CorruptVoiceModelException>()));
    expect(await installer.instalada(), isFalse);
  });

  test('no escribe fuera de su carpeta', () async {
    final bytes = paquete({...contenido, 'voz/../../fuera.txt': 'x'});
    final installer = instalador(bytes);
    await expectLater(
        installer.instalar(await publicar(bytes)).drain<void>(), throwsA(isA<CorruptVoiceModelException>()));
    expect(File('${carpeta.path}/fuera.txt').existsSync(), isFalse);
    expect(await installer.instalada(), isFalse);
  });

  test('un archivo que la estación no tiene falla sin dejar nada a medias', () async {
    final bytes = paquete(contenido);
    final url = await publicar(bytes);
    final installer = instalador(bytes);
    await expectLater(installer.instalar(url.resolve('otro')).drain<void>(), throwsA(isA<HttpException>()));
    expect(await installer.instalada(), isFalse);
  });

  test('un modelo dañado después de instalar se borra', () async {
    final bytes = paquete(contenido);
    final installer = instalador(bytes);
    await installer.instalar(await publicar(bytes)).drain<void>();
    File('${(await installer.verificar()).path}/modelo.onnx').writeAsStringSync('roto');
    await expectLater(installer.verificar(), throwsA(isA<CorruptVoiceModelException>()));
    expect(await installer.instalada(), isFalse);
  });
}
