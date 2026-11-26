import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/access/pass.dart';
import 'package:nevado_app/core/ai/model_file.dart';
import 'package:nevado_app/features/chat/chat_controller.dart';

import '../tool/estacion.dart';
import 'chat_test.dart' show FakeEngine;

final origen = Uri.parse('http://192.168.1.20:8000/$nombreModelo');

void main() {
  test('los datos del modelo coinciden con el catálogo del paquete', () {
    final file = LiteRtLmModels.gemma3_1bIt.q4Ekv4096.file;
    expect(nombreModelo, file.installFilename);
    expect(bytesModelo, file.sizeBytes);
    expect(sha256Modelo, file.sha256);
  });

  test('el pase lleva firmada la dirección del modelo', () async {
    final claves = await Ed25519().newKeyPair();
    final publica = base64Url.encode((await claves.extractPublicKey()).bytes);
    final ahora = DateTime(2026, 11, 26, 8);
    final codigo = await firmarPase(
      Pase(emitido: ahora, vence: ahora.add(const Duration(hours: 1)), modelo: origen),
      claves,
    );
    expect((await leerPase(codigo, publica))?.modelo, origen);
  });

  group('descarga al activar', () {
    test('descarga desde la estación, verifica y libera la memoria', () async {
      final engine = FakeEngine(canDownload: false);
      final chat = ChatController(engine);
      final done = chat.provision(origen);
      await pumpEventQueue();
      engine.progress.add(50);
      await pumpEventQueue();
      expect(chat.phase, ChatPhase.downloading);
      expect(chat.progress, 50);
      unawaited(engine.progress.close());
      await done;
      expect(engine.origen, origen);
      expect(chat.instalado, isTrue);
      expect(engine.unloads, 1);
    });

    test('si ya está instalado no descarga ni carga', () async {
      final engine = FakeEngine(installed: true);
      final chat = ChatController(engine);
      await chat.provision(origen);
      expect(engine.installs, 0);
      expect(engine.loads, 0);
      expect(chat.instalado, isTrue);
    });

    test('un fallo de red permite reintentar', () async {
      final engine = FakeEngine()..failInstall = true;
      final chat = ChatController(engine);
      await chat.provision(origen);
      expect(chat.phase, ChatPhase.noModel);
      expect(chat.error, isNotNull);
      engine.failInstall = false;
      unawaited(engine.progress.close());
      await chat.provision(origen);
      expect(chat.instalado, isTrue);
    });

    test('un teléfono no compatible no descarga', () async {
      final engine = FakeEngine(reason: 'poca memoria');
      final chat = ChatController(engine);
      await chat.provision(origen);
      expect(engine.installs, 0);
      expect(chat.phase, ChatPhase.unsupported);
    });
  });

  group('servidor de la estación', () {
    late Directory carpeta;
    late HttpServer servidor;
    late HttpClient cliente;

    setUp(() async {
      carpeta = Directory.systemTemp.createTempSync('estacion');
      final modelo = File('${carpeta.path}/modelo')..writeAsStringSync('0123456789');
      File('${carpeta.path}/secreto').writeAsStringSync('no');
      servidor = await iniciarServidor({'/modelo': modelo}, puerto: 0);
      cliente = HttpClient();
    });

    tearDown(() async {
      cliente.close(force: true);
      await servidor.close(force: true);
      carpeta.deleteSync(recursive: true);
    });

    Future<(int, String)> pedir(String ruta, {String? rango}) async {
      final peticion = await cliente.get('127.0.0.1', servidor.port, ruta);
      if (rango != null) peticion.headers.set(HttpHeaders.rangeHeader, rango);
      final respuesta = await peticion.close();
      return (respuesta.statusCode, await respuesta.transform(utf8.decoder).join());
    }

    test('entrega la página y el archivo, y reanuda descargas', () async {
      expect((await pedir('/')).$2, contains('Descargar la aplicación'));
      expect(await pedir('/modelo'), (200, '0123456789'));
      expect(await pedir('/modelo', rango: 'bytes=6-'), (206, '6789'));
      expect((await pedir('/modelo', rango: 'bytes=20-')).$1, 416);
    });

    test('no entrega ningún otro archivo', () async {
      for (final ruta in ['/secreto', '/../secreto', '/%2e%2e/secrets/pase_privada.key']) {
        expect((await pedir(ruta)).$1, 404, reason: ruta);
      }
    });
  });
}
