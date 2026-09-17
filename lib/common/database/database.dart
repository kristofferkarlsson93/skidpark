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
  int get schemaVersion => 6;

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
      if (from < 2) {
        await m.addColumn(storedGlideTest, storedGlideTest.useSensorFusion);
      }
      if (from < 4) {
        await m.alterTable(
          TableMigration(
            testRun,
            newColumns: [testRun.runNumber],
            columnTransformer: {testRun.runNumber: const Constant(1)},
          ),
        );
      }
      if (from < 5) {
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
}
