import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/app/app.dart';
import 'package:nevado_app/core/access/access_controller.dart';
import 'package:nevado_app/core/access/access_store.dart';
import 'package:nevado_app/core/access/pass.dart';

class MemoryStore implements AccessStore {
  PaseGuardado? guardado;

  @override
  Future<PaseGuardado?> leer() async => guardado;

  @override
  Future<void> guardar(PaseGuardado pase) async => guardado = pase;
}

/// Reloj de pared y cronómetro controlados por la prueba.
class Tiempo {
  DateTime hora = DateTime(2026, 11, 26, 8);
  Duration transcurrido = Duration.zero;

  /// Pasa el tiempo de forma normal.
  void avanzar(Duration d) {
    hora = hora.add(d);
    transcurrido += d;
  }
}

void main() {
  late SimpleKeyPair claves;
  late String publica;
  late MemoryStore store;
  late Tiempo tiempo;

  setUp(() async {
    claves = await Ed25519().newKeyPair();
    publica = _base64((await claves.extractPublicKey()).bytes);
    store = MemoryStore();
    tiempo = Tiempo();
  });

  AccessController crear() => AccessController(
    store: store,
    clavePublica: publica,
    reloj: () => tiempo.hora,
    cronometro: () => tiempo.transcurrido,
  );

  Future<String> pase({Duration vigencia = const Duration(minutes: 5), SimpleKeyPair? firmante}) =>
      firmarPase(Pase(emitido: tiempo.hora, vence: tiempo.hora.add(vigencia)), firmante ?? claves);

  test('sin pase queda bloqueada', () async {
    final access = crear();
    await access.comprobar();
    expect(access.estado, EstadoAcceso.sinPase);
  });

  test('un pase vigente habilita y vence a los 5 minutos', () async {
    final access = crear();
    expect(await access.activar(await pase()), ResultadoPase.aceptado);
    expect(access.restante, const Duration(minutes: 5));
    tiempo.avanzar(const Duration(minutes: 4, seconds: 59));
    await access.comprobar();
    expect(access.activo, isTrue);
    tiempo.avanzar(const Duration(seconds: 1));
    await access.comprobar();
    expect(access.estado, EstadoAcceso.vencido);
  });

  test('rechaza texto cualquiera, datos alterados y firmas ajenas', () async {
    final access = crear();
    final largo = (await pase(vigencia: const Duration(days: 365))).split('.');
    final corto = (await pase()).split('.');
    final ajeno = await pase(firmante: await Ed25519().newKeyPair());
    for (final codigo in ['', 'hola', 'NEV1.a.b', '${corto[0]}.${largo[1]}.${corto[2]}', ajeno]) {
      expect(await access.activar(codigo), ResultadoPase.invalido, reason: codigo);
    }
    expect(access.activo, isFalse);
  });

  test('sin clave pública ningún pase sirve', () async {
    final access = AccessController(store: store, clavePublica: '', reloj: () => tiempo.hora);
    expect(await access.activar(await pase()), ResultadoPase.invalido);
  });

  test('rechaza un pase vencido o con la hora del teléfono muy atrasada', () async {
    final access = crear();
    final codigo = await pase();
    tiempo.avanzar(const Duration(minutes: 6));
    expect(await access.activar(codigo), ResultadoPase.vencido);
    tiempo.hora = tiempo.hora.subtract(const Duration(hours: 1));
    expect(await access.activar(codigo), ResultadoPase.relojDesajustado);
  });

  test('atrasar el reloj bloquea la app', () async {
    final access = crear();
    await access.activar(await pase(vigencia: const Duration(hours: 1)));
    tiempo.avanzar(const Duration(minutes: 10));
    await access.comprobar();
    tiempo.hora = tiempo.hora.subtract(const Duration(minutes: 5));
    await access.comprobar();
    expect(access.estado, EstadoAcceso.relojAtrasado);
  });

  test('atrasos pequeños y repetidos no detienen el vencimiento', () async {
    final access = crear();
    await access.activar(await pase());
    for (var i = 0; i < 10; i++) {
      tiempo.avanzar(const Duration(seconds: 50));
      tiempo.hora = tiempo.hora.subtract(const Duration(seconds: 50));
      await access.comprobar();
    }
    expect(access.estado, EstadoAcceso.vencido);
  });

  test('un pase vencido no revive al reabrir con la hora atrasada ni reescaneando', () async {
    final codigo = await pase();
    final primero = crear();
    await primero.activar(codigo);
    tiempo.avanzar(const Duration(minutes: 6));
    await primero.comprobar();

    tiempo.hora = tiempo.hora.subtract(const Duration(minutes: 4));
    final segundo = crear();
    await segundo.iniciar();
    addTearDown(segundo.dispose);
    expect(segundo.estado, EstadoAcceso.vencido);
    expect(await segundo.activar(codigo), ResultadoPase.vencido);
    expect(segundo.activo, isFalse);
  });

  test('el pase se conserva al reabrir la app', () async {
    await crear().activar(await pase());
    tiempo.avanzar(const Duration(minutes: 2));
    final access = crear();
    await access.iniciar();
    addTearDown(access.dispose);
    expect(access.restante, const Duration(minutes: 3));
  });

  test('un pase más reciente desbloquea después de un cambio de hora', () async {
    final access = crear();
    tiempo.hora = tiempo.hora.add(const Duration(days: 1));
    final adelantado = tiempo.hora;
    await access.activar(await pase());
    // Se corrige la hora del teléfono: queda por detrás de lo guardado.
    tiempo.hora = adelantado.subtract(const Duration(hours: 1));
    await access.comprobar();
    expect(access.activo, isFalse);
    // Se emite un pase nuevo, posterior al anterior.
    tiempo.hora = adelantado.add(const Duration(minutes: 1));
    final nuevo = await pase();
    expect(await access.activar(nuevo), ResultadoPase.aceptado);
    expect(access.activo, isTrue);
  });

  testWidgets('sin pase solo abren emergencias y ubicación; al vencer se cierra la sección', (tester) async {
    final access = crear();
    await tester.runAsync(access.comprobar);
    await tester.pumpWidget(NevadoApp(access: access));

    Future<void> abrir(String label) async {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    for (final label in ['Asistente', 'Mapa', 'Fichas']) {
      await abrir(label);
      expect(find.text('Escanear pase'), findsOneWidget, reason: label);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    await abrir('Mi ubicación');
    expect(find.text('Obtener mi ubicación'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.runAsync(() async => access.activar(await pase()));
    await tester.pumpAndSettle();
    await abrir('Fichas');
    expect(find.text('Buscar en las fichas'), findsOneWidget);

    tiempo.avanzar(const Duration(minutes: 6));
    await tester.runAsync(access.comprobar);
    await tester.pumpAndSettle();
    expect(find.text('Buscar en las fichas'), findsNothing);
    expect(find.textContaining('El pase venció'), findsOneWidget);
  });
}

String _base64(List<int> bytes) => base64Url.encode(bytes);
