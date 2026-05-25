import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'models/stored_glide_test.dart';
import 'models/stored_ski.dart';
import 'models/test_runs.dart';
import 'package:collection/collection.dart';

part 'database.g.dart';

@DriftDatabase(tables: [StoredSki, StoredGlideTest, TestRun])
class AppDatabase extends _$AppDatabase {
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
    onCreate: (m) {
      return m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(storedGlideTest, storedGlideTest.useSensorFusion);
      }
      if (from < 4) {
        await m.alterTable(TableMigration(testRun));
      }
      if (from < 5) {
        await m.addColumn(testRun, testRun.barometerData);
      }
      if (from < 6) {
        await m.addColumn(testRun, testRun.runNumber);
        await _backfillRunNumbers();
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

  Future<void> _backfillRunNumbers() async {
    final allRuns = await select(testRun).get();

    final runsToUpdate = allRuns
        .groupListsBy((run) => run.glideTestId)
        .values
        .expand(
          (runsInGroup) => runsInGroup
          .sortedBy<num>((run) => run.id)
          .indexed
          .map((indexedRun) {
        final (index, run) = indexedRun;
        return run.copyWith(runNumber: index + 1);
      }),
    ).toList();

    await batch((batch) {
      for (final run in runsToUpdate) {
        batch.replace(testRun, run);
      }
    });

    log("Migration to v6: Backfilled run numbers for ${allRuns.length} runs.");
  }
}
