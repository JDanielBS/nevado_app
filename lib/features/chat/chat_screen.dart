import 'package:flutter/material.dart';

import '../../core/ai/edge_llm_engine.dart';
import 'chat_controller.dart';

final _appController = ChatController(EdgeLlmEngine());

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.controller});

  /// Solo se pasa en pruebas. La app usa uno compartido.
  final ChatController? controller;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _chat = widget.controller ?? _appController;
  final _input = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Después del primer cuadro: start() puede notificar de inmediato.
    WidgetsBinding.instance.addPostFrameCallback((_) => _chat.start());
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente')),
      body: SafeArea(
        child: ListenableBuilder(
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
      ),
    );
  }

  List<Widget> _content() => switch (_chat.phase) {
    ChatPhase.checking => const [Center(child: CircularProgressIndicator())],
    ChatPhase.unsupported => const [],
    ChatPhase.noModel =>
      _chat.engine.canDownload
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
                'Falta HUGGINGFACE_TOKEN. Compila con '
                '--dart-define-from-file=.env (ver README).',
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
    ChatPhase.ready => [
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
        onPressed: _chat.answering ? null : () => _chat.ask(_input.text),
        child: Text(_chat.answering ? 'Respondiendo…' : 'Preguntar'),
      ),
      const SizedBox(height: 16),
      SelectableText(_chat.answer, style: const TextStyle(fontSize: 18)),
    ],
    ChatPhase.failed => [
      FilledButton(onPressed: _chat.retry, child: const Text('Reintentar')),
    ],
  };
}
