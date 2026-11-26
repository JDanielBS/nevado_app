import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/ai/edge_llm_engine.dart';
import '../../core/content/card.dart';
import '../../core/ui/palette.dart';
import '../../core/ui/widgets.dart';
import '../../core/voice/device_tts.dart';
import 'chat_controller.dart';
import 'reply_view.dart';
import 'voice_chat_controller.dart';
import 'voice_controls.dart';

/// Controlador único de la app: la descarga sigue aunque se salga de la pantalla.
final chatDeLaApp = ChatController(EdgeLlmEngine());

/// Voz de la Guía IA, sobre el mismo asistente.
final chatDeVozDeLaApp = VoiceChatController(chatDeLaApp, crearMotorDeVoz());

/// Preguntas sugeridas bajo la conversación.
const preguntasSugeridas = ['¿Puedo ir al cráter?', 'Me duele la cabeza', '¿Puedo llevarme una roca?'];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.controller, this.voz});

  /// Solo se pasan en pruebas. La app usa unos compartidos; con solo [controller] no hay voz.
  final ChatController? controller;
  final VoiceChatController? voz;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final VoiceChatController? _voz = widget.voz ?? (widget.controller == null ? chatDeVozDeLaApp : null);
  late final ChatController _chat = widget.controller ?? _voz?.chat ?? chatDeLaApp;
  final _input = TextEditingController();

  /// La voz está permitida: activada en ajustes y sin modo ahorro.
  bool? _vozPermitida;

  @override
  void initState() {
    super.initState();
    // Después del primer cuadro: start() puede notificar de inmediato, y si se viene de
    // otra pantalla del asistente, esta ya habrá soltado el modelo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chat.enPantalla = true;
      // En modo ahorro no se carga el modelo.
      if (!_batterySaver) _chat.start();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final voz = _voz;
    if (voz == null) return;
    final settings = AppScope.maybeOf(context)?.settings;
    final permitida = settings == null || (settings.vozActiva && !settings.ahorroActivo);
    if (permitida == _vozPermitida) return;
    _vozPermitida = permitida;
    // Después del cuadro: ambos pueden notificar de inmediato.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      voz.enPantalla = true;
      // Sin permiso no se carga el modelo de voz, y si estaba cargado se libera.
      unawaited(_vozPermitida! ? voz.start() : voz.release());
    });
  }

  bool get _batterySaver => context.getInheritedWidgetOfExactType<AppScope>()?.settings.ahorroActivo ?? false;

  void _ask([String? texto]) {
    final pregunta = texto ?? _input.text;
    final cards = context.getInheritedWidgetOfExactType<AppScope>()?.cards ?? const <Ficha>[];
    final voz = _voz;
    if (voz == null) {
      _chat.ask(pregunta, cards: cards, batterySaver: _batterySaver);
    } else {
      voz.ask(pregunta, cards: cards, batterySaver: _batterySaver, permitida: _vozPermitida ?? false);
    }
    if (texto == null) _input.clear();
  }

  @override
  void dispose() {
    _input.dispose();
    // Al salir se recupera la memoria del modelo; vuelve a cargarse al entrar.
    _chat.enPantalla = false;
    unawaited(_chat.release());
    final voz = _voz;
    if (voz != null) {
      voz.enPantalla = false;
      // Sin avisar mientras se desmonta la pantalla.
      scheduleMicrotask(() => unawaited(voz.release()));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = TemaScope.of(context);
    final saver = AppScope.maybeOf(context)?.settings.ahorroActivo ?? false;
    // Material propio: la pantalla también se muestra sola (pruebas) y el campo de texto lo necesita.
    return Material(
      type: MaterialType.transparency,
      child: ListenableBuilder(
        listenable: Listenable.merge([_chat, _voz]),
        builder: (context, _) {
          final estado = [
            if (_voz case final voz?) PanelDeVoz(voz: voz, permitida: _vozPermitida ?? false),
            if (saver)
              const Linea('Modo ahorro: respondo solo con las fichas, sin modelo de IA.')
            else
              ..._content(),
            if (_chat.error != null) Linea(_chat.error!, color: Colores.aviso, negrita: true),
          ];
          final turnos = _chat.turnos;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colores.superficie,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tema.acento, width: 2),
                  ),
                  child: const Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Guía virtual · sin conexión\n', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(
                        text: 'Experimental: puede equivocarse. Responde con las fichas del parque y '
                            'no informa el estado actual del volcán.',
                      ),
                    ]),
                    style: TextStyle(fontSize: 14, height: 1.35, color: Colores.texto),
                  ),
                ),
                Expanded(
                  // Invertida para que lo más reciente quede abajo, junto al campo de texto.
                  child: ListView(
                    reverse: true,
                    children: [
                      if (estado.isNotEmpty)
                        Caja(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 8, children: estado),
                        ),
                      for (final (i, turno) in turnos.indexed.toList().reversed) ...[
                        // La lista está invertida: el pie va antes para quedar debajo.
                        if (_voz case final voz? when _vozPermitida ?? false) BotonDeVoz(voz: voz, turno: turno),
                        TurnoView(turno: turno, respondiendo: _chat.answering && i == turnos.length - 1),
                      ],
                      const Burbuja(texto: 'Hola. Pregúntame sobre lo que observas en la ruta.'),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pregunta in preguntasSugeridas)
                      OutlinedButton(
                        onPressed: _chat.answering ? null : () => _ask(pregunta),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          backgroundColor: Colores.superficie,
                          foregroundColor: tema.acento,
                          side: BorderSide(color: tema.acento, width: 2),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(fontFamily: Fuentes.cuerpo, fontSize: 13, fontWeight: FontWeight.w700),
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
                        decoration: const InputDecoration(hintText: 'Escribe tu pregunta'),
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
        ChatPhase.noModel => _chat.canDownload
            ? [
                const Linea('Para preguntas que no estén en las fichas, la guía puede usar un modelo de IA de 584 MB. '
                    'Descárgalo con wifi antes de subir.'),
                BotonPrincipal(
                  texto: _chat.error == null ? 'Descargar' : 'Reintentar',
                  onPressed: _chat.download,
                ),
              ]
            : const [
                Linea('El modelo no está instalado. Conéctate a la red de la estación y escanea el pase.'),
              ],
        ChatPhase.downloading => [
            Linea('Descargando ${_chat.progress} %'),
            LinearProgressIndicator(value: _chat.progress / 100),
          ],
        ChatPhase.loading => const [Linea('Cargando el modelo…'), LinearProgressIndicator()],
        ChatPhase.ready => const [],
        ChatPhase.failed => [BotonSecundario(texto: 'Reintentar', onPressed: _chat.retry)],
      };
}
