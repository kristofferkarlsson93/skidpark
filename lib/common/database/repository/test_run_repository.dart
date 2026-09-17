import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:drift/drift.dart' as drift;

import '../../../features/glide_testing/models/decoded_test_run.dart';
import '../../../features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import '../database.dart';

class TestRunRepository {
  final AppDatabase _db;

  TestRunRepository(this._db);

  Future<int> storeTestRun(TestRunCandidate testRunCandidate) async {
    final compressedGpsData = encodeGpsPositions(testRunCandidate.gpsData);
    final compressedAccelData = encodeAccelEvents(
      testRunCandidate.accelerometerEvents,
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
    final List<Position> positions = _decodeGpsPositions(rawRun.gpsData);

    final List<RawAccelerometerEvent> accelerometerEvents = _decodeAccelEvents(
      rawRun.accelerometerData,
    );

    return DecodedTestRun(
      rawRun.id,
      rawRun.startedAt,
      rawRun.skiId,
      rawRun.glideTestId,
      rawRun.runNumber,
      rawRun.elapsedSeconds,
      skiData.name,
      positions,
      accelerometerEvents,
    );
  }

  static List<Position> _decodeGpsPositions(drift.Uint8List compressedData) {
    final gzipDecoder = GZipDecoder();
    final decompressedBytes = gzipDecoder.decodeBytes(compressedData.toList());

    final jsonString = utf8.decode(decompressedBytes);

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((jsonMap) => Position.fromMap(jsonMap as Map<String, dynamic>))
        .toList();
  }

  static List<RawAccelerometerEvent> _decodeAccelEvents(
    drift.Uint8List? compressedData,
  ) {
    if (compressedData == null || compressedData.isEmpty) {
      return [];
    }

    final gzipDecoder = GZipDecoder();
    final decompressedBytes = gzipDecoder.decodeBytes(compressedData.toList());

    final jsonString = utf8.decode(decompressedBytes);

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map(
          (jsonMap) =>
              RawAccelerometerEvent.fromJson(jsonMap as Map<String, dynamic>),
        )
        .toList();
  }

  // Save space in storage
  static drift.Uint8List encodeGpsPositions(List<Position> positions) {
    final List<Map<String, dynamic>> positionListAsMap = positions
        .map((pos) => pos.toJson())
        .toList();
    final String gpsDataJsonString = jsonEncode(positionListAsMap);
    final gpsDataBytes = utf8.encode(gpsDataJsonString);

    final gzipEncoder = GZipEncoder();
    final drift.Uint8List compressedGpsData = gzipEncoder.encodeBytes(
      gpsDataBytes,
    );
    return compressedGpsData;
  }

  // Save space in storage
  static drift.Uint8List encodeAccelEvents(
    List<RawAccelerometerEvent> accelEvents,
  ) {
    final List<Map<String, dynamic>> accelListAsMap = accelEvents
        .map((event) => event.toJson())
        .toList();
    final String accelDataJsonString = jsonEncode(accelListAsMap);
    final accelDataBytes = utf8.encode(accelDataJsonString);

    final gzipEncoder = GZipEncoder();
    final drift.Uint8List compressedAccelData = gzipEncoder.encodeBytes(
      accelDataBytes,
    );
    return compressedAccelData;
  }
}
