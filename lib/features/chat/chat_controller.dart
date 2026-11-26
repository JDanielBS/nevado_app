import 'package:flutter/foundation.dart';

import '../../core/ai/llm_engine.dart';
import '../../core/assistant/responder.dart';
import '../../core/content/card.dart';

/// Una pregunta del visitante y lo que se le respondió.
class Turno {
  Turno(this.pregunta);

  final String pregunta;

  /// Respuesta de las reglas o de las fichas.
  Respuesta? respuesta;

  /// Texto generado por el modelo, si respondió él.
  String generado = '';

  /// El modelo no pudo responder.
  bool fallo = false;
}

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
  /// Texto generado por el modelo.
  String answer = '';

  /// Respuesta de las reglas o de las fichas. Cuando existe, el modelo no interviene.
  Respuesta? reply;

  /// Conversación completa, de la más antigua a la más reciente.
  final List<Turno> turnos = [];
  bool answering = false;
  Future<void>? _preparation;
  int _discarded = 0;

  /// Servidor de la estación desde el que descargar el modelo.
  Uri? origen;

  /// El modelo ya se comprobó o se encontró instalado.
  bool instalado = false;

  /// La pantalla del asistente está abierta: no conviene liberar el modelo.
  bool enPantalla = false;

  bool get canDownload => origen != null || engine.canDownload;

  void _set(ChatPhase next, [String? message]) {
    phase = next;
    error = message;
    notifyListeners();
  }

  Future<void> start() => _preparation ??= _start();

  Future<void> _start() async {
    final reason = engine.unsupportedReason();
    if (reason != null) return _set(ChatPhase.unsupported, reason);
    await _prepare();
  }

  Future<void> retry() async {
    if (phase == ChatPhase.failed) await _prepare();
  }

  /// Libera la memoria del modelo al salir de la pantalla y deja el asistente
  /// listo para cargarlo de nuevo con [start].
  ///
  /// El modelo queda instalado en disco: aquí solo se recupera su memoria.
  Future<void> release() async {
    if (phase != ChatPhase.ready) return;
    _preparation = null;
    phase = ChatPhase.checking;
    await engine.unload();
  }

  /// Descarga el modelo desde [url] si todavía no está instalado, sin necesidad de abrir el asistente.
  Future<void> provision(Uri url) async {
    origen = url;
    notifyListeners();
    if (engine.unsupportedReason() != null) return start();
    try {
      if (await engine.isInstalled()) {
        instalado = true;
        return notifyListeners();
      }
    } catch (e) {
      debugPrint('Asistente: $e');
      return _set(ChatPhase.failed, 'No se pudo revisar el modelo.');
    }
    await start();
    if (phase == ChatPhase.failed) await retry();
    await download();
    // Se recupera la memoria si nadie está usando el asistente.
    if (!enPantalla) await release();
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
      await for (final percent in engine.install(origen: origen)) {
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
      instalado = true;
      _set(ChatPhase.ready);
    } on CorruptModelException {
      instalado = false;
      _set(
        ChatPhase.noModel,
        'El archivo del modelo está dañado y se borró. Descárgalo de nuevo.',
      );
    } catch (e) {
      debugPrint('Asistente: $e');
      _set(ChatPhase.failed, 'No se pudo cargar el modelo.');
    }
  }

  /// Descarta la respuesta en pantalla y la que se esté generando.
  void clear() {
    if (reply == null && answer.isEmpty && !answering) return;
    _discarded++;
    reply = null;
    answer = '';
    notifyListeners();
  }

  /// Orden de decisión: reglas de seguridad, fichas y, solo si no hay nada, el modelo.
  ///
  /// Con [batterySaver] activo el modelo no se usa.
  Future<void> ask(
    String question, {
    List<Ficha> cards = const [],
    bool batterySaver = false,
  }) async {
    final text = question.trim();
    if (answering || text.isEmpty) return;
    final local = responderPregunta(text, cards);
    answer = '';
    error = phase == ChatPhase.ready ? null : error;
    final turno = Turno(text);
    turnos.add(turno);
    if (local.tipo != TipoRespuesta.sinInformacion ||
        phase != ChatPhase.ready ||
        batterySaver) {
      reply = local;
      turno.respuesta = local;
      notifyListeners();
      return;
    }
    reply = null;
    answering = true;
    notifyListeners();
    final generation = _discarded;
    try {
      final prompt = 'Responde en español, en máximo 3 frases.\n\n$text';
      await for (final part in engine.generate(prompt)) {
        if (generation != _discarded) break;
        answer += part;
        turno.generado = answer;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Asistente: $e');
      error = 'No se pudo responder. Intenta de nuevo.';
      turno.fallo = true;
    } finally {
      answering = false;
      notifyListeners();
    }
  }
}
