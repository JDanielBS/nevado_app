import 'package:flutter/foundation.dart';

import '../../core/ai/llm_engine.dart';
import '../../core/ai/retriever.dart';
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

/// Lo que el prompt pide responder cuando los documentos no alcanzan.
const marcaSinRespuesta = 'SIN_RESPUESTA';

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
  List<Fragment> usedFragments = const [];

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

  /// Agrega un mensaje de la propia app a la conversación.
  void informar(String pregunta, String texto) {
    turnos.add(Turno(pregunta)..generado = texto);
    notifyListeners();
  }

  /// Descarta la respuesta en pantalla y la que se esté generando.
  void clear() {
    if (reply == null && answer.isEmpty && !answering) return;
    _discarded++;
    reply = null;
    answer = '';
    usedFragments = const [];
    notifyListeners();
  }

  /// Orden de decisión: reglas de seguridad, fichas y, solo con fragmentos, el modelo.
  ///
  /// Con [batterySaver] activo el modelo no se usa.
  Future<void> ask(
    String question, {
    List<Ficha> cards = const [],
    List<Fragment> fragments = const [],
    bool batterySaver = false,
  }) async {
    final text = question.trim();
    if (answering || text.isEmpty) return;
    final local = responderPregunta(text, cards);
    answer = '';
    usedFragments = const [];
    error = phase == ChatPhase.ready ? null : error;
    final turno = Turno(text);
    turnos.add(turno);
    // Las reglas de seguridad mandan; con fragmentos, el modelo redacta sobre ellos.
    if (local.tipo == TipoRespuesta.emergencia ||
        local.tipo == TipoRespuesta.limite ||
        phase != ChatPhase.ready ||
        batterySaver ||
        fragments.isEmpty) {
      reply = local;
      turno.respuesta = local;
      notifyListeners();
      return;
    }
    reply = null;
    usedFragments = fragments;
    answering = true;
    notifyListeners();
    final generation = _discarded;
    try {
      final prompt = _ragPrompt(text, fragments);
      final reloj = Stopwatch()..start();
      await for (final part in engine.generate(prompt)) {
        if (generation != _discarded) break;
        if (answer.isEmpty) debugPrint('RAG primera palabra ms=${reloj.elapsedMilliseconds} prompt=${prompt.length}');
        answer += part;
        // Mientras pueda ser la marca de abstención, no se muestra.
        final inicio = answer.trimLeft();
        final esMarca = marcaSinRespuesta.startsWith(inicio) || inicio.contains(marcaSinRespuesta);
        turno.generado = esMarca ? '' : answer;
        notifyListeners();
      }
      if (generation == _discarded && answer.contains(marcaSinRespuesta)) {
        // Abstención: mensaje fijo de la app, sin fuentes.
        answer = '';
        usedFragments = const [];
        turno.generado = '';
        reply = turno.respuesta = const Respuesta(TipoRespuesta.sinInformacion, mensajeSinInformacion, []);
        debugPrint('RAG total ms=${reloj.elapsedMilliseconds} abstención');
      } else if (generation == _discarded) {
        // La cita la pone la app a partir de lo recuperado, no el modelo.
        final fuentes = {for (final f in fragments.take(2)) _fuenteCorta(f.source)};
        answer = '${answer.split(RegExp(r'\n?\s*Fuente:')).first.trim()}\n\nFuente: ${fuentes.join('; ')}';
        turno.generado = answer;
        debugPrint('RAG total ms=${reloj.elapsedMilliseconds} respuesta=$answer');
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

  /// Plantilla de `prompt_sistema.md`; la de respaldo solo se usa en pruebas.
  String plantilla =
      'Responde en español, en máximo 4 frases. Usa solo los documentos. '
      'Si no responden la pregunta, responde solo $marcaSinRespuesta. No inventes datos.\n\n'
      'DOCUMENTOS DE CONSULTA\n{documentos}\n\nCONSULTA\n{consulta}';

  static String _fuenteCorta(String fuente) =>
      fuente.replaceAll(RegExp(r', https?://\S+?(?=,|;|$)'), '');

  String _ragPrompt(String question, List<Fragment> fragments) {
    final documentos = StringBuffer();
    for (final f in fragments) {
      final doc = '${f.path}\n${f.text}\nFuente: ${_fuenteCorta(f.source)}\n\n';
      // ponytail: tope por caracteres para caber en 2048 tokens; contar tokens si se recorta de más.
      if (documentos.isNotEmpty && documentos.length + doc.length > 3500) break;
      documentos.write(doc);
    }
    return plantilla
        .replaceFirst('{documentos}', documentos.toString().trim())
        .replaceFirst('{consulta}', question);
  }
}
