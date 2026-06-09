import 'package:drift/drift.dart';

class SavingsEnvelopes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get targetAmountVnd => integer().withDefault(const Constant(0))();
  IntColumn get currentAmountVnd => integer().withDefault(const Constant(0))();
  IntColumn get autoAllocationPercent => integer().withDefault(const Constant(0))();
  TextColumn get colorHex => text()();
  IntColumn get iconCode => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
