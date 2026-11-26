import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/settings/settings.dart';
import 'package:nevado_app/features/about/settings_card.dart';

class MemorySettingsStore implements AjustesStore {
  bool? voz;

  @override
  Future<bool?> leerVozActiva() async => voz;

  @override
  Future<void> guardarVozActiva(bool valor) async => voz = valor;
}

void main() {
  test('la voz empieza activada', () {
    expect(Ajustes(store: MemorySettingsStore()).vozActiva, isTrue);
  });

  test('apagar la voz se guarda y se recupera al abrir de nuevo', () async {
    final store = MemorySettingsStore();
    var avisos = 0;
    Ajustes(store: store)
      ..addListener(() => avisos++)
      ..vozActiva = false;
    await pumpEventQueue();
    expect(avisos, 1);
    expect(store.voz, isFalse);

    final otro = Ajustes(store: store);
    await otro.leerPreferencias();
    expect(otro.vozActiva, isFalse);
  });

  testWidgets('la tarjeta de ajustes permite apagar la voz', (tester) async {
    final settings = Ajustes(store: MemorySettingsStore());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ListenableBuilder(listenable: settings, builder: (_, _) => SettingsCard(settings: settings)),
        ),
      ),
    ));
    await tester.tap(find.text('Respuestas con voz'));
    await tester.pump();
    expect(settings.vozActiva, isFalse);
  });
}
