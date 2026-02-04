import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

Future<Map<String, dynamic>> getDeviceInfo() async {
  try {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final features = androidInfo.systemFeatures;
      return {
        'os': 'Android',
        'brand': androidInfo.brand,
        'model': androidInfo.model,
        'device': androidInfo.device,
        'version': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'chipset_info': {
          'hardware': androidInfo.hardware,
          'board': androidInfo.board,
        },

        'gps_capabilities': {
          'supportsRawGnss':
              features.contains('android.hardware.location') &&
              androidInfo.version.sdkInt >= 24,
        },
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return {
        'os': 'iOS',
        'name': iosInfo.name,
        'systemName': iosInfo.systemName,
        'systemVersion': iosInfo.systemVersion,
        'model': iosInfo.model,
      };
    }
    return {'os': 'unknown'};
  } catch (e) {
    return {'appVersion': 'unknown', 'error': e.toString()};
  }
}
