import 'dart:convert';
import 'package:skidpark/common/database/database.dart';

class ExportedGlideTest {
  final StoredGlideTestData test;
  final List<StoredSkiData> skis;
  final List<TestRunData> runs;

  ExportedGlideTest({
    required this.test,
    required this.skis,
    required this.runs,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': 1,
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
          'gpsData': base64Encode(r.gpsData),
          'accelerometerData': base64Encode(r.accelerometerData),
        };
      }).toList(),
    };
  }
}
