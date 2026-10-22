import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<Map<String, dynamic>> getDeviceInfo() async {
  final result = <String, dynamic>{'app': await _getAppInfo()};

  try {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      final features = androidInfo.systemFeatures;
      result.addAll({
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
      });
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      result.addAll({
        'os': 'iOS',
        'name': iosInfo.name,
        'systemName': iosInfo.systemName,
        'systemVersion': iosInfo.systemVersion,
        'model': iosInfo.model,
      });
    } else {
      result['os'] = 'unknown';
    }
  } catch (e) {
    result['deviceInfoError'] = e.toString();
  }

  return result;
}

Future<Map<String, dynamic>> _getAppInfo() async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'packageName': packageInfo.packageName,
    };
  } catch (e) {
    return {'version': 'unknown', 'error': e.toString()};
  }
}
