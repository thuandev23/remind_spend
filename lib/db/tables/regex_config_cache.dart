import 'package:drift/drift.dart';

class RegexConfigCache extends Table {
  TextColumn get bankId => text()();
  TextColumn get packageNamesJson => text()(); // JSON array of strings
  TextColumn get patternsJson => text()();     // JSON array of strings
  IntColumn get amountGroup => integer().withDefault(const Constant(1))();
  TextColumn get sign => text()();             // "debit" | "credit"
  IntColumn get version => integer()();
  IntColumn get fetchedAt => integer()();      // epoch ms

  @override
  Set<Column> get primaryKey => {bankId};
}
