import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/bank_rule.dart';
import 'tables/regex_config_cache.dart';
import 'tables/transactions.dart';
import 'tables/custom_regex_rules.dart';
import 'tables/savings_envelopes.dart';
import 'tables/savings_logs.dart';

part 'app_db.g.dart';

@DriftDatabase(tables: [Transactions, RegexConfigCache, CustomRegexRules, SavingsEnvelopes, SavingsLogs])
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  /// In-memory database for unit tests — no file I/O, no path_provider needed.
  AppDb.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

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
          if (from < 6) {
            await m.createTable(customRegexRules);
          }
          if (from < 7) {
            await m.createTable(savingsEnvelopes);
            await m.createTable(savingsLogs);
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

  // ── Custom Regex Rules CRUD ────────────────────────────────────────────────

  Future<void> upsertCustomRegexRule(CustomRegexRulesCompanion entry) =>
      into(customRegexRules).insertOnConflictUpdate(entry);

  Future<void> updateCustomRegexRule(String id, CustomRegexRulesCompanion entry) =>
      (update(customRegexRules)..where((t) => t.id.equals(id))).write(entry);

  Future<List<CustomRegexRule>> getAllCustomRegexRules() =>
      (select(customRegexRules)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<void> deleteCustomRegexRule(String id) =>
      (delete(customRegexRules)..where((t) => t.id.equals(id))).go();

  // ── Savings Envelopes CRUD ──────────────────────────────────────────────────

  Future<void> upsertSavingsEnvelope(SavingsEnvelopesCompanion entry) =>
      into(savingsEnvelopes).insertOnConflictUpdate(entry);

  Future<void> deleteSavingsEnvelope(String id) =>
      (delete(savingsEnvelopes)..where((t) => t.id.equals(id))).go();

  Future<List<SavingsEnvelope>> getAllSavingsEnvelopes() =>
      (select(savingsEnvelopes)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Stream<List<SavingsEnvelope>> watchAllSavingsEnvelopes() =>
      (select(savingsEnvelopes)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  // ── Savings Logs CRUD ───────────────────────────────────────────────────────

  Future<void> insertSavingsLog(SavingsLogsCompanion entry) =>
      into(savingsLogs).insert(entry);

  Future<List<SavingsLog>> getEnvelopeLogs(String envelopeId) =>
      (select(savingsLogs)
            ..where((t) => t.envelopeId.equals(envelopeId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestampMs)]))
          .get();

  Stream<List<SavingsLog>> watchEnvelopeLogs(String envelopeId) =>
      (select(savingsLogs)
            ..where((t) => t.envelopeId.equals(envelopeId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestampMs)]))
          .watch();
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
