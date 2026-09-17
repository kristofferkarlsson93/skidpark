import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';

void main() {
  for (final sourceVersion in [3, 4]) {
    test(
      'version $sourceVersion migration preserves data and numbers runs per test',
      () async {
        final executor = NativeDatabase.memory(
          setup: (database) {
            database
              ..execute('''
            CREATE TABLE stored_ski (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL,
              name TEXT NOT NULL,
              brand_and_model TEXT NULL,
              technical_data TEXT NULL,
              notes TEXT NULL,
              archived_at INTEGER NULL
            )
          ''')
              ..execute('''
            CREATE TABLE stored_glide_test (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL,
              title TEXT NOT NULL,
              notes TEXT NULL,
              use_sensor_fusion INTEGER NOT NULL DEFAULT 0
            )
          ''')
              ..execute('''
            CREATE TABLE test_run (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              glide_test_id INTEGER NOT NULL REFERENCES stored_glide_test(id) ON DELETE CASCADE,
              ski_id INTEGER NOT NULL REFERENCES stored_ski(id),
              started_at INTEGER NOT NULL,
              elapsed_seconds INTEGER NOT NULL,
              gps_data BLOB NOT NULL,
              accelerometer_data BLOB NOT NULL
            )
          ''')
              ..execute(
                "INSERT INTO stored_ski (created_at, name) VALUES (1, 'SP1'), (1, 'SP2')",
              )
              ..execute(
                "INSERT INTO stored_ski (created_at, name, archived_at) VALUES (1, 'Arkiverad', 2)",
              )
              ..execute(
                "INSERT INTO stored_glide_test (created_at, title) VALUES (1, 'Test 1'), (1, 'Test 2')",
              )
              ..execute('''
              INSERT INTO test_run (
                glide_test_id,
                ski_id,
                started_at,
                elapsed_seconds,
                gps_data,
                accelerometer_data
              ) VALUES
                (1, 1, 1, 10, X'00', X'00'),
                (2, 2, 2, 10, X'00', X'00'),
                (1, 2, 3, 10, X'00', X'00')
            ''')
              ..execute('PRAGMA user_version = $sourceVersion');
          },
        );
        final database = AppDatabase(executor);
        addTearDown(database.close);
        final repository = GlideTestRepository(database);

        expect(await repository.getSkiIdsForTest(1), [1, 2]);
        expect(await repository.getSkiIdsForTest(2), [1, 2]);
        expect((await repository.getTestById(1))!.isExample, isFalse);
        expect(await database.select(database.appSetting).get(), isEmpty);
        final runs = await (database.select(
          database.testRun,
        )..orderBy([(run) => OrderingTerm.asc(run.id)])).get();
        expect(runs.map((run) => (run.glideTestId, run.runNumber)), [
          (1, 1),
          (2, 1),
          (1, 2),
        ]);
      },
    );
  }
}
