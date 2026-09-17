import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/models/test_run_candidate.dart';

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
}

TestRunCandidate _candidate(int testId, int skiId) {
  return TestRunCandidate(
    startedAt: DateTime(2026, 9, 15),
    skiId: skiId,
    glideTestId: testId,
    elapsedSeconds: 10,
    gpsData: const [],
    accelerometerEvents: const [],
  );
}
