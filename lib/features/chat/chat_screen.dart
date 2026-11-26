import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_page.dart';
import '../../app/app_scope.dart';
import '../../core/ai/edge_llm_engine.dart';
import 'chat_controller.dart';
import 'reply_view.dart';

/// Controlador único de la app: la descarga sigue aunque se salga de la pantalla.
final chatDeLaApp = ChatController(EdgeLlmEngine());

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.controller});

  /// Solo se pasa en pruebas. La app usa uno compartido.
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
    // Después del primer cuadro: start() puede notificar de inmediato.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // En modo ahorro no se carga el modelo.
      if (mounted && !_batterySaver) _chat.start();
    });
  }

  bool get _batterySaver =>
      context.getInheritedWidgetOfExactType<AppScope>()?.settings.ahorroActivo ?? false;

  void _ask() => _chat.ask(
    _input.text,
    cards: context.getInheritedWidgetOfExactType<AppScope>()?.cards ?? const [],
    batterySaver: _batterySaver,
  );

  @override
  void dispose() {
    _input.dispose();
    // Al salir se recupera la memoria del modelo; vuelve a cargarse al entrar.
    _chat.enPantalla = false;
    unawaited(_chat.release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saver = AppScope.maybeOf(context)?.settings.ahorroActivo ?? false;
    return AppPage(
      title: 'Asistente',
      body: ListenableBuilder(
        listenable: _chat,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Experimental. Puede dar información falsa. '
              'En una emergencia usa Emergencias.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Tu pregunta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _chat.answering ? null : _ask,
              child: Text(_chat.answering ? 'Respondiendo…' : 'Preguntar'),
            ),
            const SizedBox(height: 16),
            if (_chat.reply case final reply?)
              ReplyView(reply: reply)
            else if (_chat.answer.isNotEmpty) ...[
              const Text('Respuesta del modelo, sin fuente verificada:'),
              Text(_chat.answer, style: const TextStyle(fontSize: 18)),
            ],
            const SizedBox(height: 16),
            if (saver)
              const Text('Modo ahorro: respondo solo con las fichas, sin modelo de IA.')
            else
              ..._content(),
            if (_chat.error != null) ...[
              const SizedBox(height: 16),
              Text(
                _chat.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _content() => switch (_chat.phase) {
    ChatPhase.checking => const [Center(child: CircularProgressIndicator())],
    ChatPhase.unsupported => const [],
    ChatPhase.noModel =>
      _chat.canDownload
          ? [
              const Text(
                'El asistente necesita descargar un modelo de 584 MB. '
                'Usa wifi.',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _chat.download,
                child: Text(_chat.error == null ? 'Descargar' : 'Reintentar'),
              ),
            ]
          : const [
              Text(
                'El modelo no está instalado. Conéctate a la red de la estación '
                'y escanea el pase.',
              ),
            ],
    ChatPhase.downloading => [
      Text('Descargando ${_chat.progress} %'),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: _chat.progress / 100),
    ],
    ChatPhase.loading => const [
      Text('Cargando el modelo…'),
      SizedBox(height: 8),
      LinearProgressIndicator(),
    ],
    ChatPhase.ready => const [Text('Modelo listo para preguntas que no estén en las fichas.')],
    ChatPhase.failed => [
      FilledButton(onPressed: _chat.retry, child: const Text('Reintentar')),
    ],
  };
}
