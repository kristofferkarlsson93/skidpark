import 'dart:async';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';

void main() {
  late AppDatabase database;
  late GlideTestRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = GlideTestRepository(database);
  });

  tearDown(() => database.close());

  test('summaries count runs and distinct tested skis', () async {
    final testId = await repository.create(
      GlideTestCandidate(title: 'Test med åk', notes: null),
    );
    await repository.create(
      GlideTestCandidate(title: 'Tomt test', notes: null),
    );

    final firstSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
    final secondSkiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP2'));
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
    expect(empty.testedSkiCount, 0);
    expect(empty.latestActivityAt, empty.test.createdAt);
  });

  test('summary stream updates when a run is inserted', () async {
    final testId = await repository.create(
      GlideTestCandidate(title: 'Reaktivt test', notes: null),
    );
    final skiId = await database
        .into(database.storedSki)
        .insert(StoredSkiCompanion.insert(name: 'SP1'));
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
}

Future<void> _insertRun(
  AppDatabase database,
  int testId,
  int skiId,
  DateTime startedAt,
) async {
  await database
      .into(database.testRun)
      .insert(
        TestRunCompanion.insert(
          glideTestId: testId,
          skiId: skiId,
          startedAt: startedAt,
          elapsedSeconds: 10,
          gpsData: Uint8List(0),
          accelerometerData: Uint8List(0),
        ),
      );
}
