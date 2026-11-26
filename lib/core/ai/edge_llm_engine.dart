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
    // También debe estar marcado como activo; el paquete lo recuerda entre reinicios.
    if (!await FlutterEdgeAi.isModelInstalled(_variant.file.installFilename) ||
        !FlutterEdgeAi.hasActiveModel()) {
      return false;
    }
    // Un archivo de otra versión o dañado se borra y cuenta como no instalado, para descargarlo de nuevo.
    try {
      await _verify();
      return true;
    } on CorruptModelException {
      return false;
    }
  }

  @override
  Stream<int> install({Uri? origen}) {
    final progress = StreamController<int>();
    Future<void> run() async {
      try {
        await _init();
        final builder = origen == null
            ? FlutterEdgeAi.installModelFromCatalog(_variant)
            : FlutterEdgeAi.installModel(
                modelType: _variant.modelType,
                fileType: ModelFileType.litertlm,
              ).fromNetwork(
                origen.toString(),
                filename: _variant.file.installFilename,
                expectedSize: _variant.file.sizeBytes,
              );
        await builder.withProgress(progress.add).install();
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
    await _verify();
    _model = await FlutterEdgeAi.getActiveModel(maxTokens: 2048, preferredBackend: PreferredBackend.cpu);
    await _removeOldModels();
  }

  Future<void> _verify() async {
    final file = _variant.file;
    await verifyModelFile(
      await FlutterEdgeAi.getModelPath(file.installFilename),
      file.sha256,
      onCorrupt: () => FlutterEdgeAi.uninstallModel(file.installFilename),
    );
  }

  /// Libera el espacio de modelos de versiones anteriores de la app, una vez que el actual cargó.
  Future<void> _removeOldModels() async {
    try {
      for (final id in await FlutterEdgeAi.listInstalledModels()) {
        if (id != _variant.file.installFilename) await FlutterEdgeAi.uninstallModel(id);
      }
    } catch (e) {
      debugPrint('No se pudo borrar un modelo anterior: $e');
    }
  }

  @override
  Future<void> unload() async {
    final model = _model;
    if (model == null) return;
    _model = null;
    await model.close();
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
