import 'package:flutter_test/flutter_test.dart';

import 'fake_tts_engine.dart';

void main() {
  test('speak registra el texto y stop interrumpe la reproducción', () async {
    final engine = FakeTtsEngine()..holdSpeech = true;
    final speech = engine.speak('Hola');
    expect(engine.spoken, ['Hola']);
    expect(engine.isSpeaking, isTrue);
    await engine.stop();
    await speech;
    expect(engine.isSpeaking, isFalse);
  });
}
