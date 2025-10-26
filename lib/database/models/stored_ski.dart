import 'package:drift/drift.dart';

class StoredSki extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  TextColumn get brandAndModel => text().nullable()();
  TextColumn get technicalData => text().nullable()();
  TextColumn get notes => text().nullable()();
}