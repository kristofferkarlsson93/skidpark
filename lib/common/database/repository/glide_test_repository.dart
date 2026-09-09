import 'package:drift/drift.dart' as drift;
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/common/utils/device_info.dart';
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';

import '../database.dart';
import '../models/exported_glide_test.dart';

class GlideTestSummary {
  const GlideTestSummary({
    required this.test,
    required this.runCount,
    required this.testedSkiCount,
    required this.latestActivityAt,
  });

  final StoredGlideTestData test;
  final int runCount;
  final int testedSkiCount;
  final DateTime latestActivityAt;
}

class GlideTestRepository {
  final AppDatabase _db;

  GlideTestRepository(this._db);

  Stream<List<StoredGlideTestData>> watchTests() {
    return (_db.select(_db.storedGlideTest)..orderBy([
          (t) => drift.OrderingTerm.desc(t.id), // newest first
        ]))
        .watch();
  }

  Stream<List<GlideTestSummary>> watchTestSummaries() {
    final runCount = _db.testRun.id.count();
    final testedSkiCount = _db.testRun.skiId.count(distinct: true);
    final latestRunAt = _db.testRun.startedAt.max();
    final latestActivity = drift.ifNull(
      latestRunAt,
      _db.storedGlideTest.createdAt,
    );

    final query = _db.select(_db.storedGlideTest).join([
      drift.leftOuterJoin(
        _db.testRun,
        _db.testRun.glideTestId.equalsExp(_db.storedGlideTest.id),
        useColumns: false,
      ),
    ]);

    query
      ..addColumns([runCount, testedSkiCount, latestRunAt])
      ..groupBy([_db.storedGlideTest.id])
      ..orderBy([
        drift.OrderingTerm.desc(latestActivity),
        drift.OrderingTerm.desc(_db.storedGlideTest.createdAt),
      ]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final test = row.readTable(_db.storedGlideTest);
        return GlideTestSummary(
          test: test,
          runCount: row.read(runCount) ?? 0,
          testedSkiCount: row.read(testedSkiCount) ?? 0,
          latestActivityAt: row.read(latestRunAt) ?? test.createdAt,
        );
      }).toList(),
    );
  }

  Stream<StoredGlideTestData?> watchTestById(int glideTestId) {
    return (_db.select(
      _db.storedGlideTest,
    )..where((t) => t.id.equals(glideTestId))).watchSingleOrNull();
  }

  Future<int> create(GlideTestCandidate candidate) {
    final companion = StoredGlideTestCompanion(
      title: drift.Value(candidate.title),
      notes: drift.Value(candidate.notes),
    );

    return _db.into(_db.storedGlideTest).insert(companion);
  }

  Future<int> setUseSensorFusion(int id, bool shouldUseSensorFusion) {
    return (_db.update(
      _db.storedGlideTest,
    )..where((t) => t.id.equals(id))).write(
      StoredGlideTestCompanion(
        useSensorFusion: drift.Value(shouldUseSensorFusion),
      ),
    );
  }

  Future<int> update(int glideTestId, GlideTestCandidate updatedTest) {
    final companion = StoredGlideTestCompanion(
      title: drift.Value(updatedTest.title),
      notes: drift.Value(updatedTest.notes),
    );

    return (_db.update(
      _db.storedGlideTest,
    )..where((t) => t.id.equals(glideTestId))).write(companion);
  }

  void deleteGlideTest(int id) async {
    await (_db.delete(
      _db.storedGlideTest,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<ExportedGlideTest> exportRelatedData(int glideTestId) async {
    final test = await (_db.select(
      _db.storedGlideTest,
    )..where((t) => t.id.equals(glideTestId))).getSingle();

    final runs = await (_db.select(
      _db.testRun,
    )..where((r) => r.glideTestId.equals(glideTestId))).get();

    final skiIds = runs.map((r) => r.skiId).toSet();
    final skis = await (_db.select(
      _db.storedSki,
    )..where((s) => s.id.isIn(skiIds))).get();

    final decodedRuns = runs
        .map(
          (r) => TestRunRepository.decodeRun(
            r,
            skis.firstWhere((s) => s.id == r.skiId),
          ),
        )
        .toList();

    final deviceInfo = await getDeviceInfo();

    return ExportedGlideTest(
      test: test,
      runs: decodedRuns,
      skis: skis,
      deviceInfo: deviceInfo,
    );
  }
}
