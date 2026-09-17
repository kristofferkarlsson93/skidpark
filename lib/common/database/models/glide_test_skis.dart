import 'package:drift/drift.dart';

import 'stored_glide_test.dart';
import 'stored_ski.dart';

@TableIndex(
  name: 'glide_test_ski_test_order_index',
  columns: {#glideTestId, #sortOrder},
)
class GlideTestSki extends Table {
  IntColumn get glideTestId =>
      integer().references(StoredGlideTest, #id, onDelete: KeyAction.cascade)();

  IntColumn get skiId => integer().references(StoredSki, #id)();

  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {glideTestId, skiId};
}
