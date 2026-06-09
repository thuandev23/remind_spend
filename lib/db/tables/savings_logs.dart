import 'package:drift/drift.dart';

class SavingsLogs extends Table {
  TextColumn get id => text()();
  TextColumn get envelopeId => text()();
  IntColumn get amountVnd => integer()();
  TextColumn get description => text()();
  IntColumn get timestampMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
