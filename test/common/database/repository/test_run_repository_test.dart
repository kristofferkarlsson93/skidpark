import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_barometer_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gps_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_gyroscope_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/raw_rotation_vector_event.dart';
import 'package:skidpark/features/glide_testing/test_runs/models/sensor_recording_metadata.dart';

void main() {
  late AppDatabase database;
  late TestRunRepository repository;
  late int skiId;
  late int firstTestId;
  late int secondTestId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = TestRunRepository(database);
    skiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    firstTestId = await database
        .into(database.storedGlideTest)
        .insert(StoredGlideTestCompanion.insert(title: 'Första testet'));
    secondTestId = await database
        .into(database.storedGlideTest)
        .insert(StoredGlideTestCompanion.insert(title: 'Andra testet'));
  });

  tearDown(() => database.close());

  test('assigns stable sequential run numbers within each test', () async {
    final firstRunId = await repository.storeTestRun(
      _candidate(firstTestId, skiId),
    );
    await repository.storeTestRun(_candidate(secondTestId, skiId));
    await repository.storeTestRun(_candidate(firstTestId, skiId));

    var firstTestRuns = await repository.streamByGlideTest(firstTestId).first;
    final secondTestRuns = await repository
        .streamByGlideTest(secondTestId)
        .first;
    expect(firstTestRuns.map((run) => run.runNumber), [1, 2]);
    expect(secondTestRuns.map((run) => run.runNumber), [1]);

    await (database.delete(
      database.testRun,
    )..where((run) => run.id.equals(firstRunId))).go();
    await repository.storeTestRun(_candidate(firstTestId, skiId));

    firstTestRuns = await repository.streamByGlideTest(firstTestId).first;
    expect(firstTestRuns.map((run) => run.runNumber), [2, 3]);
  });

  test('round-trips extended raw sensor streams and metadata', () async {
    final timestamp = DateTime.utc(2026, 9, 17, 12);
    const metadata = SensorRecordingMetadata(
      streams: {
        'gyroscope': SensorStreamMetadata(
          source: 'sensors_plus@7.1.0',
          unit: 'rad/s',
          coordinateFrame: 'device',
          requestedSamplingPeriodMicroseconds: 20000,
          sampleCount: 1,
        ),
      },
    );
    await repository.storeTestRun(
      _candidate(
        firstTestId,
        skiId,
        gpsEvents: [
          RawGpsEvent.fromPosition(
            _position(timestamp),
            receivedElapsedMicroseconds: 90,
          ),
        ],
        gyroscopeEvents: [
          RawGyroscopeEvent(
            x: 1,
            y: 2,
            z: 3,
            sensorTimestamp: timestamp,
            elapsedMicroseconds: 100,
          ),
        ],
        barometerEvents: [
          RawBarometerEvent(
            pressureHpa: 998.2,
            sensorTimestamp: timestamp,
            elapsedMicroseconds: 110,
          ),
        ],
        rotationVectorEvents: const [
          RawRotationVectorEvent(
            x: 0,
            y: 0,
            z: 0,
            w: 1,
            accuracyRadians: 0.1,
            sensorTimestampNanoseconds: 123456,
            elapsedMicroseconds: 120,
          ),
        ],
        sensorMetadata: metadata,
      ),
    );

    final run = (await repository.streamByGlideTest(firstTestId).first).single;

    expect(run.gpsData.single.timestamp, timestamp);
    expect(run.gpsEvents.single.receivedElapsedMicroseconds, 90);
    expect(run.gyroscopeEvents.single.x, 1);
    expect(run.gyroscopeEvents.single.sensorTimestamp, timestamp);
    expect(run.barometerEvents.single.pressureHpa, 998.2);
    expect(run.rotationVectorEvents.single.w, 1);
    expect(run.rotationVectorEvents.single.sensorTimestampNanoseconds, 123456);
    expect(run.sensorMetadata?.streams['gyroscope']?.sampleCount, 1);

    final glideTestRepository = GlideTestRepository(database);
    await glideTestRepository.addSkiToTest(firstTestId, skiId);
    final export = await glideTestRepository.exportRelatedData(firstTestId);
    final exportJson = export.toJson();
    final exportedRun =
        (exportJson['runs'] as List<dynamic>).single as Map<String, dynamic>;
    final sensorData = exportedRun['sensorData'] as Map<String, dynamic>;
    final exportedGps =
        (exportedRun['gpsData'] as List<dynamic>).single
            as Map<String, dynamic>;
    expect(exportJson['version'], 3);
    expect(exportedGps['receivedElapsedMicroseconds'], 90);
    expect(sensorData['gyroscope'], isA<String>());
    expect(sensorData['barometer'], isA<String>());
    expect(sensorData['rotationVector'], isA<String>());
    expect(
      (sensorData['metadata'] as Map<String, dynamic>)['formatVersion'],
      1,
    );
  });
}

TestRunCandidate _candidate(
  int testId,
  int skiId, {
  List<RawGpsEvent> gpsEvents = const [],
  List<RawGyroscopeEvent> gyroscopeEvents = const [],
  List<RawBarometerEvent> barometerEvents = const [],
  List<RawRotationVectorEvent> rotationVectorEvents = const [],
  SensorRecordingMetadata sensorMetadata = const SensorRecordingMetadata(
    streams: {},
  ),
}) {
  return TestRunCandidate(
    startedAt: DateTime(2026, 9, 15),
    skiId: skiId,
    glideTestId: testId,
    elapsedSeconds: 10,
    gpsEvents: gpsEvents,
    accelerometerEvents: const [],
    gyroscopeEvents: gyroscopeEvents,
    barometerEvents: barometerEvents,
    rotationVectorEvents: rotationVectorEvents,
    sensorMetadata: sensorMetadata,
  );
}

Position _position(DateTime timestamp) {
  return Position(
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
  );
}
