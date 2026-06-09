import 'package:drift/drift.dart';

class CustomRegexRules extends Table {
  TextColumn get id => text()();
  TextColumn get bankId => text()();
  TextColumn get name => text()();
  TextColumn get packageNamesJson => text()(); // JSON array of package names
  TextColumn get patternsJson => text()();     // JSON array of regex patterns
  TextColumn get sign => text()();             // "debit" | "credit"
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();      // epoch ms

  @override
  Set<Column> get primaryKey => {id};
}
