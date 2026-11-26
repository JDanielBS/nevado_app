import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_player_output.dart';
import 'local_tts_engine.dart';
import 'sherpa_synth.dart';
import 'voice_installer.dart';

/// Motor de voz del teléfono.
LocalTtsEngine crearMotorDeVoz() => LocalTtsEngine(
      installer: VoiceInstaller(
        base: () async => Directory('${(await getApplicationSupportDirectory()).path}/voz'),
      ),
      synth: SherpaSynth(),
      output: AudioPlayerOutput(),
      compatible: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    );
