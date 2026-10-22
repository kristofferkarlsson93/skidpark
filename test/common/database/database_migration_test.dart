import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skidpark/common/database/database.dart';
import 'package:skidpark/common/database/repository/glide_test_repository.dart';
import 'package:skidpark/common/database/repository/test_run_repository.dart';

void main() {
  for (final sourceVersion in [1, 2, 3, 4]) {
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
              notes TEXT NULL
              ${sourceVersion >= 2 ? ', use_sensor_fusion INTEGER NOT NULL DEFAULT 0' : ''}
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
        expect(runs.every((run) => run.gyroscopeData == null), isTrue);
        expect(runs.every((run) => run.barometerData == null), isTrue);
        expect(runs.every((run) => run.rotationVectorData == null), isTrue);
        expect(runs.every((run) => run.sensorMetadata == null), isTrue);
      },
    );
  }

  test('version 6 migration adds nullable sensor columns', () async {
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
              archived_at INTEGER NULL,
              is_example INTEGER NOT NULL DEFAULT 0
            )
          ''')
          ..execute('''
            CREATE TABLE stored_glide_test (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              created_at INTEGER NOT NULL,
              title TEXT NOT NULL,
              notes TEXT NULL,
              use_sensor_fusion INTEGER NOT NULL DEFAULT 0,
              is_example INTEGER NOT NULL DEFAULT 0
            )
          ''')
          ..execute('''
            CREATE TABLE test_run (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              glide_test_id INTEGER NOT NULL REFERENCES stored_glide_test(id) ON DELETE CASCADE,
              ski_id INTEGER NOT NULL REFERENCES stored_ski(id),
              run_number INTEGER NOT NULL DEFAULT 1,
              started_at INTEGER NOT NULL,
              elapsed_seconds INTEGER NOT NULL,
              gps_data BLOB NOT NULL,
              accelerometer_data BLOB NOT NULL
            )
          ''')
          ..execute(
            "INSERT INTO stored_ski (created_at, name) VALUES (1, 'SP1')",
          )
          ..execute(
            "INSERT INTO stored_glide_test (created_at, title) VALUES (1, 'Test')",
          )
          ..execute('''
            INSERT INTO test_run (
              glide_test_id,
              ski_id,
              run_number,
              started_at,
              elapsed_seconds,
              gps_data,
              accelerometer_data
            ) VALUES (1, 1, 1, 1, 10, X'00', X'00')
          ''')
          ..execute('PRAGMA user_version = 6');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final run = await database.select(database.testRun).getSingle();

    expect(run.gyroscopeData, null);
    expect(run.barometerData, null);
    expect(run.rotationVectorData, null);
    expect(run.sensorMetadata, null);
  });

  test('legacy barometer version 5 keeps pressure data', () async {
    final legacyPressureData = GZipEncoder().encodeBytes(
      utf8.encode(
        jsonEncode([
          {'pressure': 998.2, 'timestamp': '2026-02-27T12:00:00.000Z'},
        ]),
      ),
    );
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
              accelerometer_data BLOB NOT NULL,
              barometer_data BLOB NULL
            )
          ''')
          ..execute(
            "INSERT INTO stored_ski (created_at, name) VALUES (1, 'SP1')",
          )
          ..execute(
            "INSERT INTO stored_glide_test (created_at, title) VALUES (1, 'Test')",
          )
          ..execute(
            '''
            INSERT INTO test_run (
              glide_test_id,
              ski_id,
              started_at,
              elapsed_seconds,
              gps_data,
              accelerometer_data,
              barometer_data
            ) VALUES (1, 1, 1, 10, X'00', X'00', ?)
          ''',
            [legacyPressureData],
          )
          ..execute('PRAGMA user_version = 5');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);
    final repository = GlideTestRepository(database);

    final run = await database.select(database.testRun).getSingle();

    expect(run.runNumber, 1);
    final pressureEvents = TestRunRepository.decodeBarometerEvents(
      run.barometerData,
    );
    expect(run.barometerData, legacyPressureData);
    expect(pressureEvents.single.pressureHpa, 998.2);
    expect(pressureEvents.single.elapsedMicroseconds, 0);
    expect(run.gyroscopeData, null);
    expect(run.rotationVectorData, null);
    expect(run.sensorMetadata, null);
    expect((await repository.getTestById(1))!.isExample, isFalse);
    expect(await repository.getSkiIdsForTest(1), [1]);
    expect(await database.select(database.appSetting).get(), isEmpty);
  });
}
