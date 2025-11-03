import 'package:drift/drift.dart' as drift;
import 'package:skidpark/features/glide_testing/models/glide_test_candidate.dart';

import '../database.dart';

class GlideTestRepository {
  final AppDatabase _db;

  GlideTestRepository(this._db);

  Stream<List<StoredGlideTestData>> watchTests() {
    return (_db.select(_db.storedGlideTest)..orderBy([
          (t) => drift.OrderingTerm.desc(t.createdAt), // newest first
        ]))
        .watch();
  }

  Stream<StoredGlideTestData> watchTestById(int glideTestId) {
    return (_db.select(
      _db.storedGlideTest,
    )..where((t) => t.id.equals(glideTestId))).watchSingle();
  }

  Future<int> create(GlideTestCandidate candidate) {
    final companion = StoredGlideTestCompanion(
      title: drift.Value(candidate.title),
      notes: drift.Value(candidate.notes),
    );

    return _db.into(_db.storedGlideTest).insert(companion);
  }
}
