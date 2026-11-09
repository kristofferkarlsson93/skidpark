import 'dart:convert';

import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/models/decoded_test_run.dart';

class ExportedGlideTest {
  final StoredGlideTestData test;
  final List<StoredSkiData> skis;
  final List<int> selectedSkiIds;
  final List<DecodedTestRun> runs;
  final Map<String, dynamic> deviceInfo;

  ExportedGlideTest({
    required this.test,
    required this.skis,
    required this.runs,
    required this.deviceInfo,
    required this.selectedSkiIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'version': 3,
      // Related skis also include historical runs' skis that are no longer selected.
      'selectedSkiIds': selectedSkiIds,
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
          'runNumber': r.runNumber,
          'skiId': r.skiId,
          'skiName': ski.name,
          'startedAt': r.startedAt.toIso8601String(),
          'elapsedSeconds': r.elapsedSeconds,
          'gpsData': r.gpsEvents.map((event) => event.toJson()).toList(),
          'accelerometerData': base64.encode(
            TestRunRepository.encodeAccelEvents(r.accelerometerEvents),
          ),
          'sensorData': {
            'metadata': r.sensorMetadata?.toJson(),
            'gyroscope': base64.encode(
              TestRunRepository.encodeGyroscopeEvents(r.gyroscopeEvents),
            ),
            'barometer': base64.encode(
              TestRunRepository.encodeBarometerEvents(r.barometerEvents),
            ),
            'rotationVector': base64.encode(
              TestRunRepository.encodeRotationVectorEvents(
                r.rotationVectorEvents,
              ),
            ),
          },
        };
      }).toList(),
    };
  }
}
