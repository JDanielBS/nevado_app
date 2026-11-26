import 'package:flutter/foundation.dart';

import '../../core/ai/llm_engine.dart';

enum ChatPhase {
  checking,
  unsupported,
  noModel,
  downloading,
  loading,
  ready,
  failed,
}

/// Estado del asistente. Vive fuera de la pantalla para que la descarga y la
/// respuesta sigan si el usuario sale y vuelve.
class ChatController extends ChangeNotifier {
  ChatController(this.engine);

  final LlmEngine engine;

  ChatPhase phase = ChatPhase.checking;

  /// Mensaje para el usuario: motivo de incompatibilidad o último fallo.
  String? error;
  int progress = 0;
  String answer = '';
  bool answering = false;
  bool _started = false;

  void _set(ChatPhase next, [String? message]) {
    phase = next;
    error = message;
    notifyListeners();
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    final reason = engine.unsupportedReason();
    if (reason != null) return _set(ChatPhase.unsupported, reason);
    await _prepare();
  }

  Future<void> retry() async {
    if (phase == ChatPhase.failed) await _prepare();
  }

  Future<void> _prepare() async {
    _set(ChatPhase.checking);
    try {
      if (!await engine.isInstalled()) return _set(ChatPhase.noModel);
    } catch (e) {
      debugPrint('Asistente: $e');
      return _set(ChatPhase.failed, 'No se pudo revisar el modelo.');
    }
    await _load();
  }

  Future<void> download() async {
    if (phase != ChatPhase.noModel) return;
    progress = 0;
    _set(ChatPhase.downloading);
    try {
      await for (final percent in engine.install()) {
        progress = percent;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Asistente: $e');
      return _set(
        ChatPhase.noModel,
        'No se pudo descargar. Revisa la conexión y el espacio libre.',
      );
    }
    await _load();
  }

  Future<void> _load() async {
    _set(ChatPhase.loading);
    try {
      await engine.load();
      _set(ChatPhase.ready);
    } on CorruptModelException {
      _set(
        ChatPhase.noModel,
        'El archivo del modelo está dañado y se borró. Descárgalo de nuevo.',
      );
    } catch (e) {
      debugPrint('Asistente: $e');
      _set(ChatPhase.failed, 'No se pudo cargar el modelo.');
    }
  }

  Future<void> ask(String question) async {
    final text = question.trim();
    if (phase != ChatPhase.ready || answering || text.isEmpty) return;
    answering = true;
    answer = '';
    error = null;
    notifyListeners();
    try {
      final prompt = 'Responde en español, en máximo 3 frases.\n\n$text';
      await for (final part in engine.generate(prompt)) {
        answer += part;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Asistente: $e');
      error = 'No se pudo responder. Intenta de nuevo.';
    } finally {
      answering = false;
      notifyListeners();
    }
  }
}
