import 'package:flutter/services.dart';

class VolumeControl {
  static const platform = MethodChannel('com.skidpark.app/volume_key');

  static void listenForVolumeKeys(Function(MethodCall call) callback) {
    platform.setMethodCallHandler((MethodCall call) async {
      callback(call);
      return null;
    });
  }
}
