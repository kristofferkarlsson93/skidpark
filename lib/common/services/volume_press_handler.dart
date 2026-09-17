import 'dart:async';

import 'package:flutter/services.dart';

import 'volume_control.dart';

enum VolumeButton { up, down }

abstract interface class VolumeButtonInput {
  Stream<VolumeButton> get shortPressStream;

  Stream<VolumeButton> get longPressStream;

  void dispose();
}

class VolumePressHandler implements VolumeButtonInput {
  static const Duration _longPressThreshold = Duration(milliseconds: 500);

  final _shortPressController = StreamController<VolumeButton>.broadcast();
  final _longPressController = StreamController<VolumeButton>.broadcast();

  @override
  Stream<VolumeButton> get shortPressStream => _shortPressController.stream;

  @override
  Stream<VolumeButton> get longPressStream => _longPressController.stream;

  final Map<VolumeButton, DateTime> _keyDownTime = {};
  final Map<VolumeButton, Timer?> _activeTimers = {};

  VolumePressHandler() {
    VolumeControl.listenForVolumeKeys(_handleNativeEvent);
  }

  void _handleNativeEvent(MethodCall call) {
    final String downOrUp = call.arguments as String; // "down" or "up"
    final buttonId = downOrUp == 'down' ? VolumeButton.down : VolumeButton.up;

    var isKeyDown = call.method == 'onVolumePress';
    var isKeyUp = call.method == 'onVolumeRelease';
    if (isKeyDown) {
      if (_keyDownTime.containsKey(buttonId)) {
        return;
      }
      _keyDownTime[buttonId] = DateTime.now();
      _activeTimers[buttonId] = Timer(_longPressThreshold, () {
        _handleLongPress(buttonId);
      });
    } else if (isKeyUp) {
      _activeTimers[buttonId]?.cancel();
      _activeTimers.remove(buttonId);

      final keyDownTime = _keyDownTime.remove(buttonId);
      if (keyDownTime == null) return;

      final pressDuration = DateTime.now().difference(keyDownTime);

      if (pressDuration < _longPressThreshold) {
        _shortPressController.add(buttonId);
      }
    }
  }

  void _handleLongPress(VolumeButton button) {
    _activeTimers.remove(button);

    _longPressController.add(button);
  }

  @override
  void dispose() {
    _shortPressController.close();
    _longPressController.close();
    for (var timer in _activeTimers.values) {
      timer?.cancel();
    }
  }
}
