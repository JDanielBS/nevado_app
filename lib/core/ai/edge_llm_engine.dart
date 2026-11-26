import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

import 'device_support.dart';
import 'llm_engine.dart';
import 'model_integrity.dart';

/// Motor sobre `flutter_edge_ai`. Único archivo que importa el paquete.
class EdgeLlmEngine implements LlmEngine {
  // Solo para desarrollo: el token queda dentro del APK.
  static const _token = String.fromEnvironment('HUGGINGFACE_TOKEN');

  final _variant = LiteRtLmModels.gemma3_1bIt.q4Ekv4096;
  Future<void>? _initialized;
  InferenceModel? _model;

  @override
  bool get canDownload => _token.isNotEmpty;

  @override
  String? unsupportedReason() {
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    var memInfo = '';
    if (android) {
      try {
        memInfo = File('/proc/meminfo').readAsStringSync();
      } on FileSystemException catch (e) {
        debugPrint('No se pudo leer la memoria: $e');
      }
    }
    return supportReason(
      androidArm64: android && Platform.version.contains('android_arm64'),
      memInfo: memInfo,
    );
  }

  Future<void> _init() => _initialized ??= FlutterEdgeAi.initialize(
    inferenceEngines: const [LiteRtLmEngine()],
    huggingFaceToken: canDownload ? _token : null,
  );

  @override
  Future<bool> isInstalled() async {
    await _init();
    return FlutterEdgeAi.isModelInstalled(_variant.file.installFilename);
  }

  @override
  Stream<int> install() {
    final progress = StreamController<int>();
    Future<void> run() async {
      try {
        await _init();
        await FlutterEdgeAi.installModelFromCatalog(
          _variant,
        ).withProgress(progress.add).install();
      } catch (e, s) {
        progress.addError(e, s);
      } finally {
        await progress.close();
      }
    }

    unawaited(run());
    return progress.stream;
  }

  @override
  Future<void> load() async {
    if (_model != null) return;
    await _init();
    final file = _variant.file;
    await verifyModelFile(
      await FlutterEdgeAi.getModelPath(file.installFilename),
      file.sha256,
      onCorrupt: () => FlutterEdgeAi.uninstallModel(file.installFilename),
    );
    // Con el archivo ya instalado no descarga: solo lo marca como activo.
    await FlutterEdgeAi.installModelFromCatalog(_variant).install();
    _model = await FlutterEdgeAi.getActiveModel(
      maxTokens: 2048,
      preferredBackend: PreferredBackend.cpu,
    );
  }

  @override
  Stream<String> generate(String prompt) async* {
    final chat = await _model!.openChat(topK: 1, maxOutputTokens: 150);
    try {
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) yield response.token;
      }
    } finally {
      await chat.close();
    }
  }
}
