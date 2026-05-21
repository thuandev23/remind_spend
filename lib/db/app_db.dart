import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/bank_rule.dart';
import 'tables/regex_config_cache.dart';
import 'tables/transactions.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Transactions, RegexConfigCache])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  /// In-memory database for unit tests — no file I/O, no path_provider needed.
  AppDb.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(regexConfigCache);
          }
          if (from < 3) {
            await m.addColumn(transactions, transactions.rawContent);
          }
          if (from < 4) {
            await m.addColumn(transactions, transactions.isDraft);
          }
          if (from < 5) {
            await m.addColumn(transactions, transactions.categoryId);
          }
        },
      );

  // ── Transaction writes ────────────────────────────────────────────────────

  /// Insert a row; silently ignore if a row with the same [id] already exists.
  Future<void> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry, mode: InsertMode.insertOrIgnore);

  /// Approve a pending draft transaction
  Future<void> approveTransaction(String id) =>
      (update(transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(isDraft: Value(false)));

  /// Delete a transaction (used for rejecting/deleting drafts or verified transactions)
  Future<void> deleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  /// Update the amount of a transaction and confirm it (ends its draft state)
  Future<void> updateTransactionAmount(String id, int amountVnd) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          amountVnd: Value(amountVnd),
          isDraft: const Value(false),
        ),
      );

  /// Update transaction companion fields directly (flexible update)
  Future<void> updateTransactionCompanion(String id, TransactionsCompanion entry) =>
      (update(transactions)..where((t) => t.id.equals(id))).write(entry);

  // ── Transaction reads ─────────────────────────────────────────────────────

  /// Reactive stream — newest transaction first.
  Stream<List<Transaction>> watchAll() =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.timestampMs)]))
          .watch();

  /// One-shot read — newest first.
  Future<List<Transaction>> getAll() =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.timestampMs)]))
          .get();

  // ── Regex config cache ────────────────────────────────────────────────────

  Future<void> upsertRegexConfig(RegexConfigCacheCompanion entry) =>
      into(regexConfigCache).insertOnConflictUpdate(entry);

  Future<List<RegexConfigCacheData>> getAllRegexConfig() =>
      select(regexConfigCache).get();

  Future<void> clearRegexConfig() => delete(regexConfigCache).go();
}

// ── Conversion helpers ────────────────────────────────────────────────────────

extension RegexConfigCacheDataX on RegexConfigCacheData {
  BankRule toBankRule() => BankRule(
        bankId: bankId,
        packageNames:
            (jsonDecode(packageNamesJson) as List<dynamic>).cast<String>(),
        patterns: (jsonDecode(patternsJson) as List<dynamic>).cast<String>(),
        amountGroup: amountGroup,
        sign: sign,
      );
}

extension BankRuleX on BankRule {
  RegexConfigCacheCompanion toCacheCompanion(int version, {int? fetchedAt}) =>
      RegexConfigCacheCompanion.insert(
        bankId: bankId,
        packageNamesJson: jsonEncode(packageNames),
        patternsJson: jsonEncode(patterns),
        amountGroup: Value(amountGroup),
        sign: sign,
        version: version,
        fetchedAt: fetchedAt ?? DateTime.now().millisecondsSinceEpoch,
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'remind_spend.db'));
    return NativeDatabase.createInBackground(file);
  });
}
