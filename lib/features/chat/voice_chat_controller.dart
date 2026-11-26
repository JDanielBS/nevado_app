import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/content/card.dart';
import '../../core/voice/tts_engine.dart';
import '../../core/voice/tts_exceptions.dart';
import '../../core/voice/voice_file.dart';
import 'chat_controller.dart';

enum VoicePhase { checking, unsupported, noModel, downloading, loading, ready, failed }

/// Dónde se recuerda si las respuestas se leen solas.
abstract interface class VoiceStore {
  Future<bool?> leerAutoLeer();
  Future<void> guardarAutoLeer(bool valor);
}

/// Almacenamiento local del teléfono.
class PreferencesVoiceStore implements VoiceStore {
  static const _clave = 'voz_auto_leer';

  // Se crea al usarlo: en pruebas puede no existir el almacenamiento.
  late final _preferencias = SharedPreferencesAsync();

  @override
  Future<bool?> leerAutoLeer() => _preferencias.getBool(_clave);

  @override
  Future<void> guardarAutoLeer(bool valor) => _preferencias.setBool(_clave, valor);
}

/// Voz de la Guía IA. El texto sigue siendo del [chat]; aquí solo se gestiona el
/// modelo de voz y qué se lee: únicamente lo que ha escrito el modelo de lenguaje.
class VoiceChatController extends ChangeNotifier {
  VoiceChatController(this.chat, this.tts, {VoiceStore? store}) : _store = store ?? PreferencesVoiceStore() {
    chat.addListener(notifyListeners);
  }

  final ChatController chat;
  final TtsEngine tts;
  final VoiceStore _store;

  VoicePhase phase = VoicePhase.checking;

  /// Motivo de incompatibilidad o último fallo de la voz.
  String? error;
  int progress = 0;
  bool autoSpeak = true;

  /// Turno que se está leyendo.
  Turno? speaking;

  /// El modelo de voz ya está en el teléfono.
  bool instalada = false;

  /// La pantalla de Guía IA está abierta: no conviene liberar la voz.
  bool enPantalla = false;

  /// El pase indicó la estación, que es de donde se descarga la voz.
  bool get canDownload => chat.origen != null;

  Future<void>? _preparation;

  /// Cambia con cada lectura o parada: lo pedido antes queda sin efecto.
  int _generacion = 0;

  List<Turno> get turnos => chat.turnos;

  void _set(VoicePhase next, [String? message]) {
    phase = next;
    error = message;
    notifyListeners();
  }

  Future<void> start() => _preparation ??= _start();

  Future<void> _start() async {
    try {
      autoSpeak = await _store.leerAutoLeer() ?? true;
    } catch (e) {
      debugPrint('Voz: $e');
    }
    final reason = tts.unsupportedReason();
    if (reason != null) return _set(VoicePhase.unsupported, reason);
    await _prepare();
  }

  Future<void> retry() async {
    if (phase == VoicePhase.failed) await _prepare();
  }

  Future<void> _prepare() async {
    _set(VoicePhase.checking);
    try {
      instalada = await tts.isInstalled();
      if (!instalada) return _set(VoicePhase.noModel);
    } catch (e) {
      debugPrint('Voz: $e');
      return _set(VoicePhase.failed, 'No se pudo revisar la voz.');
    }
    await _load();
  }

  /// Descarga la voz de la estación que reparte el modelo en [modelo], si todavía no está.
  Future<void> provision(Uri modelo) async {
    chat.origen ??= modelo;
    if (tts.unsupportedReason() != null) return start();
    try {
      if (await tts.isInstalled()) {
        instalada = true;
        return notifyListeners();
      }
    } catch (e) {
      debugPrint('Voz: $e');
      return _set(VoicePhase.failed, 'No se pudo revisar la voz.');
    }
    await start();
    if (phase == VoicePhase.failed) await retry();
    await download();
    // Se recupera la memoria si nadie está en la Guía IA.
    if (!enPantalla) await release();
  }

  Future<void> download() async {
    final estacion = chat.origen;
    if (phase != VoicePhase.noModel || estacion == null) return;
    progress = 0;
    _set(VoicePhase.downloading);
    try {
      await for (final percent in tts.install(origen: estacion.resolve(nombreVoz))) {
        progress = percent;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Voz: $e');
      return _set(
        VoicePhase.noModel,
        'No se pudo descargar la voz. Revisa que sigues en la red de la estación y el espacio libre.',
      );
    }
    await _load();
  }

  Future<void> _load() async {
    _set(VoicePhase.loading);
    try {
      await tts.load();
      instalada = true;
      _set(VoicePhase.ready);
    } on CorruptVoiceModelException {
      instalada = false;
      _set(VoicePhase.noModel, 'La voz está dañada y se borró. Descárgala de nuevo en la estación.');
    } catch (e) {
      debugPrint('Voz: $e');
      _set(VoicePhase.failed, 'No se pudo cargar la voz.');
    }
  }

  /// Calla y libera la memoria de la voz; [start] la vuelve a cargar.
  Future<void> release() async {
    await stop();
    if (phase != VoicePhase.ready) return;
    _preparation = null;
    phase = VoicePhase.checking;
    await tts.unload();
  }

  Future<void> setAutoSpeak(bool value) async {
    autoSpeak = value;
    notifyListeners();
    if (!value) await stop();
    try {
      await _store.guardarAutoLeer(value);
    } catch (e) {
      debugPrint('Voz: $e');
    }
  }

  /// Responde en texto y, al terminar, lee la respuesta sin esperar al audio.
  ///
  /// [permitida] es `false` en modo ahorro o con la voz desactivada en ajustes.
  Future<void> ask(
    String question, {
    List<Ficha> cards = const [],
    bool batterySaver = false,
    bool permitida = true,
  }) async {
    if (chat.answering || question.trim().isEmpty) return;
    final previos = turnos.length;
    // La marca se toma antes de esperar, para no perder una parada que llegue enseguida.
    final parada = stop();
    final generacion = _generacion;
    await parada;
    await chat.ask(question, cards: cards, batterySaver: batterySaver);
    // La conversación puede haberse borrado mientras tanto (pase vencido).
    if (generacion != _generacion || turnos.isEmpty || turnos.length == previos) return;
    if (autoSpeak && permitida && !batterySaver) unawaited(repeat(turnos.last));
  }

  /// La voz solo dice lo que escribió el modelo: ni fichas, ni reglas, ni avisos.
  bool puedeLeer(Turno turno) => turno.respuesta == null && !turno.fallo && turno.generado.isNotEmpty;

  /// Lee la respuesta de [turno], interrumpiendo lo que estuviera sonando.
  Future<void> repeat(Turno turno) async {
    if (phase != VoicePhase.ready || !puedeLeer(turno)) return;
    final parada = stop();
    final generacion = _generacion;
    await parada;
    if (generacion != _generacion) return;
    speaking = turno;
    error = null;
    notifyListeners();
    try {
      await tts.speak(turno.generado);
    } catch (e) {
      debugPrint('Voz: $e');
      if (generacion == _generacion) error = 'No se pudo reproducir el audio.';
    }
    if (generacion != _generacion) return;
    speaking = null;
    notifyListeners();
  }

  Future<void> stop() async {
    _generacion++;
    if (speaking == null) return;
    speaking = null;
    notifyListeners();
    try {
      await tts.stop();
    } catch (e) {
      debugPrint('Voz: $e');
    }
  }

  @override
  void dispose() {
    chat.removeListener(notifyListeners);
    super.dispose();
  }
}
