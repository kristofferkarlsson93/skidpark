import 'package:drift/drift.dart';
import 'package:skidpark/common/database/models/stored_glide_test.dart';
import 'package:skidpark/common/database/models/stored_ski.dart';

@TableIndex(name: 'glide_test_id_id_index', columns: {#glideTestId, #id})
class TestRun extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get glideTestId => integer().references(StoredGlideTest, #id)();
  IntColumn get skiId => integer().references(StoredSki, #id)();

  DateTimeColumn get startedAt => dateTime()();
  IntColumn get elapsedSeconds => integer()();

  BlobColumn get gpsData => blob()();
  BlobColumn get accelerometerData => blob()();

  BlobColumn get barometerData => blob().nullable()();
}