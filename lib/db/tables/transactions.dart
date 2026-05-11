import 'package:drift/drift.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get bankId => text()();

  // Int64 — never real/double. Drift maps IntColumn to Dart int (64-bit).
  IntColumn get amountVnd => integer()();

  TextColumn get sign => text()(); // "debit" | "credit"
  IntColumn get timestampMs => integer()(); // from notification/SMS
  IntColumn get createdAt => integer()(); // when Flutter persisted it

  // Nullable — set when synced to backend (Sprint 5+).
  IntColumn get syncedAt => integer().nullable()();

  // Raw SMS/notification text — nullable for rows migrated from older schema.
  TextColumn get rawContent => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
