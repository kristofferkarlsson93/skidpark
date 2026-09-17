import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/ski_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';
import 'package:skidpark/features/glide_testing/compare/services/run_data_processor.dart';
import 'package:skidpark/features/glide_testing/example_data/example_data_installer.dart';
import 'package:skidpark/features/glide_testing/import/glide_test_import_service.dart';

void main() {
  late AppDatabase database;
  late ExampleDataInstaller installer;
  late String exampleSource;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    exampleSource = await File('assets/example_data/glide_test.json')
        .readAsString();
    installer = ExampleDataInstaller(
      database,
      GlideTestImportService(database),
      loadAsset: () async => exampleSource,
    );
  });

  tearDown(() => database.close());

  test(
    'installs the persisted example once through the normal data path',
    () async {
      await Future.wait([
        installer.ensureInstalled(),
        installer.ensureInstalled(),
      ]);

      final tests = await database.select(database.storedGlideTest).get();
      final skis = await database.select(database.storedSki).get();
      final runs = await database.select(database.testRun).get();
      expect(tests, hasLength(1));
      expect(tests.single.isExample, isTrue);
      expect(skis, hasLength(2));
      expect(skis.every((ski) => ski.isExample), isTrue);
      expect(runs, hasLength(4));

      final decodedRuns = await TestRunRepository(database)
          .streamByGlideTest(tests.single.id)
          .first;
      expect(decodedRuns, hasLength(4));
      expect(decodedRuns.map((run) => run.runNumber), [1, 2, 3, 4]);
      expect(decodedRuns.every((run) => run.gpsData.isNotEmpty), isTrue);
      expect(
        decodedRuns.every((run) => run.accelerometerEvents.isNotEmpty),
        isTrue,
      );
      expect(
        decodedRuns.every(
          (run) => RunDataProcessor.processRun(
            rawPositions: run.gpsData,
            accelerometerReadings: run.accelerometerEvents,
          ).isNotEmpty,
        ),
        isTrue,
      );
      expect(await SkiRepository(database).getActiveSkis(), isEmpty);
    },
  );

  test('committed example contains only synthetic identity and location', () {
    final json = jsonDecode(exampleSource) as Map<String, dynamic>;
    expect(json['deviceInfo'], isEmpty);
    final skis = json['skis'] as List<dynamic>;
    expect(skis.map((ski) => (ski as Map<String, dynamic>)['name']), [
      'Exempelskida A',
      'Exempelskida B',
    ]);
    final runs = json['runs'] as List<dynamic>;
    final positions = runs.expand(
      (run) => (run as Map<String, dynamic>)['gpsData'] as List<dynamic>,
    );
    expect(
      positions.every((value) {
        final position = value as Map<String, dynamic>;
        final latitude = position['latitude'] as num;
        final longitude = position['longitude'] as num;
        return latitude > 59.99 &&
            latitude <= 60 &&
            longitude > 14.99 &&
            longitude < 15.01 &&
            position['is_mocked'] == true;
      }),
      isTrue,
    );
  });

  test('a failed import leaves no partial example data', () async {
    final importService = GlideTestImportService(database);
    await expectLater(
      importService.importJson(
        exampleSource,
        asExample: true,
        afterInsert: (_) => throw StateError('simulated failure'),
      ),
      throwsStateError,
    );

    expect(await database.select(database.storedGlideTest).get(), isEmpty);
    expect(await database.select(database.storedSki).get(), isEmpty);
    expect(await database.select(database.testRun).get(), isEmpty);
  });

  test('deletion stays deleted until the user explicitly resets it', () async {
    await installer.ensureInstalled();
    final test = (await database.select(database.storedGlideTest).get()).single;
    await GlideTestRepository(database).deleteGlideTest(test.id);

    await installer.ensureInstalled();
    expect(await database.select(database.storedGlideTest).get(), isEmpty);
    expect(await database.select(database.storedSki).get(), isEmpty);

    await installer.reset();
    expect(await database.select(database.storedGlideTest).get(), hasLength(1));
    expect(await database.select(database.storedSki).get(), hasLength(2));
  });
}
