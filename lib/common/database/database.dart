import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models/app_settings.dart';
import 'models/glide_test_skis.dart';
import 'models/stored_glide_test.dart';
import 'models/stored_ski.dart';
import 'models/test_runs.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [StoredSki, StoredGlideTest, TestRun, GlideTestSki, AppSetting],
)
class AppDatabase extends _$AppDatabase {
  static const _runNumberIndexName = 'test_run_test_id_run_number_unique';

  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_ski_park',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createRunNumberIndex();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // The old feat-barrometer-recording branch also used schema version 5,
      // but its schema contained barometer_data and did not yet contain the
      // product-flow tables introduced by the main branch's version 5. Detect
      // that alternate lineage by its actual columns so test-phone data can be
      // upgraded in place instead of deleting the existing pressure samples.
      final isLegacyBarometerVersion5 =
          from == 5 &&
          await _columnExists('test_run', 'barometer_data') &&
          !await _columnExists('stored_glide_test', 'is_example');

      if (from < 2) {
        await m.addColumn(storedGlideTest, storedGlideTest.useSensorFusion);
      }
      if (from < 4) {
        final newColumns = <GeneratedColumn<Object>>[
          testRun.runNumber,
          testRun.gyroscopeData,
          testRun.rotationVectorData,
          testRun.sensorMetadata,
        ];
        if (!await _columnExists('test_run', 'barometer_data')) {
          newColumns.add(testRun.barometerData);
        }
        await m.alterTable(
          TableMigration(
            testRun,
            newColumns: newColumns,
            columnTransformer: {testRun.runNumber: const Constant(1)},
          ),
        );
      }
      if (from < 5 || isLegacyBarometerVersion5) {
        await m.addColumn(storedGlideTest, storedGlideTest.isExample);
        await m.addColumn(storedSki, storedSki.isExample);
        await m.createTable(glideTestSki);
        await m.createTable(appSetting);
        await customStatement('''
          INSERT INTO glide_test_ski (glide_test_id, ski_id, sort_order)
          SELECT test.id, ski.id,
            (
              SELECT COUNT(*)
              FROM stored_ski AS earlier_ski
              WHERE earlier_ski.archived_at IS NULL
                AND earlier_ski.id < ski.id
            )
          FROM stored_glide_test AS test
          CROSS JOIN stored_ski AS ski
          WHERE ski.archived_at IS NULL
        ''');
      }
      if (from < 6) {
        // TableMigration above already creates every current TestRun column.
        if (from >= 4) {
          await m.addColumn(testRun, testRun.runNumber);
        }
        await customStatement('''
          UPDATE test_run AS current_run
          SET run_number = (
            SELECT COUNT(*)
            FROM test_run AS earlier_run
            WHERE earlier_run.glide_test_id = current_run.glide_test_id
              AND earlier_run.id <= current_run.id
          )
        ''');
        await _createRunNumberIndex();
      }
      if (from < 7 && from >= 4) {
        if (!await _columnExists('test_run', 'gyroscope_data')) {
          await m.addColumn(testRun, testRun.gyroscopeData);
        }
        if (!await _columnExists('test_run', 'barometer_data')) {
          await m.addColumn(testRun, testRun.barometerData);
        }
        if (!await _columnExists('test_run', 'rotation_vector_data')) {
          await m.addColumn(testRun, testRun.rotationVectorData);
        }
        if (!await _columnExists('test_run', 'sensor_metadata')) {
          await m.addColumn(testRun, testRun.sensorMetadata);
        }
      }
    },
    beforeOpen: (details) async {
      // Enable foreign keys.
      await customStatement('PRAGMA foreign_keys = ON');
    },

    /*
    beforeOpen: (details) async {
      // ⚠️ DESTRUCTIVE, DANGEROUS CLEANING HACK.

      final m = Migrator(this);

      log('DEVELOPMENT WARNING: Wiping all data in specified tables to reset database schema.');
      await m.drop(testRun);
      await m.drop(storedSki);
      await m.drop(storedGlideTest);

      await m.createAll();

      // ⚠️ IMPORTANT: Remove or comment out this entire code block after use
    },
      */
  );

  Future<void> _createRunNumberIndex() {
    return customStatement('''
      CREATE UNIQUE INDEX IF NOT EXISTS $_runNumberIndexName
      ON test_run (glide_test_id, run_number)
    ''');
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    final columns = await customSelect('PRAGMA table_info($tableName)').get();
    return columns.any((row) => row.read<String>('name') == columnName);
  }
}
