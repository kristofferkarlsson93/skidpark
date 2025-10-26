import 'package:drift/drift.dart';

class StoredSki extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  TextColumn get name => text()();
  TextColumn get brandAndModel => text().nullable()();
  TextColumn get technicalData => text().nullable()();
  TextColumn get notes => text().nullable()();
}