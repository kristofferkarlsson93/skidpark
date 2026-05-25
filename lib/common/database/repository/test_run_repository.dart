import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:drift/drift.dart' as drift;
import 'package:skidpark/features/glide_testing/test_runs/models/raw_barometer_event.dart';

import '../../../features/glide_testing/models/decoded_test_run.dart';
import '../../../features/glide_testing/test_runs/models/raw_accelerometer_event.dart';
import '../database.dart';

class TestRunRepository {
  final AppDatabase _db;

  TestRunRepository(this._db);

  Future<int> storeTestRun(TestRunCandidate testRunCandidate) async {

    final currentMaxRunNumber = await (_db.select(_db.testRun)
      ..where((tbl) => tbl.glideTestId.equals(testRunCandidate.glideTestId))
      ..orderBy([
            (tbl) => drift.OrderingTerm(
            expression: tbl.runNumber, mode: drift.OrderingMode.desc)
      ])
      ..limit(1))
        .getSingleOrNull();

    final nextRunNumber = (currentMaxRunNumber?.runNumber ?? 0) + 1;

    drift.Uint8List compressedGpsData = _encodeGpsPositions(testRunCandidate);
    drift.Uint8List compressedAccelData = encodeAccelEvents(
      testRunCandidate.accelerometerEvents,
    );
    drift.Uint8List compressedBarometerData = encodeBarometerEvents(
      testRunCandidate.barometerEvents,
    );

    final companion = TestRunCompanion(
      startedAt: drift.Value(testRunCandidate.startedAt),
      skiId: drift.Value(testRunCandidate.skiId),
      glideTestId: drift.Value(testRunCandidate.glideTestId),
      elapsedSeconds: drift.Value(testRunCandidate.elapsedSeconds),
      gpsData: drift.Value(compressedGpsData),
      accelerometerData: drift.Value(compressedAccelData),
      barometerData: drift.Value(compressedBarometerData),
      runNumber: drift.Value(nextRunNumber),
    );

    return _db.into(_db.testRun).insert(companion);
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
                  expression: _db.testRun.id,
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
    await (_db.delete(_db.testRun)
      ..where((tbl) => tbl.id.equals(testRunId))
    ).go();
  }

  static DecodedTestRun decodeRun(TestRunData rawRun, StoredSkiData skiData) {
    final List<Position> positions = _decodeGpsPositions(rawRun.gpsData);

    final List<RawAccelerometerEvent> accelerometerEvents = _decodeAccelEvents(
      rawRun.accelerometerData,
    );

    List<RawBarometerEvent>? barometerEvents = _decodeBarometerEvents(rawRun.barometerData);

    return DecodedTestRun(
      rawRun.id,
      rawRun.runNumber,
      rawRun.startedAt,
      rawRun.skiId,
      rawRun.glideTestId,
      rawRun.elapsedSeconds,
      skiData.name,
      positions,
      accelerometerEvents,
      barometerEvents
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

  static List<RawBarometerEvent>? _decodeBarometerEvents(
      drift.Uint8List? compressedData,
      ) {
    if (compressedData == null || compressedData.isEmpty) {
      return null;
    }

    final gzipDecoder = GZipDecoder();
    final decompressedBytes = gzipDecoder.decodeBytes(compressedData.toList());

    final jsonString = utf8.decode(decompressedBytes);

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map(
          (jsonMap) =>
          RawBarometerEvent.fromJson(jsonMap as Map<String, dynamic>),
    )
        .toList();
  }


  // Save space in storage
  drift.Uint8List _encodeGpsPositions(TestRunCandidate testRunCandidate) {
    final List<Map<String, dynamic>> positionListAsMap = testRunCandidate
        .gpsData
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

  static drift.Uint8List encodeBarometerEvents(
    List<RawBarometerEvent> barometerEvents,
  ) {
    final List<Map<String, dynamic>> barometerListAsMap = barometerEvents
        .map((event) => event.toJson())
        .toList();
    final String barometerDataJsonString = jsonEncode(barometerListAsMap);
    final barometerDataBytes = utf8.encode(barometerDataJsonString);

    final gzipEncoder = GZipEncoder();
    final drift.Uint8List compressedBarometerData = gzipEncoder.encodeBytes(
      barometerDataBytes,
    );
    return compressedBarometerData;
  }
}
