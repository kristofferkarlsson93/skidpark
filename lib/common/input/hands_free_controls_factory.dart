import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/volume_press_handler.dart';
import '../services/recording_display.dart';
import 'android/android_volume_hands_free_input.dart';
import 'hands_free_input.dart';
import 'hands_free_controller.dart';
import 'ios/ios_motion_hands_free_input.dart';
import 'ios/ios_recording_display.dart';
import 'unsupported_hands_free_input.dart';

/// Platform selection lives here, rather than in screens or view-models.
class HandsFreeControlsFactory {
  HandsFreeControlsFactory({required this.platform, required this.volumeInput});

  final TargetPlatform platform;
  final VolumeButtonInput volumeInput;
  HandsFreeController? _controller;
  late final RecordingDisplay recordingDisplay =
      !kIsWeb && platform == TargetPlatform.iOS
      ? IosRecordingDisplay()
      : const SystemManagedRecordingDisplay();

  HandsFreeController get controller => _controller ??= HandsFreeController(
    input: createInput(),
    feedback: createFeedback(),
  );

  HandsFreeInstructions get instructions => switch (platform) {
    TargetPlatform.iOS when isSupported =>
      IosMotionHandsFreeInput.inputInstructions,
    TargetPlatform.android when isSupported =>
      AndroidVolumeHandsFreeInput.inputInstructions,
    _ => UnsupportedHandsFreeInput.inputInstructions,
  };

  Future<void> dispose() async => _controller?.dispose();

  bool get isSupported =>
      !kIsWeb &&
      (platform == TargetPlatform.iOS ||
          (platform == TargetPlatform.android &&
              volumeInput.supportsVolumeInput));

  HandsFreeInput createInput() => !isSupported
      ? UnsupportedHandsFreeInput()
      : switch (platform) {
          TargetPlatform.iOS => IosMotionHandsFreeInput(),
          TargetPlatform.android => AndroidVolumeHandsFreeInput(volumeInput),
          _ => UnsupportedHandsFreeInput(),
        };

  HandsFreeFeedback createFeedback() => platform == TargetPlatform.iOS
      ? IosSpokenHandsFreeFeedback()
      : _SystemHandsFreeFeedback();
}

class _SystemHandsFreeFeedback implements HandsFreeFeedback {
  int _generation = 0;

  @override
  Future<void> announce(String message) async {
    final generation = ++_generation;
    await HapticFeedback.mediumImpact();
    if (generation != _generation) return;
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  Future<void> stop() async {
    _generation++;
  }
}
