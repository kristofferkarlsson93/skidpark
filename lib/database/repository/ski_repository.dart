import 'package:drift/drift.dart';

import '../database.dart';

class SkiRepository {
  final AppDatabase _db;

  SkiRepository(this._db);

  Stream<List<StoredSkiData>> watchSkis() {
    return _db.select(_db.storedSki).watch();
  }

  Future<int> save(StoredSkiCompanion ski) {
    return _db.into(_db.storedSki).insert(ski);
  }
}