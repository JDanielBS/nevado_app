import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/access/access_controller.dart';
import 'package:nevado_app/core/access/pass.dart';
import 'package:nevado_app/core/content/card.dart';
import 'package:nevado_app/core/content/carpeta_contenido.dart';
import 'package:nevado_app/core/content/content_controller.dart';
import 'package:nevado_app/core/content/content_package.dart';
import 'package:nevado_app/core/content/package_io.dart';
import 'package:nevado_app/core/content/publicacion_r2.dart';
import 'package:nevado_app/core/content/seccion.dart';
import 'package:nevado_app/features/guia/compartir_controller.dart';
import 'package:nevado_app/features/guia/guia_contenido.dart';

import 'access_test.dart' show MemoryStore;
import 'security_test.dart' show MemoryPackageStore;

/// Imita al Worker de `cloudflare/worker.js`: mismo protocolo, en memoria.
class R2Simulado {
  R2Simulado(this.clave);
  final String clave;
  final objetos = <String, Uint8List>{};
  late HttpServer servidor;

  Uri get base => Uri.parse('http://127.0.0.1:${servidor.port}/');

  Future<void> iniciar() async {
    servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servidor.listen((p) async {
      final ruta = p.uri.path.substring(1);
      final r = p.response;
      if (p.method == 'GET') {
        final o = objetos[ruta];
        r.statusCode = o == null ? 404 : 200;
        if (o != null) r.add(o);
      } else if (p.method == 'PUT' && ruta == rutaPaqueteR2) {
        if (p.headers.value('authorization') != 'Bearer $clave') {
          r.statusCode = 401;
        } else {
          final base = int.parse(p.headers.value('x-version-base')!);
          final anterior = objetos[rutaManifiestoR2];
          final actual = anterior == null ? 0 : (jsonDecode(utf8.decode(anterior)) as Map)['version'] as int;
          if (actual != base) {
            r.statusCode = 409;
            r.write(jsonEncode({'version': actual}));
          } else {
            final cuerpo = Uint8List.fromList(await p.expand((b) => b).toList());
            final m = utf8.encode(
              jsonEncode({
                'version': actual + 1,
                'publicado': DateTime.now().toIso8601String(),
                'bytes': cuerpo.length,
                'sha256': sha256.convert(cuerpo).toString(),
              }),
            );
            objetos[rutaPaqueteR2] = cuerpo;
            objetos[rutaManifiestoR2] = Uint8List.fromList(m);
            r.add(m);
          }
        }
      } else {
        r.statusCode = 404;
      }
      await r.close();
    });
  }
}

const _seccion = '''
# Naturaleza
## Frailejón
### Ficha técnica
Planta que capta agua de la niebla.

Fuente: Guion Ecoturístico UTON 2024, p. 5
''';

void main() {
  final llave = List<int>.generate(bytesLlave, (i) => i * 3);
  late Directory dir;
  late GuiaContenido guia;

  Future<GuiaContenido> nuevoGuia(String nombre) async {
    final g = GuiaContenido(emergencia: const [], carpeta: Directory('${dir.path}/$nombre'));
    await g.iniciar(semilla: () async => [('naturaleza.md', _seccion), ('avisos.md', '# Avisos vigentes\n')]);
    return g;
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('guia');
    guia = await nuevoGuia('a');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('contenido del guía', () {
    test('se siembra la primera vez y luego se conserva lo editado', () async {
      expect(guia.secciones.map((s) => s.archivo), ['naturaleza.md', 'avisos.md']);
      guia.guardarTema('naturaleza.md', Tema(titulo: 'Cóndor', ficha: [Apartado(texto: 'Ave.', fuente: 'F, p. 1')]));
      final reabierto = await nuevoGuia('a');
      expect(reabierto.secciones.first.temas.map((t) => t.titulo), ['Frailejón', 'Cóndor']);
      expect(reabierto.sinPublicar, isTrue);
    });

    test('lo que agrega el guía lo encuentra el asistente', () {
      guia.guardarTema(
        'naturaleza.md',
        Tema(titulo: 'Danta de montaña', ficha: [Apartado(texto: 'Dispersa semillas.', fuente: 'Guion norte, p. 2')]),
      );
      expect(guia.indice.buscar('danta').first.fragmento.ruta, contains('Danta'));
    });

    test('crea, renombra, ordena y borra secciones, salvo las fijas', () {
      final archivo = guia.crearSeccion('Aves del páramo');
      expect(archivo, 'aves-del-paramo.md');
      guia.editarSeccion(archivo, titulo: 'Aves', descripcion: 'Especies de alta montaña.');
      guia.moverSeccion(archivo, -2);
      expect(guia.secciones.first.titulo, 'Aves');
      expect(() => guia.borrarSeccion('avisos.md'), throwsStateError);
      guia.borrarSeccion(archivo);
      expect(guia.secciones.map((s) => s.archivo), isNot(contains(archivo)));
      expect(File('${guia.carpeta.path}/$archivo').existsSync(), isFalse);
    });
  });

  group('publicación en R2', () {
    late R2Simulado r2;
    setUp(() async {
      r2 = R2Simulado('secreta');
      await r2.iniciar();
    });
    tearDown(() => r2.servidor.close(force: true));

    test('publica cifrado y otro guía lo descarga', () async {
      final m = await guia.publicar(ClienteR2(r2.base, clave: 'secreta'), llave);
      expect(m.version, 1);
      expect(guia.sinPublicar, isFalse);
      expect(latin1.decode(r2.objetos[rutaPaqueteR2]!), isNot(contains('Frailejón')));

      final otro = GuiaContenido(emergencia: const [], carpeta: Directory('${dir.path}/b'));
      await otro.iniciar();
      expect(otro.secciones, isEmpty);
      await otro.actualizar(ClienteR2(r2.base), llave);
      expect(otro.secciones.first.temas.single.titulo, 'Frailejón');
      expect(otro.version, 1);
    });

    test('si otro guía publicó antes, avisa el conflicto', () async {
      final otro = await nuevoGuia('b');
      await otro.publicar(ClienteR2(r2.base, clave: 'secreta'), llave);
      await expectLater(guia.publicar(ClienteR2(r2.base, clave: 'secreta'), llave), throwsA(isA<ConflictoDeVersion>()));
    });

    test('sin la clave no publica', () async {
      await expectLater(guia.publicar(ClienteR2(r2.base, clave: 'otra'), llave), throwsA(isA<HttpException>()));
      expect(r2.objetos, isEmpty);
    });

    test('el visitante descarga antes de la visita y abre con el pase, sin red', () async {
      await guia.publicar(ClienteR2(r2.base, clave: 'secreta'), llave);
      final claves = await Ed25519().newKeyPair();
      final publica = base64Url.encode((await claves.extractPublicKey()).bytes);
      final hora = DateTime(2026, 11, 26, 8);
      final acceso = AccessController(store: MemoryStore(), clavePublica: publica, reloj: () => hora, cronometro: () => Duration.zero);
      final paquetes = MemoryPackageStore();
      var conRed = true;
      final visitante = ContentController(
        emergencia: const <Ficha>[],
        store: paquetes,
        internet: r2.base.resolve(rutaPaqueteR2),
        descargar: (u) => conRed ? descargarPaquete(u) : throw const SocketException('sin red'),
      )..vincular(acceso);
      await acceso.comprobar();
      await visitante.predescargar();
      expect(paquetes.paquete, isNotNull);
      expect(visitante.secciones, isEmpty);

      conRed = false;
      final codigo = await firmarPase(Pase(emitido: hora, vence: hora.add(const Duration(minutes: 10)), llave: llave), claves);
      await acceso.activar(codigo);
      await visitante.pendiente;
      expect(visitante.estado, EstadoContenido.listo);
      expect(visitante.secciones.first.temas.single.titulo, 'Frailejón');
    });
  });

  group('zona wifi del guía', () {
    test('el visitante recibe el contenido del teléfono del guía con el pase', () async {
      final semilla = await Ed25519().newKeyPair();
      final privada = base64Url.encode(await semilla.extractPrivateKeyBytes());
      final publica = base64Url.encode((await semilla.extractPublicKey()).bytes);
      final compartir = CompartirController(
        contenido: guia,
        carpetaTrabajo: Directory('${dir.path}/compartir'),
        clavePrivada: privada,
        llave: llave,
        buscarModelo: () async => null,
        buscarApk: () async => null,
        buscarRedes: () async => [(interfaz: 'lo', ip: '127.0.0.1')],
      );
      await compartir.encender(puerto: 0);
      addTearDown(compartir.apagar);
      expect(compartir.error, isNull);
      expect(compartir.codigoPase, isNotNull);

      final pase = await leerPase(compartir.codigoPase!, publica);
      expect(pase!.contenido.toString(), startsWith('http://127.0.0.1:'));
      expect(pase.modelo, isNull);
      expect(pase.vence.difference(pase.emitido), const Duration(minutes: minutosPase));

      final acceso = AccessController(store: MemoryStore(), clavePublica: publica);
      final visitante = ContentController(emergencia: const <Ficha>[], store: MemoryPackageStore())..vincular(acceso);
      await acceso.activar(compartir.codigoPase!);
      await visitante.pendiente;
      expect(visitante.secciones.first.temas.single.titulo, 'Frailejón');
    });

    test('sin las claves del guía no enciende', () async {
      final compartir = CompartirController(
        contenido: guia,
        carpetaTrabajo: Directory('${dir.path}/compartir'),
        clavePrivada: '',
        llave: null,
        buscarModelo: () async => null,
        buscarApk: () async => null,
      );
      await compartir.encender(puerto: 0);
      expect(compartir.encendido, isFalse);
      expect(compartir.error, contains('claves'));
    });
  });

  test('la carpeta conserva el orden y no deja temporales', () {
    final c = leerCarpeta(guia.carpeta);
    expect(c.archivos.map((a) => a.$1), ['naturaleza.md', 'avisos.md']);
    expect(guia.carpeta.listSync().where((f) => f.path.endsWith('.tmp')), isEmpty);
    expect(leerSeccion('x.md', c.archivos.first.$2).temas.single.ficha.single.fuente, isNotNull);
  });
}
