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
    final runCount = _db.testRun.id.count(distinct: true);
    final selectedSkiCount = _db.glideTestSki.skiId.count(distinct: true);
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
      drift.leftOuterJoin(
        _db.glideTestSki,
        _db.glideTestSki.glideTestId.equalsExp(_db.storedGlideTest.id),
        useColumns: false,
      ),
    ]);

    query
      ..addColumns([runCount, selectedSkiCount, latestRunAt])
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
          testedSkiCount: row.read(selectedSkiCount) ?? 0,
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

  Future<StoredGlideTestData?> getTestById(int glideTestId) {
    return (_db.select(
      _db.storedGlideTest,
    )..where((test) => test.id.equals(glideTestId))).getSingleOrNull();
  }

  Stream<List<StoredSkiData>> watchSkisForTest(int glideTestId) {
    final query =
        _db.select(_db.storedSki).join([
            drift.innerJoin(
              _db.glideTestSki,
              _db.glideTestSki.skiId.equalsExp(_db.storedSki.id),
              useColumns: false,
            ),
          ])
          ..where(
            _db.glideTestSki.glideTestId.equals(glideTestId) &
                _db.storedSki.archivedAt.isNull(),
          )
          ..orderBy([drift.OrderingTerm.asc(_db.glideTestSki.sortOrder)]);

    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(_db.storedSki)).toList(),
    );
  }

  Future<List<int>> getSkiIdsForTest(int glideTestId) async {
    final query = _db.select(_db.glideTestSki)
      ..where((relation) => relation.glideTestId.equals(glideTestId))
      ..orderBy([(relation) => drift.OrderingTerm.asc(relation.sortOrder)]);

    return (await query.get()).map((relation) => relation.skiId).toList();
  }

  Future<List<int>> getLatestRealTestSkiIds() async {
    final latestTestQuery = _db.select(_db.storedGlideTest)
      ..where((test) => test.isExample.equals(false))
      ..orderBy([
        (test) => drift.OrderingTerm.desc(test.createdAt),
        (test) => drift.OrderingTerm.desc(test.id),
      ])
      ..limit(1);
    final latestTest = await latestTestQuery.getSingleOrNull();
    if (latestTest == null) return const [];

    return getSkiIdsForTest(latestTest.id);
  }

  Future<int> createTestWithSkis(GlideTestCandidate candidate) {
    return _db.transaction(() async {
      final skiIds = await _validateRealSkiIds(candidate.skiIds);
      final testId = await _db
          .into(_db.storedGlideTest)
          .insert(
            StoredGlideTestCompanion(
              title: drift.Value(candidate.title),
              notes: drift.Value(candidate.notes),
            ),
          );
      await _insertSkiRelations(testId, skiIds);
      return testId;
    });
  }

  Future<int> create(GlideTestCandidate candidate) {
    return createTestWithSkis(candidate);
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

  Future<void> update(int glideTestId, GlideTestCandidate updatedTest) {
    return _db.transaction(() async {
      final test = await getTestById(glideTestId);
      if (test == null) throw StateError('The glide test no longer exists.');
      if (test.isExample) {
        throw StateError('Example tests cannot be changed.');
      }
      final skiIds = await _validateRealSkiIds(updatedTest.skiIds);
      await (_db.update(
        _db.storedGlideTest,
      )..where((test) => test.id.equals(glideTestId))).write(
        StoredGlideTestCompanion(
          title: drift.Value(updatedTest.title),
          notes: drift.Value(updatedTest.notes),
        ),
      );
      await _replaceSkiRelations(glideTestId, skiIds);
    });
  }

  Future<void> replaceSkisForTest(int glideTestId, List<int> skiIds) {
    return _db.transaction(() async {
      final validatedIds = await _validateRealSkiIds(skiIds);
      await _replaceSkiRelations(glideTestId, validatedIds);
    });
  }

  Future<void> addSkiToTest(int glideTestId, int skiId) {
    return _db.transaction(() async {
      final test = await (_db.select(
        _db.storedGlideTest,
      )..where((row) => row.id.equals(glideTestId))).getSingle();
      if (test.isExample) {
        throw StateError('Example tests cannot be changed.');
      }

      final validatedIds = await _validateRealSkiIds([skiId]);
      final existingIds = await getSkiIdsForTest(glideTestId);
      if (existingIds.contains(skiId)) return;

      await _db
          .into(_db.glideTestSki)
          .insert(
            GlideTestSkiCompanion.insert(
              glideTestId: glideTestId,
              skiId: validatedIds.single,
              sortOrder: existingIds.length,
            ),
          );
    });
  }

  Future<void> deleteGlideTest(int id) async {
    await _db.transaction(() async {
      final test = await getTestById(id);
      if (test == null) return;
      final exampleSkiIds = test.isExample
          ? await getSkiIdsForTest(id)
          : const <int>[];

      await (_db.delete(
        _db.storedGlideTest,
      )..where((row) => row.id.equals(id))).go();
      if (exampleSkiIds.isNotEmpty) {
        await (_db.delete(_db.storedSki)..where(
              (ski) => ski.id.isIn(exampleSkiIds) & ski.isExample.equals(true),
            ))
            .go();
      }
    });
  }

  Future<List<int>> _validateRealSkiIds(List<int> skiIds) async {
    final uniqueIds = skiIds.toSet().toList();
    if (uniqueIds.isEmpty) {
      throw ArgumentError.value(skiIds, 'skiIds', 'Select at least one ski.');
    }

    final skis =
        await (_db.select(_db.storedSki)..where(
              (ski) =>
                  ski.id.isIn(uniqueIds) &
                  ski.archivedAt.isNull() &
                  ski.isExample.equals(false),
            ))
            .get();
    if (skis.length != uniqueIds.length) {
      throw ArgumentError.value(
        skiIds,
        'skiIds',
        'All skis must be active, non-example skis.',
      );
    }
    return uniqueIds;
  }

  Future<void> _replaceSkiRelations(int glideTestId, List<int> skiIds) async {
    await (_db.delete(
      _db.glideTestSki,
    )..where((relation) => relation.glideTestId.equals(glideTestId))).go();
    await _insertSkiRelations(glideTestId, skiIds);
  }

  Future<void> _insertSkiRelations(int glideTestId, List<int> skiIds) async {
    await _db.batch((batch) {
      batch.insertAll(_db.glideTestSki, [
        for (final (index, skiId) in skiIds.indexed)
          GlideTestSkiCompanion.insert(
            glideTestId: glideTestId,
            skiId: skiId,
            sortOrder: index,
          ),
      ]);
    });
  }

  Future<ExportedGlideTest> exportRelatedData(int glideTestId) async {
    final test = await (_db.select(
      _db.storedGlideTest,
    )..where((t) => t.id.equals(glideTestId))).getSingle();

    final runs =
        await (_db.select(_db.testRun)
              ..where((r) => r.glideTestId.equals(glideTestId))
              ..orderBy([(r) => drift.OrderingTerm.asc(r.runNumber)]))
            .get();

    final skiIds = await getSkiIdsForTest(glideTestId);
    final unorderedSkis = await (_db.select(
      _db.storedSki,
    )..where((s) => s.id.isIn(skiIds))).get();
    final skisById = {for (final ski in unorderedSkis) ski.id: ski};
    final skis = [for (final skiId in skiIds) skisById[skiId]!];

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
