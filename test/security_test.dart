import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/access/access_controller.dart';
import 'package:nevado_app/core/access/pass.dart';
import 'package:nevado_app/core/content/card.dart';
import 'package:nevado_app/core/content/card_repository.dart';
import 'package:nevado_app/core/content/carpeta_contenido.dart';
import 'package:nevado_app/core/content/contenido_guia.dart';
import 'package:nevado_app/core/content/content_controller.dart';
import 'package:nevado_app/core/content/content_package.dart';
import 'package:nevado_app/core/content/package_io.dart';
import 'package:nevado_app/features/chat/chat_controller.dart';

import '../tool/pases.dart' show crearPaquete, llaveDeLaJornada;
import 'access_test.dart' show MemoryStore;
import 'chat_test.dart' show FakeEngine;

class MemoryPackageStore implements PackageStore {
  Uint8List? paquete;

  @override
  Future<Uint8List?> leer() async => paquete;

  @override
  Future<void> guardar(Uint8List nuevo) async => paquete = nuevo;

  @override
  Future<void> borrar() async => paquete = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final llave = List<int>.generate(bytesLlave, (i) => i);
  final otraLlave = List<int>.filled(bytesLlave, 7);
  final completas = utf8.decode(leerCarpeta(Directory(rutaSecciones)).codificar());
  final emergencia = fichasDesdeTexto(File(rutaEmergencia).readAsStringSync());

  test('la app solo incluye fichas de emergencia en texto plano', () {
    expect(emergencia, isNotEmpty);
    expect(emergencia.every((f) => f.categoria == Categoria.emergencia), isTrue);
    final incluidos = Directory('assets/content').listSync().map((f) => f.uri.pathSegments.last);
    expect(incluidos.where((n) => n != '.gitkeep'), ['emergencia.json']);
  });

  group('paquete cifrado', () {
    test('no deja texto legible y solo abre con su llave', () async {
      final paquete = await cifrarPaquete(utf8.encode(completas), llave);
      expect(latin1.decode(paquete), isNot(contains('Espeletia')));
      expect(utf8.decode(await descifrarPaquete(paquete, llave)), completas);
      await expectLater(descifrarPaquete(paquete, otraLlave), throwsA(isA<Object>()));
    });

    test('rechaza un paquete alterado o mal formado', () async {
      final paquete = await cifrarPaquete(utf8.encode(completas), llave);
      paquete[paquete.length ~/ 2] ^= 1;
      await expectLater(descifrarPaquete(paquete, llave), throwsA(isA<Object>()));
      await expectLater(descifrarPaquete([1, 2, 3], llave), throwsFormatException);
    });

    test('la llave cambia cada jornada y se conserva durante el día', () {
      final carpeta = Directory.systemTemp.createTempSync('llaves');
      addTearDown(() => carpeta.deleteSync(recursive: true));
      List<int> de(DateTime d) => llaveDeLaJornada(ahora: d, carpeta: carpeta.path);
      final hoy = de(DateTime(2026, 11, 26, 8));
      expect(hoy, hasLength(bytesLlave));
      expect(de(DateTime(2026, 11, 26, 18)), hoy);
      expect(de(DateTime(2026, 11, 27)), isNot(hoy));
    });

    test('la estación genera un paquete que la app puede abrir', () async {
      final carpeta = Directory.systemTemp.createTempSync('paquete');
      addTearDown(() => carpeta.deleteSync(recursive: true));
      final destino = File('${carpeta.path}/contenido.nev');
      await crearPaquete(Directory(rutaSecciones), destino, llave);
      final abierto = ContenidoGuia.decodificar(await descifrarPaquete(destino.readAsBytesSync(), llave));
      expect(abierto.archivos, ContenidoGuia.decodificar(utf8.encode(completas)).archivos);
      expect(abierto.publicado, isNotNull);
    });
  });

  group('contenido según el pase', () {
    late SimpleKeyPair claves;
    late AccessController access;
    late MemoryStore registro;
    late MemoryPackageStore paquetes;
    late ContentController content;
    late Uint8List remoto;
    late DateTime hora;
    var descargas = 0;
    var sinRed = false;

    AccessController crearAcceso(String publica) => AccessController(
      store: registro,
      clavePublica: publica,
      reloj: () => hora,
      cronometro: () => Duration.zero,
    );

    ContentController crearContenido() => ContentController(
      emergencia: emergencia,
      store: paquetes,
      descargar: (_) async {
        descargas++;
        if (sinRed) throw const SocketException('sin red');
        return remoto;
      },
    );

    late String publica;

    setUp(() async {
      claves = await Ed25519().newKeyPair();
      publica = base64Url.encode((await claves.extractPublicKey()).bytes);
      registro = MemoryStore();
      paquetes = MemoryPackageStore();
      remoto = await cifrarPaquete(utf8.encode(completas), llave);
      hora = DateTime(2026, 11, 26, 8);
      descargas = 0;
      sinRed = false;
      access = crearAcceso(publica);
      content = crearContenido()..vincular(access);
    });

    Future<String> pase({List<int>? con}) => firmarPase(
      Pase(
        emitido: hora,
        vence: hora.add(const Duration(minutes: 10)),
        contenido: Uri.parse('http://192.168.1.20:8000/contenido.nev'),
        llave: con ?? llave,
      ),
      claves,
    );

    Future<void> vencer() async {
      hora = hora.add(const Duration(minutes: 11));
      await access.comprobar();
      await content.pendiente;
    }

    test('sin pase solo hay emergencias', () async {
      await access.comprobar();
      await content.pendiente;
      expect(content.secciones, isEmpty);
    });

    test('con pase descarga, descifra y guarda solo el paquete cifrado', () async {
      await access.activar(await pase());
      await content.pendiente;
      expect(content.estado, EstadoContenido.listo);
      expect(content.secciones, hasLength(10));
      expect(paquetes.paquete, remoto);
      await access.comprobar();
      await content.pendiente;
      expect(descargas, 1);
    });

    test('al vencer borra las fichas, el paquete y la llave', () async {
      await access.activar(await pase());
      await content.pendiente;
      await vencer();
      expect(content.secciones, isEmpty);
      expect(paquetes.paquete, isNull);
      expect(registro.guardado!.codigo, isNull);
      expect(access.pase!.llave, isNull);
    });

    test('el pase vencido no revive tras reabrir con la hora atrasada', () async {
      final codigo = await pase();
      await access.activar(codigo);
      await content.pendiente;
      await vencer();
      hora = hora.subtract(const Duration(minutes: 5));
      final reabierta = crearAcceso(publica);
      await reabierta.iniciar();
      addTearDown(reabierta.dispose);
      expect(reabierta.estado, EstadoAcceso.vencido);
      expect(await reabierta.activar(codigo), ResultadoPase.vencido);
    });

    test('con la app cerrada al vencer, borra todo al abrirla', () async {
      await access.activar(await pase());
      await content.pendiente;
      hora = hora.add(const Duration(hours: 2));
      final reabierta = crearAcceso(publica);
      final otro = crearContenido()..vincular(reabierta);
      await reabierta.iniciar();
      addTearDown(reabierta.dispose);
      await otro.pendiente;
      expect(paquetes.paquete, isNull);
      expect(registro.guardado!.codigo, isNull);
    });

    test('reabrir sin red durante la vigencia usa el paquete guardado', () async {
      await access.activar(await pase());
      await content.pendiente;
      sinRed = true;
      final reabierta = crearAcceso(publica);
      final otro = crearContenido()..vincular(reabierta);
      await reabierta.iniciar();
      addTearDown(reabierta.dispose);
      await otro.pendiente;
      expect(otro.estado, EstadoContenido.listo);
    });

    test('un fallo de red o una llave ajena no muestran contenido', () async {
      sinRed = true;
      await access.activar(await pase());
      await content.pendiente;
      expect(content.estado, EstadoContenido.error);
      sinRed = false;
      await content.reintentar();
      expect(content.estado, EstadoContenido.listo);

      hora = hora.add(const Duration(seconds: 1));
      paquetes.paquete = null;
      await access.activar(await pase(con: otraLlave));
      await content.pendiente;
      expect(content.secciones, isEmpty);
    });
  });

  test('limpiar el asistente descarta la respuesta en pantalla y la que se genera', () async {
    final chat = ChatController(FakeEngine(installed: true));
    await chat.start();
    final respuesta = chat.ask('una pregunta sin ficha');
    chat.clear();
    await respuesta;
    expect(chat.answer, isEmpty);
    expect(chat.reply, isNull);
  });
}
