import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/ai/edge_llm_engine.dart';
import '../../core/content/card.dart';
import '../../core/ai/knowledge_base.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import 'chat_controller.dart';
import 'rag_check.dart';
import 'reply_view.dart';

final chatDeLaApp = ChatController(EdgeLlmEngine());

final conocimiento = KnowledgeBase();

const preguntasSugeridas = [
  '¿Puedo ir al cráter?',
  'Me duele la cabeza',
  '¿Puedo llevarme una roca?',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.controller});

  final ChatController? controller;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _chat = widget.controller ?? chatDeLaApp;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chat.enPantalla = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _batterySaver) return;
      // Pruebas (controlador propio): sin índice ni modelo de embeddings.
      if (widget.controller == null) unawaited(conocimiento.indexar());
      _chat.start();
    });
  }

  bool get _batterySaver =>
      AppScope.maybeOf(context)?.settings.ahorroActivo ?? false;

  void _ask([String? suggested]) {
    final question = suggested ?? _input.text;
    final cards = AppScope.maybeOf(context)?.cards ?? const <Ficha>[];
    _askWithRetriever(question, cards);
    if (suggested == null) _input.clear();
  }

  Future<void> _askWithRetriever(String question, List<Ficha> cards) async {
    if (question.trim() == '/prueba') {
      final resumen = await autoprueba(conocimiento);
      _chat.informar(question, resumen);
      return;
    }
    await conocimiento.cargar();
    if (conocimiento.plantilla.isNotEmpty) _chat.plantilla = conocimiento.plantilla;
    final fragments = await conocimiento.retrieve(question);
    if (!mounted) return;
    await _chat.ask(
      question,
      cards: cards,
      fragments: fragments,
      batterySaver: _batterySaver,
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _chat.enPantalla = false;
    unawaited(_chat.release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    final saver = AppScope.maybeOf(context)?.settings.ahorroActivo ?? false;
    return Material(
      type: MaterialType.transparency,
      child: ListenableBuilder(
        listenable: Listenable.merge([_chat, conocimiento.estado]),
        builder: (context, _) {
          final estado = [
            if (saver)
              const Linea(
                'Modo ahorro: respondo solo con las fichas, sin modelo de IA.',
              ),
            if (conocimiento.estado.value.isNotEmpty) Linea(conocimiento.estado.value),
            if (_chat.error != null)
              Linea(_chat.error!, color: Colores.aviso, negrita: true),
            ..._content(),
          ];
          final turnos = _chat.turnos;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colores.superficie,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tema.acento, width: 2),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Guía virtual · sin conexión\n',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              'Experimental: puede equivocarse. Responde con las fichas del parque y '
                              'no informa el estado actual del volcán.',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Colores.texto,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    reverse: true,
                    children: [
                      if (estado.isNotEmpty)
                        Caja(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 8,
                            children: estado,
                          ),
                        ),
                      for (final (i, turno) in turnos.indexed.toList().reversed)
                        TurnoView(
                          turno: turno,
                          respondiendo:
                              _chat.answering && i == turnos.length - 1,
                        ),
                      const Burbuja(
                        texto: 'Hola. Pregúntame sobre lo que observas en la ruta.',
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pregunta in preguntasSugeridas)
                      OutlinedButton(
                        onPressed: _chat.answering
                            ? null
                            : () => _ask(pregunta),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: Colores.superficie,
                          foregroundColor: tema.acento,
                          side: BorderSide(color: tema.acento, width: 2),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontFamily: Fuentes.cuerpo,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Text(pregunta),
                      ),
                  ],
                ),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (!_chat.answering) _ask();
                        },
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu pregunta',
                        ),
                      ),
                    ),
                    BotonPrincipal(
                      texto: _chat.answering ? 'Respondiendo…' : 'Enviar',
                      onPressed: _chat.answering ? null : _ask,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content() => switch (_chat.phase) {
    ChatPhase.checking => const [Center(child: CircularProgressIndicator())],
    ChatPhase.unsupported => const [],
    ChatPhase.noModel =>
      _chat.canDownload
          ? [
              const Linea(
                'Para preguntas que no estén en las fichas, la guía puede usar un modelo de IA de 584 MB. Descárgalo con wifi antes de subir.',
              ),
              BotonPrincipal(
                texto: _chat.error == null ? 'Descargar' : 'Reintentar',
                onPressed: _chat.download,
              ),
            ]
          : const [
              Linea(
                'El modelo no está instalado. Conéctate a la red de la estación y escanea el pase.',
              ),
            ],
    ChatPhase.downloading => [
      Linea('Descargando ${_chat.progress} %'),
      LinearProgressIndicator(value: _chat.progress / 100),
    ],
    ChatPhase.loading => const [
      Linea('Cargando el modelo…'),
      LinearProgressIndicator(),
    ],
    ChatPhase.ready => const [],
    ChatPhase.failed => [
      BotonSecundario(texto: 'Reintentar', onPressed: _chat.retry),
    ],
  };
}
