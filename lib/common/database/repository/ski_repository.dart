import 'package:drift/drift.dart' as drift;
import 'package:skidpark/features/ski_management/models/ski.dart';

import '../database.dart';

class SkiRepository {
  final AppDatabase _db;

  SkiRepository(this._db);

  Stream<List<StoredSkiData>> watchActiveSkis({bool includeExamples = false}) {
    final activeSkisQuery = _db.select(_db.storedSki)
      ..where(
        (ski) =>
            ski.archivedAt.isNull() &
            (includeExamples
                ? const drift.Constant(true)
                : ski.isExample.equals(false)),
      )
      ..orderBy([(ski) => drift.OrderingTerm.asc(ski.id)]);

    return activeSkisQuery.watch();
  }

  Future<List<StoredSkiData>> getActiveSkis({bool includeExamples = false}) {
    final query = _db.select(_db.storedSki)
      ..where(
        (ski) =>
            ski.archivedAt.isNull() &
            (includeExamples
                ? const drift.Constant(true)
                : ski.isExample.equals(false)),
      )
      ..orderBy([(ski) => drift.OrderingTerm.asc(ski.id)]);
    return query.get();
  }

  Stream<StoredSkiData> watchSkiById(int id) {
    return (_db.select(
      _db.storedSki,
    )..where((t) => t.id.equals(id))).watchSingle();
  }

  Future<int> save(SkiCandidate ski) {
    final companion = StoredSkiCompanion(
      name: drift.Value(ski.name),
      brandAndModel: drift.Value(ski.brandAndModel),
      technicalData: drift.Value(ski.technicalData),
      notes: drift.Value(ski.notes),
    );

    return _db.into(_db.storedSki).insert(companion);
  }

  Future<int> updateSki(StoredSkiData ski, SkiCandidate candidate) {
    final companion = StoredSkiCompanion(
      name: drift.Value(candidate.name),
      brandAndModel: drift.Value(candidate.brandAndModel),
      technicalData: drift.Value(candidate.technicalData),
      notes: drift.Value(candidate.notes),
    );

    return (_db.update(
      _db.storedSki,
    )..where((t) => t.id.equals(ski.id))).write(companion);
  }

  Future<int> archiveSki(StoredSkiData ski) {
    final companion = StoredSkiCompanion(
      archivedAt: drift.Value(DateTime.now()),
    );
    return (_db.update(
      _db.storedSki,
    )..where((t) => t.id.equals(ski.id))).write(companion);
  }
}
