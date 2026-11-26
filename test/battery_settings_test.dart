import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/settings/settings.dart';

class FakeBattery extends Fake implements Battery {
  int level = 15;

  @override
  Future<int> get batteryLevel async => level;

  @override
  Future<bool> get isInBatterySaveMode async => false;
}

void main() {
  test('se activa solo, se puede desactivar y vuelve a automático al recargar', () async {
    final battery = FakeBattery();
    final settings = Ajustes(bateria: battery);

    await settings.leerBateria();
    expect(settings.ahorroActivo, isTrue);

    settings.elegirAhorro(false);
    await settings.leerBateria();
    expect(settings.ahorroActivo, isFalse, reason: 'la lectura periódica no lo reactiva');

    battery.level = 80;
    await settings.leerBateria();
    battery.level = 20;
    await settings.leerBateria();
    expect(settings.ahorroActivo, isTrue, reason: 'un nuevo episodio de batería baja');
  });

  test('activado a mano se mantiene con batería alta', () async {
    final settings = Ajustes(bateria: FakeBattery()..level = 90);
    await settings.leerBateria();
    settings.elegirAhorro(true);
    await settings.leerBateria();
    expect(settings.ahorroActivo, isTrue);
  });
}
