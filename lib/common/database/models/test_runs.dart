import 'package:drift/drift.dart';
import 'package:skidpark/common/database/models/stored_glide_test.dart';
import 'package:skidpark/common/database/models/stored_ski.dart';


class TestRun extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get glideTestId => integer().references(StoredGlideTest, #id)();
  IntColumn get skiId => integer().references(StoredSki, #id)();

  DateTimeColumn get startedAt => dateTime()();
  IntColumn get elapsedSeconds => integer()();

  BlobColumn get gpsData => blob()();
  BlobColumn get accelerometerData => blob().nullable()();
}