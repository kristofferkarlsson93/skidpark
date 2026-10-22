import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/import/glide_test_import_service.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_barometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gyroscope_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_rotation_vector_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/sensor_recording_metadata.dart';

void main() {
  test('preserves explicit run numbers from version 2 exports', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final testId = await GlideTestImportService(database).importJson(
      jsonEncode({
        'version': 2,
        'glideTest': {
          'title': 'Importerat test',
          'createdAt': '2026-09-15T12:00:00.000Z',
          'useSensorFusion': false,
        },
        'skis': [
          {'id': 10, 'name': 'SP1'},
        ],
        'runs': [
          {
            'id': 20,
            'runNumber': 2,
            'skiId': 10,
            'startedAt': '2026-09-15T12:01:00.000Z',
            'elapsedSeconds': 10,
            'gpsData': <Object>[],
          },
          {
            'id': 21,
            'runNumber': 4,
            'skiId': 10,
            'startedAt': '2026-09-15T12:02:00.000Z',
            'elapsedSeconds': 10,
            'gpsData': <Object>[],
          },
        ],
      }),
      asExample: false,
    );

    final runs = await TestRunRepository(database)
        .streamByGlideTest(testId)
        .first;
    expect(runs.map((run) => run.runNumber), [2, 4]);
  });

  test('imports version 3 sensor streams and metadata', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final timestamp = DateTime.utc(2026, 9, 17, 12);
    final gpsPoint = Position(
      longitude: 18,
      latitude: 59,
      timestamp: timestamp,
      accuracy: 2,
      altitude: 10,
      altitudeAccuracy: 3,
      heading: 0,
      headingAccuracy: 1,
      speed: 4,
      speedAccuracy: 0.5,
    ).toJson()..['receivedElapsedMicroseconds'] = 75;
    const metadata = SensorRecordingMetadata(
      streams: {
        'rotationVector': SensorStreamMetadata(
          source: 'flutter_rotation_sensor@0.4.0',
          unit: 'unit quaternion',
          coordinateFrame: 'device-to-world ENU',
          requestedSamplingPeriodMicroseconds: 20000,
          sampleCount: 1,
        ),
      },
    );

    final testId = await GlideTestImportService(database).importJson(
      jsonEncode({
        'version': 3,
        'glideTest': {
          'title': 'Instrumenterat test',
          'createdAt': '2026-09-17T12:00:00.000Z',
          'useSensorFusion': false,
        },
        'skis': [
          {'id': 10, 'name': 'SP1'},
        ],
        'runs': [
          {
            'id': 20,
            'runNumber': 1,
            'skiId': 10,
            'startedAt': '2026-09-17T12:01:00.000Z',
            'elapsedSeconds': 10,
            'gpsData': [gpsPoint],
            'sensorData': {
              'metadata': metadata.toJson(),
              'gyroscope': base64Encode(
                TestRunRepository.encodeGyroscopeEvents([
                  RawGyroscopeEvent(
                    x: 1,
                    y: 2,
                    z: 3,
                    sensorTimestamp: timestamp,
                    elapsedMicroseconds: 100,
                  ),
                ]),
              ),
              'barometer': base64Encode(
                TestRunRepository.encodeBarometerEvents([
                  RawBarometerEvent(
                    pressureHpa: 1001,
                    sensorTimestamp: timestamp,
                    elapsedMicroseconds: 110,
                  ),
                ]),
              ),
              'rotationVector': base64Encode(
                TestRunRepository.encodeRotationVectorEvents(const [
                  RawRotationVectorEvent(
                    x: 0,
                    y: 0,
                    z: 0,
                    w: 1,
                    accuracyRadians: -1,
                    sensorTimestampNanoseconds: 100000,
                    elapsedMicroseconds: 120,
                  ),
                ]),
              ),
            },
          },
        ],
      }),
      asExample: false,
    );

    final run = (await TestRunRepository(
      database,
    ).streamByGlideTest(testId).first).single;

    expect(run.gpsEvents.single.receivedElapsedMicroseconds, 75);
    expect(run.gyroscopeEvents.single.z, 3);
    expect(run.barometerEvents.single.pressureHpa, 1001);
    expect(run.rotationVectorEvents.single.w, 1);
    expect(run.sensorMetadata?.streams['rotationVector']?.sampleCount, 1);
  });
}
