import 'package:drift/drift.dart';

import '../core/app_exception.dart';
import '../core/app_logger.dart';
import '../db/app_db.dart';
import '../models/pending_transaction.dart';
import '../services/bridge_service.dart';

const _tag = 'TransactionRepository';

class TransactionRepository {
  final AppDb _db;

  TransactionRepository(this._db);

  // ── Native pull ───────────────────────────────────────────────────────────

  /// Pulls from the native queue, validates, persists to Drift.
  /// Returns the number of new rows written.
  /// Throws [BridgePullException] or [DatabaseWriteException] on failure.
  Future<int> syncFromNative() async {
    final List<PendingTransaction> pending;
    try {
      pending = await BridgeService.getAndClearQueue();
    } on BridgeError catch (e, st) {
      AppLogger.error(_tag, 'Native pull failed: ${e.code}', error: e, stack: st);
      throw BridgePullException(e.message);
    }

    if (pending.isEmpty) return 0;

    final valid = pending.where(_isValid).toList();
    final dropped = pending.length - valid.length;
    if (dropped > 0) {
      AppLogger.warn(_tag, 'Dropped $dropped invalid transactions');
    }

    if (valid.isEmpty) return 0;

    try {
      for (final tx in valid) {
        await _db.insertTransaction(_toCompanion(tx));
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'DB write failed', error: e, stack: st);
      throw DatabaseWriteException(e.toString());
    }

    // Log count only — never log amounts (PII).
    AppLogger.info(_tag, 'Persisted ${valid.length} transaction(s)');
    return valid.length;
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// Reactive stream for the UI — newest first.
  Stream<List<Transaction>> watchAll() => _db.watchAll();

  /// One-shot read — newest first.
  Future<List<Transaction>> getAll() => _db.getAll();

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isValid(PendingTransaction tx) {
    if (tx.amountVnd <= 0) return false;
    if (tx.bankId.isEmpty) return false;
    if (tx.sign != 'debit' && tx.sign != 'credit') return false;
    return true;
  }

  TransactionsCompanion _toCompanion(PendingTransaction tx) =>
      TransactionsCompanion.insert(
        id: tx.id,
        bankId: tx.bankId,
        amountVnd: tx.amountVnd,
        sign: tx.sign,
        timestampMs: tx.timestampMs,
        createdAt: tx.createdAt,
        syncedAt: const Value.absent(),
      );
}
