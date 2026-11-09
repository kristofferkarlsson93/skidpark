import 'package:flutter/services.dart';

import '../../services/recording_display.dart';

class IosRecordingDisplay implements RecordingDisplay {
  static const _channel = MethodChannel(
    'com.skidpark.app/ios_recording_display',
  );

  @override
  Future<void> setKeepAwake(bool enabled) =>
      _channel.invokeMethod<void>('setKeepAwake', enabled);
}
