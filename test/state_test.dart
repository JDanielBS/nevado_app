import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/settings/battery_saver.dart';
import 'package:nevado_app/core/location/location_format.dart';

void main() {
  group('describirPrecision', () {
    test('clasifica por metros', () {
      expect(describirPrecision(8).nivel, NivelPrecision.buena);
      expect(describirPrecision(20).nivel, NivelPrecision.buena);
      expect(describirPrecision(50).nivel, NivelPrecision.regular);
      expect(describirPrecision(300).nivel, NivelPrecision.mala);
    });
    test('no inventa precisión si no hay dato', () {
      expect(describirPrecision(null).nivel, NivelPrecision.mala);
      expect(describirPrecision(double.nan).texto, 'Precisión desconocida');
    });
  });

  group('describirAntiguedad', () {
    const t = 1000000;
    test('formatea segundos, minutos y horas', () {
      expect(describirAntiguedad(t, t + 3000), 'ahora mismo');
      expect(describirAntiguedad(t, t + 30000), 'hace 30 s');
      expect(describirAntiguedad(t, t + 5 * 60000), 'hace 5 min');
      expect(describirAntiguedad(t, t + 3 * 3600000), 'hace 3 h');
    });
    test('no da negativos si el reloj se desfasa', () {
      expect(describirAntiguedad(t + 5000, t), 'ahora mismo');
    });
  });

  group('formatearCoordenadas', () {
    test('indica hemisferio', () {
      expect(formatearCoordenadas(4.89563, -75.37), '4.89563° N, 75.37000° O');
      expect(formatearCoordenadas(-1.5, 10), '1.50000° S, 10.00000° E');
    });
  });

  group('calcularAhorro', () {
    ({bool activo, MotivoAhorro? motivo}) calcular({double? nivel = 0.8, bool sistema = false, bool manual = false}) =>
        calcularAhorro(nivel: nivel, ahorroSistema: sistema, manual: manual);

    test('está apagado con batería normal', () {
      expect(calcular(), (activo: false, motivo: null));
    });
    test('se activa con batería baja, incluido el límite', () {
      expect(calcular(nivel: 0.2).motivo, MotivoAhorro.bateriaBaja);
      expect(calcular(nivel: 0.21).activo, isFalse);
    });
    test('lo manual tiene prioridad', () {
      expect(calcular(manual: true, nivel: 0.1).motivo, MotivoAhorro.manual);
    });
    test('respeta el ahorro del sistema', () {
      expect(calcular(sistema: true).motivo, MotivoAhorro.ahorroSistema);
    });
    test('un nivel no disponible no activa el ahorro', () {
      expect(calcular(nivel: -1).activo, isFalse);
      expect(calcular(nivel: null).activo, isFalse);
    });
    test('porcentaje maneja el valor no disponible', () {
      expect(porcentaje(0.456), '46 %');
      expect(porcentaje(-1), 'no disponible');
    });
  });
}
