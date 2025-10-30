import 'package:drift/drift.dart';

class StoredGlideTest extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
}