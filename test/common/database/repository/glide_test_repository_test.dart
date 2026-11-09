import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';
import 'package:skidpark/features/glide_testing/import/glide_test_import_service.dart';

void main() {
  late AppDatabase database;
  late GlideTestRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = GlideTestRepository(database);
  });

  tearDown(() => database.close());

  test(
    'exports legacy historical runs without a current selection losslessly',
    () async {
      final skiId = await database
          .into(database.storedSki)
          .insert(StoredSkiCompanion.insert(name: 'Historisk skida'));
      final testId = await repository.create(
        GlideTestCandidate(title: 'Äldre test', skiIds: [skiId]),
      );
      await _insertRun(database, testId, skiId, DateTime.utc(2026, 1, 1));
      await (database.delete(
        database.glideTestSki,
      )..where((selection) => selection.glideTestId.equals(testId))).go();
      final exported = await repository.exportRelatedData(testId);
      final importedId = await GlideTestImportService(database)
          .importJson(jsonEncode(exported.toJson()), asExample: false);
      expect(await repository.getSkiIdsForTest(importedId), isEmpty);
      final runs = await TestRunRepository(database)
          .streamByGlideTest(importedId)
          .first;
      expect(runs.single.skiName, 'Historisk skida');
    },
  );

  test('changing selection preserves metadata, historical runs and export round trip', () async {
    final ids = <int>[];
    for (final name in ['Tidigare skida', 'SP2', 'SP3']) {
      ids.add(
        await database
            .into(database.storedSki)
            .insert(StoredSkiCompanion.insert(name: name)),
      );
    }
    final testId = await repository.create(
      GlideTestCandidate(title: 'Nysnö', notes: 'Svag vind', skiIds: ids),
    );
    await repository.setUseSensorFusion(testId, true);
    await _insertRun(database, testId, ids.first, DateTime.utc(2026, 10, 30));
    final originalRun = await database.select(database.testRun).getSingle();

    await repository.replaceSkisForTest(testId, [ids[2], ids[1]]);

    expect(await repository.getSkiIdsForTest(testId), [ids[2], ids[1]]);
    final test = (await repository.getTestById(testId))!;
    expect(test.title, 'Nysnö');
    expect(test.notes, 'Svag vind');
    expect(test.useSensorFusion, isTrue);
    expect(await database.select(database.testRun).getSingle(), originalRun);
    final historical = (await TestRunRepository(
      database,
    ).streamByGlideTest(testId).first).single;
    expect(historical.skiName, 'Tidigare skida');
    expect(historical.runNumber, 1);

    final exported = await repository.exportRelatedData(testId);
    final json = exported.toJson();
    expect(json['selectedSkiIds'], [ids[2], ids[1]]);
    expect(exported.skis.map((ski) => ski.id), [ids[2], ids[1], ids.first]);
    final importedId = await GlideTestImportService(database)
        .importJson(jsonEncode(json), asExample: false);
    final importedSkis = await repository.watchSkisForTest(importedId).first;
    expect(importedSkis.map((ski) => ski.name), ['SP3', 'SP2']);
    final importedRun = (await TestRunRepository(
      database,
    ).streamByGlideTest(importedId).first).single;
    expect(importedRun.skiName, 'Tidigare skida');
    expect(importedRun.runNumber, originalRun.runNumber);
    expect(importedRun.gpsEvents.length, historical.gpsEvents.length);
  });

  test('invalid or read-only selection changes leave the original relations intact', () async {
    final skiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    final testId = await repository.create(
      GlideTestCandidate(title: 'Test', skiIds: [skiId]),
    );
    for (final invalid in [
      <int>[],
      [99999],
    ]) {
      await expectLater(
        repository.replaceSkisForTest(testId, invalid),
        throwsArgumentError,
      );
      expect(await repository.getSkiIdsForTest(testId), [skiId]);
    }
    await (database.update(database.storedGlideTest)
          ..where((test) => test.id.equals(testId)))
        .write(const StoredGlideTestCompanion(isExample: Value(true)));
    await expectLater(
      repository.replaceSkisForTest(testId, [skiId]),
      throwsStateError,
    );
    await expectLater(
      repository.replaceSkisForTest(99999, [skiId]),
      throwsStateError,
    );
    expect(await repository.getSkiIdsForTest(testId), [skiId]);
  });

  test('summaries count runs and selected skis', () async {
    final firstSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    final secondSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP2'));
    final testId = await repository.create(
      GlideTestCandidate(
        title: 'Test med åk',
        notes: null,
        skiIds: [firstSkiId, secondSkiId],
      ),
    );
    await repository.create(
      GlideTestCandidate(title: 'Tomt test', notes: null, skiIds: [firstSkiId]),
    );
    final latestRunAt = DateTime(2026, 2, 3, 12, 30);

    await _insertRun(database, testId, firstSkiId, DateTime(2026, 2, 3, 12));
    await _insertRun(
      database,
      testId,
      firstSkiId,
      DateTime(2026, 2, 3, 12, 15),
    );
    await _insertRun(database, testId, secondSkiId, latestRunAt);

    final summaries = await repository.watchTestSummaries().first;
    expect(summaries.first.test.title, 'Tomt test');
    final populated = summaries.singleWhere(
      (summary) => summary.test.title == 'Test med åk',
    );
    final empty = summaries.singleWhere(
      (summary) => summary.test.title == 'Tomt test',
    );

    expect(populated.runCount, 3);
    expect(populated.testedSkiCount, 2);
    expect(populated.latestActivityAt, latestRunAt);
    expect(empty.runCount, 0);
    expect(empty.testedSkiCount, 1);
    expect(empty.latestActivityAt, empty.test.createdAt);
  });

  test('summary stream updates when a run is inserted', () async {
    final skiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    final testId = await repository.create(
      GlideTestCandidate(title: 'Reaktivt test', notes: null, skiIds: [skiId]),
    );
    final emissions = StreamIterator(repository.watchTestSummaries());

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current.single.runCount, 0);

    final runAt = DateTime(2026, 2, 3, 12, 30);
    await _insertRun(database, testId, skiId, runAt);

    expect(
      await emissions.moveNext().timeout(const Duration(seconds: 2)),
      isTrue,
    );
    expect(emissions.current.single.runCount, 1);
    expect(emissions.current.single.testedSkiCount, 1);
    expect(emissions.current.single.latestActivityAt, runAt);

    await emissions.cancel();
  });

  test('creation preserves ski order and is atomic on invalid ids', () async {
    final firstSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    final secondSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP2'));

    final testId = await repository.create(
      GlideTestCandidate(title: 'Ordning', skiIds: [secondSkiId, firstSkiId]),
    );
    expect(await repository.getSkiIdsForTest(testId), [
      secondSkiId,
      firstSkiId,
    ]);

    await expectLater(
      repository.create(
        GlideTestCandidate(title: 'Ska inte sparas', skiIds: [99999]),
      ),
      throwsArgumentError,
    );
    final tests = await repository.watchTests().first;
    expect(tests.map((test) => test.title), ['Ordning']);
  });

  test('example skis stay out of real selections', () async {
    final ownSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'Egen'));
    final exampleSkiId = await database
        .into(database.storedSki)
        .insert(
          StoredSkiCompanion.insert(
            name: 'Exempel',
            isExample: const Value(true),
          ),
        );

    await expectLater(
      repository.create(
        GlideTestCandidate(title: 'Fel', skiIds: [exampleSkiId]),
      ),
      throwsArgumentError,
    );
    final testId = await repository.create(
      GlideTestCandidate(title: 'Rätt', skiIds: [ownSkiId]),
    );
    expect(await repository.getLatestRealTestSkiIds(), [ownSkiId]);
    expect(await repository.getSkiIdsForTest(testId), [ownSkiId]);
  });

  test('export includes selected skis when the test has no runs', () async {
    final firstSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    final secondSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP2'));
    final testId = await repository.create(
      GlideTestCandidate(
        title: 'Test utan åk',
        skiIds: [secondSkiId, firstSkiId],
      ),
    );

    final exported = await repository.exportRelatedData(testId);

    expect(exported.runs, isEmpty);
    expect(exported.skis.map((ski) => ski.id), [secondSkiId, firstSkiId]);
  });

  test('export includes selected skis that have not been tested yet', () async {
    final testedSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'Testad'));
    final untestedSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'Inte testad'));
    final testId = await repository.create(
      GlideTestCandidate(
        title: 'Delvis genomfört test',
        skiIds: [untestedSkiId, testedSkiId],
      ),
    );
    await _insertRun(database, testId, testedSkiId, DateTime(2026, 2, 3, 12));

    final exported = await repository.exportRelatedData(testId);

    expect(exported.runs, hasLength(1));
    expect(exported.runs.single.skiId, testedSkiId);
    expect(exported.skis.map((ski) => ski.id), [untestedSkiId, testedSkiId]);
    final exportedJson = exported.toJson();
    expect(exportedJson['version'], 3);
    expect(
      (exportedJson['runs'] as List<dynamic>).single,
      containsPair('runNumber', 1),
    );
  });
}

Future<void> _insertRun(
  AppDatabase database,
  int testId,
  int skiId,
  DateTime startedAt,
) async {
  final existingRuns = await (database.select(
    database.testRun,
  )..where((run) => run.glideTestId.equals(testId))).get();
  final nextRunNumber = existingRuns.length + 1;
  await database
      .into(database.testRun)
      .insert(
        TestRunCompanion.insert(
          glideTestId: testId,
          skiId: skiId,
          runNumber: Value(nextRunNumber),
          startedAt: startedAt,
          elapsedSeconds: 10,
          gpsData: TestRunRepository.encodeGpsPositions(const []),
          accelerometerData: TestRunRepository.encodeAccelEvents(const []),
        ),
      );
}
