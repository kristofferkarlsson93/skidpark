import 'package:drift/drift.dart' as drift;
import 'package:skidpark/models/ski/ski.dart';

import '../database.dart';

class SkiRepository {
  final AppDatabase _db;

  SkiRepository(this._db);

  Stream<List<StoredSkiData>> watchSkis() {
    return _db.select(_db.storedSki).watch();
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
}