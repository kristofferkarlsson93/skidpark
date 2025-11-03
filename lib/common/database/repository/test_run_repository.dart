import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';
import 'package:drift/drift.dart' as drift;

import '../../../features/glide_testing/models/decoded_test_run.dart';
import '../database.dart';

class TestRunRepository {
  final AppDatabase _db;

  TestRunRepository(this._db);

  Future<int> storeTestRun(TestRunCandidate testRunCandidate) {
    drift.Uint8List compressedGpsData = _encodePositions(testRunCandidate);

    final companion = TestRunCompanion(
      startedAt: drift.Value(testRunCandidate.startedAt),
      skiId: drift.Value(testRunCandidate.skiId),
      glideTestId: drift.Value(testRunCandidate.glideTestId),
      elapsedSeconds: drift.Value(testRunCandidate.elapsedSeconds),
      gpsData: drift.Value(compressedGpsData),
    );

    return _db.into(_db.testRun).insert(companion);
  }

  Stream<List<DecodedTestRun>> streamByGlideTest(int glideTestId) {
    final rawRunStream =
        (_db.select(_db.testRun)
              ..where((tbl) => tbl.glideTestId.equals(glideTestId))
              ..orderBy([
                (tbl) => drift.OrderingTerm(
                  expression: tbl.id,
                  mode: drift.OrderingMode.asc,
                ),
              ]))
            .watch();

    return rawRunStream.map((rawRunList) {
      return rawRunList.map((rawRun) {
        return _decodeRun(rawRun);
      }).toList();
    });
  }

  DecodedTestRun _decodeRun(TestRunData rawRun) {
    final gzipDecoder = GZipDecoder();
    final decompressedBytes = gzipDecoder.decodeBytes(rawRun.gpsData);

    final jsonString = utf8.decode(decompressedBytes);

    final List<dynamic> jsonList = jsonDecode(jsonString);


    final List<Position> positions = jsonList
        .map((jsonMap) => Position.fromMap(jsonMap as Map<String, dynamic>))
        .toList();

    return DecodedTestRun(
      rawRun.id,
      rawRun.startedAt,
      rawRun.skiId,
      rawRun.glideTestId,
      rawRun.elapsedSeconds,
      positions,
    );
  }

  // To save some space when storing.
  drift.Uint8List _encodePositions(TestRunCandidate testRunCandidate) {
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
}
