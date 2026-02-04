import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/models/decoded_test_run.dart';

class ExportedGlideTest {
  final StoredGlideTestData test;
  final List<StoredSkiData> skis;
  final List<DecodedTestRun> runs;
  final Map<String, dynamic> deviceInfo;

  ExportedGlideTest({
    required this.test,
    required this.skis,
    required this.runs,
    required this.deviceInfo
  });

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
      'deviceInfo': deviceInfo,
      'exportedAt': DateTime.now().toIso8601String(),
      'glideTest': {
        'id': test.id,
        'title': test.title,
        'notes': test.notes,
        'createdAt': test.createdAt.toIso8601String(),
        'useSensorFusion': test.useSensorFusion,
      },
      'skis': skis
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'brandAndModel': s.brandAndModel,
              'technicalData': s.technicalData,
            },
          )
          .toList(),
      'runs': runs.map((r) {
        final ski = skis.firstWhere((s) => s.id == r.skiId);

        return {
          'id': r.id,
          'skiId': r.skiId,
          'skiName': ski.name,
          'startedAt': r.startedAt.toIso8601String(),
          'elapsedSeconds': r.elapsedSeconds,
          'gpsData': r.gpsData.map((data) => data.toJson()).toList(),
          'accelerometerData': base64.encode(
            TestRunRepository.encodeAccelEvents(r.accelerometerEvents),
          ),
        };
      }).toList(),
    };
  }
}
