import 'package:drift/drift.dart';

import '../core/app_exception.dart';
import '../core/app_logger.dart';
import '../db/app_db.dart';
import '../models/pending_transaction.dart';
import '../services/bridge_service.dart';
import '../services/categorization_service.dart';
import '../services/gemini_service.dart';
import '../services/budget_service.dart';
// import '../services/savings_service.dart';

const _tag = 'TransactionRepository';

class TransactionRepository {
  final AppDb _db;

  AppDb get db => _db;

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
        
        // Nếu phân loại cục bộ ra 'others' và có nội dung tin nhắn, kích hoạt AI phân tích ở background
        final initialCategory = CategorizationService.classify(tx.rawContent, tx.sign);
        if (initialCategory == 'others' && tx.rawContent != null && tx.rawContent!.trim().isNotEmpty) {
          _triggerBackgroundAiClassification(tx.id, tx.rawContent!, tx.sign);
        }
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'DB write failed', error: e, stack: st);
      throw DatabaseWriteException(e.toString());
    }

    // Log count only — never log amounts (PII).
    AppLogger.info(_tag, 'Persisted ${valid.length} transaction(s)');
    return valid.length;
  }

  /// Kích hoạt tiến trình phân loại bằng AI chạy ngầm (fire-and-forget) để không block UI chính
  void _triggerBackgroundAiClassification(String id, String content, String sign) {
    Future.microtask(() async {
      try {
        final aiCategory = await GeminiService.classifyWithAi(content, sign);
        AppLogger.info(_tag, 'AI đã phân loại lại thành công cho $id thành: "$aiCategory"');
        await _db.updateTransactionCompanion(
          id,
          TransactionsCompanion(
            categoryId: Value(aiCategory),
          ),
        );
      } catch (e, st) {
        AppLogger.error(_tag, 'Lỗi trong tiến trình AI background classification của giao dịch $id', error: e, stack: st);
        // Fallback về others nếu có lỗi nặng
        await _db.updateTransactionCompanion(
          id,
          const TransactionsCompanion(
            categoryId: Value('others'),
          ),
        );
      }
    });
  }

  // ── Reads ─────────────────────────────────────────────────────────────────

  /// Reactive stream for the UI — newest first.
  Stream<List<Transaction>> watchAll() => _db.watchAll();

  /// One-shot read — newest first.
  Future<List<Transaction>> getAll() => _db.getAll();

  /// Approve a pending draft transaction
  Future<void> approveTransaction(String id) async {
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    await _db.approveTransaction(id);
    if (tx != null) {
      if (tx.sign == 'debit') {
        await BudgetService.checkAndNotifyBudget(_db, tx.categoryId);
      } else if (tx.sign == 'credit') {
        // Tạm ẩn tính năng tự động trích lập hũ khi ẩn hũ tài chính
        // await SavingsService.autoAllocateCredit(_db, tx.amountVnd, tx.rawContent ?? 'Thu nhập');
      }
    }
  }

  /// Delete a transaction (reject draft or delete official transaction)
  Future<void> deleteTransaction(String id) async {
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    await _db.deleteTransaction(id);
    if (tx != null && tx.sign == 'debit') {
      await BudgetService.checkAndNotifyBudget(_db, tx.categoryId);
    }
  }

  /// Adjust the amount of a transaction and approve it
  Future<void> updateTransactionAmount(String id, int amountVnd) async {
    await _db.updateTransactionAmount(id, amountVnd);
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (tx != null && tx.sign == 'debit') {
      await BudgetService.checkAndNotifyBudget(_db, tx.categoryId);
    }
  }

  /// Update flexible transaction companion fields directly (e.g. amount & sign)
  Future<void> updateTransactionCompanion(String id, TransactionsCompanion entry) async {
    await _db.updateTransactionCompanion(id, entry);
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (tx != null && tx.sign == 'debit') {
      await BudgetService.checkAndNotifyBudget(_db, tx.categoryId);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isValid(PendingTransaction tx) {
    if (tx.amountVnd <= 0) return false;
    if (tx.bankId.isEmpty) return false;
    if (tx.sign != 'debit' && tx.sign != 'credit') return false;
    return true;
  }

  TransactionsCompanion _toCompanion(PendingTransaction tx) {
    final initialCategory = CategorizationService.classify(tx.rawContent, tx.sign);
    // Nếu phân loại ban đầu ra 'others' và có nội dung tin nhắn để AI phân tích được
    final finalInitialCategory = (initialCategory == 'others' && tx.rawContent != null && tx.rawContent!.trim().isNotEmpty)
        ? 'others'
        : initialCategory;

    return TransactionsCompanion.insert(
      id: tx.id,
      bankId: tx.bankId,
      amountVnd: tx.amountVnd,
      sign: tx.sign,
      timestampMs: tx.timestampMs,
      createdAt: tx.createdAt,
      syncedAt: const Value.absent(),
      rawContent: Value(tx.rawContent),
      isDraft: const Value(true), // Mặc định là Draft đối với giao dịch kéo từ native về
      categoryId: Value(finalInitialCategory),
    );
  }
}
