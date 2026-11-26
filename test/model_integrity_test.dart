import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nevado_app/core/ai/llm_engine.dart';
import 'package:nevado_app/core/ai/model_integrity.dart';

// SHA-256 de los bytes de "abc".
const abc = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad';

void main() {
  late Directory dir;
  late File model;
  var deleted = 0;

  Future<void> verify() =>
      verifyModelFile(model.path, abc, onCorrupt: () async => deleted++);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('integridad');
    model = File('${dir.path}/modelo.bin')..writeAsStringSync('abc');
    deleted = 0;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('archivo correcto pasa y queda marcado', () async {
    await verify();
    expect(File('${model.path}.sha256').readAsStringSync(), abc);
    expect(deleted, 0);
  });

  test('archivo marcado no se vuelve a calcular', () async {
    await verify();
    model.writeAsStringSync('otro');
    await verify();
    expect(deleted, 0);
  });

  test('archivo dañado se borra, lanza error y no queda marcado', () async {
    model.writeAsStringSync('abd');
    await expectLater(verify(), throwsA(isA<CorruptModelException>()));
    expect(deleted, 1);
    expect(File('${model.path}.sha256').existsSync(), isFalse);
  });

  test('una marca de otra versión obliga a verificar', () async {
    File('${model.path}.sha256').writeAsStringSync('0' * 64);
    model.writeAsStringSync('abd');
    await expectLater(verify(), throwsA(isA<CorruptModelException>()));
  });
}
