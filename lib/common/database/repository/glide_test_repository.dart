import 'package:drift/drift.dart' as drift;
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';

import '../database.dart';
import '../models/exported_glide_test.dart';

class GlideTestRepository {
  final AppDatabase _db;

  GlideTestRepository(this._db);

  Stream<List<StoredGlideTestData>> watchTests() {
    return (_db.select(_db.storedGlideTest)..orderBy([
          (t) => drift.OrderingTerm.desc(t.id), // newest first
        ]))
        .watch();
  }

  Stream<StoredGlideTestData> watchTestById(int glideTestId) {
    return (_db.select(
      _db.storedGlideTest,
    )..where((t) => t.id.equals(glideTestId))).watchSingle();
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

    return ExportedGlideTest(test: test, runs: runs, skis: skis);
  }
}
