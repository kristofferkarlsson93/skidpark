import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:drift/drift.dart' as drift;

import '../../../features/glide_testing/models/decoded_test_run.dart';
import '../../../features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import '../../../features/glide_testing/test_runs/models/raw_barometer_event.dart';
import '../../../features/glide_testing/test_runs/models/raw_gps_event.dart';
import '../../../features/glide_testing/test_runs/models/raw_gyroscope_event.dart';
import '../../../features/glide_testing/test_runs/models/raw_rotation_vector_event.dart';
import '../../../features/glide_testing/test_runs/models/sensor_recording_metadata.dart';
import '../database.dart';

class TestRunRepository {
  final AppDatabase _db;

  TestRunRepository(this._db);

  Future<int> storeTestRun(TestRunCandidate testRunCandidate) async {
    final compressedGpsData = encodeGpsEvents(testRunCandidate.gpsEvents);
    final compressedAccelData = encodeAccelEvents(
      testRunCandidate.accelerometerEvents,
    );
    final compressedGyroscopeData = encodeGyroscopeEvents(
      testRunCandidate.gyroscopeEvents,
    );
    final compressedBarometerData = encodeBarometerEvents(
      testRunCandidate.barometerEvents,
    );
    final compressedRotationVectorData = encodeRotationVectorEvents(
      testRunCandidate.rotationVectorEvents,
    );
    final compressedSensorMetadata = encodeSensorMetadata(
      testRunCandidate.sensorMetadata,
    );

    return _db.transaction(() async {
      final runNumber = await _nextRunNumber(testRunCandidate.glideTestId);
      final companion = TestRunCompanion.insert(
        startedAt: testRunCandidate.startedAt,
        skiId: testRunCandidate.skiId,
        glideTestId: testRunCandidate.glideTestId,
        runNumber: drift.Value(runNumber),
        elapsedSeconds: testRunCandidate.elapsedSeconds,
        gpsData: compressedGpsData,
        accelerometerData: compressedAccelData,
        gyroscopeData: drift.Value(compressedGyroscopeData),
        barometerData: drift.Value(compressedBarometerData),
        rotationVectorData: drift.Value(compressedRotationVectorData),
        sensorMetadata: drift.Value(compressedSensorMetadata),
      );

      return _db.into(_db.testRun).insert(companion);
    });
  }

  Future<int> _nextRunNumber(int glideTestId) async {
    final maxRunNumber = _db.testRun.runNumber.max();
    final query = _db.selectOnly(_db.testRun)
      ..addColumns([maxRunNumber])
      ..where(_db.testRun.glideTestId.equals(glideTestId));
    final currentMax = await query
        .map((row) => row.read(maxRunNumber))
        .getSingle();
    return (currentMax ?? 0) + 1;
  }

  Stream<List<DecodedTestRun>> streamByGlideTest(int glideTestId) {
    final stream =
        (_db.select(_db.testRun).join([
                drift.innerJoin(
                  _db.storedSki,
                  _db.storedSki.id.equalsExp(_db.testRun.skiId),
                ),
              ])
              ..where(_db.testRun.glideTestId.equals(glideTestId))
              ..orderBy([
                drift.OrderingTerm(
                  expression: _db.testRun.runNumber,
                  mode: drift.OrderingMode.asc,
                ),
              ]))
            .watch();

    return stream.map((rows) {
      return rows.map((row) {
        final runData = row.readTable(_db.testRun);
        final skiData = row.readTable(_db.storedSki);

        return decodeRun(runData, skiData);
      }).toList();
    });
  }

  void deleteById(int testRunId) async {
    await (_db.delete(
      _db.testRun,
    )..where((tbl) => tbl.id.equals(testRunId))).go();
  }

  static DecodedTestRun decodeRun(TestRunData rawRun, StoredSkiData skiData) {
    final gpsEvents = decodeGpsEvents(rawRun.gpsData);

    final List<RawAccelerometerEvent> accelerometerEvents = _decodeAccelEvents(
      rawRun.accelerometerData,
    );
    final gyroscopeEvents = decodeGyroscopeEvents(rawRun.gyroscopeData);
    final barometerEvents = decodeBarometerEvents(rawRun.barometerData);
    final rotationVectorEvents = decodeRotationVectorEvents(
      rawRun.rotationVectorData,
    );
    final sensorMetadata = decodeSensorMetadata(rawRun.sensorMetadata);

    return DecodedTestRun(
      id: rawRun.id,
      startedAt: rawRun.startedAt,
      skiId: rawRun.skiId,
      glideTestId: rawRun.glideTestId,
      runNumber: rawRun.runNumber,
      elapsedSeconds: rawRun.elapsedSeconds,
      skiName: skiData.name,
      gpsEvents: gpsEvents,
      accelerometerEvents: accelerometerEvents,
      gyroscopeEvents: gyroscopeEvents,
      barometerEvents: barometerEvents,
      rotationVectorEvents: rotationVectorEvents,
      sensorMetadata: sensorMetadata,
    );
  }

  static List<RawGpsEvent> decodeGpsEvents(drift.Uint8List compressedData) {
    final jsonList = _decodeJson(compressedData) as List<dynamic>;

    return jsonList
        .map((jsonMap) => RawGpsEvent.fromJson(jsonMap as Map<String, dynamic>))
        .toList();
  }

  static List<RawAccelerometerEvent> _decodeAccelEvents(
    drift.Uint8List? compressedData,
  ) {
    if (compressedData == null || compressedData.isEmpty) {
      return [];
    }

    return _decodeEvents(compressedData, RawAccelerometerEvent.fromJson);
  }

  static drift.Uint8List encodeGpsPositions(List<Position> positions) {
    return encodeGpsEvents(
      positions.map((position) => RawGpsEvent.fromPosition(position)),
    );
  }

  static drift.Uint8List encodeGpsEvents(Iterable<RawGpsEvent> events) {
    return _encodeEvents(events.map((event) => event.toJson()));
  }

  static drift.Uint8List encodeAccelEvents(List<RawAccelerometerEvent> events) {
    return _encodeEvents(events.map((event) => event.toJson()));
  }

  static drift.Uint8List encodeGyroscopeEvents(List<RawGyroscopeEvent> events) {
    return _encodeEvents(events.map((event) => event.toJson()));
  }

  static List<RawGyroscopeEvent> decodeGyroscopeEvents(
    drift.Uint8List? compressedData,
  ) {
    return _decodeEvents(compressedData, RawGyroscopeEvent.fromJson);
  }

  static drift.Uint8List encodeBarometerEvents(List<RawBarometerEvent> events) {
    return _encodeEvents(events.map((event) => event.toJson()));
  }

  static List<RawBarometerEvent> decodeBarometerEvents(
    drift.Uint8List? compressedData,
  ) {
    return _decodeEvents(compressedData, RawBarometerEvent.fromJson);
  }

  static drift.Uint8List encodeRotationVectorEvents(
    List<RawRotationVectorEvent> events,
  ) {
    return _encodeEvents(events.map((event) => event.toJson()));
  }

  static List<RawRotationVectorEvent> decodeRotationVectorEvents(
    drift.Uint8List? compressedData,
  ) {
    return _decodeEvents(compressedData, RawRotationVectorEvent.fromJson);
  }

  static drift.Uint8List encodeSensorMetadata(
    SensorRecordingMetadata metadata,
  ) {
    return _encodeJson(metadata.toJson());
  }

  static SensorRecordingMetadata? decodeSensorMetadata(
    drift.Uint8List? compressedData,
  ) {
    if (compressedData == null || compressedData.isEmpty) return null;
    return SensorRecordingMetadata.fromJson(
      _decodeJson(compressedData) as Map<String, dynamic>,
    );
  }

  static drift.Uint8List _encodeEvents(Iterable<Map<String, dynamic>> events) {
    return _encodeJson(events.toList());
  }

  static List<T> _decodeEvents<T>(
    drift.Uint8List? compressedData,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (compressedData == null || compressedData.isEmpty) return [];
    final jsonList = _decodeJson(compressedData) as List<dynamic>;
    return jsonList
        .map((json) => fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static drift.Uint8List _encodeJson(Object value) {
    return GZipEncoder().encodeBytes(utf8.encode(jsonEncode(value)));
  }

  static Object? _decodeJson(drift.Uint8List compressedData) {
    final bytes = GZipDecoder().decodeBytes(compressedData.toList());
    return jsonDecode(utf8.decode(bytes));
  }
}
