import 'package:drift/drift.dart' as drift;
import 'package:skidpark/models/ski/ski.dart';

import '../database.dart';

class SkiRepository {
  final AppDatabase _db;

  SkiRepository(this._db);

  Stream<List<StoredSkiData>> watchSkis() {
    return _db.select(_db.storedSki).watch();
  }

  Stream<StoredSkiData> watchSkiById(int id) {
    return (_db.select(_db.storedSki)..where((t) => t.id.equals(id)))
        .watchSingle();
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

    return (_db.update(_db.storedSki)..where((t) => t.id.equals(ski.id)))
        .write(companion);
  }

  Future<int> deleteSki(StoredSkiData ski) {
    return (_db.delete(_db.storedSki)..where((t) => t.id.equals(ski.id))).go();
  }
}