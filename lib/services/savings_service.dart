import '../db/app_db.dart';

class SavingsService {
  static Future<void> autoAllocateCredit(AppDb db, int creditAmountVnd, String description) async {
    if (creditAmountVnd <= 0) return;

    await db.transaction(() async {
      final envelopes = await db.getAllSavingsEnvelopes();
      final activeEnvelopes = envelopes.where((e) => e.isActive && e.autoAllocationPercent > 0).toList();

      if (activeEnvelopes.isEmpty) return;

      final now = DateTime.now().millisecondsSinceEpoch;

      for (final envelope in activeEnvelopes) {
        final allocatedAmount = (creditAmountVnd * envelope.autoAllocationPercent / 100).round();
        if (allocatedAmount <= 0) continue;

        final newAmount = envelope.currentAmountVnd + allocatedAmount;
        await db.upsertSavingsEnvelope(
          envelope.copyWith(currentAmountVnd: newAmount).toCompanion(true),
        );

        final logId = 'log_${DateTime.now().microsecondsSinceEpoch}_${envelope.id.hashCode % 1000}';
        await db.insertSavingsLog(
          SavingsLogsCompanion.insert(
            id: logId,
            envelopeId: envelope.id,
            amountVnd: allocatedAmount,
            description: 'Tự động trích lập ${envelope.autoAllocationPercent}% từ: $description',
            timestampMs: now,
          ),
        );
      }
    });
  }

  static Future<void> depositToEnvelope(AppDb db, String envelopeId, int amountVnd, String description) async {
    if (amountVnd <= 0) return;

    await db.transaction(() async {
      final envelopes = await db.getAllSavingsEnvelopes();
      final envelope = envelopes.firstWhere((e) => e.id == envelopeId);

      final newAmount = envelope.currentAmountVnd + amountVnd;
      await db.upsertSavingsEnvelope(
        envelope.copyWith(currentAmountVnd: newAmount).toCompanion(true),
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final logId = 'log_${DateTime.now().microsecondsSinceEpoch}_${envelopeId.hashCode % 1000}';
      await db.insertSavingsLog(
        SavingsLogsCompanion.insert(
          id: logId,
          envelopeId: envelopeId,
          amountVnd: amountVnd,
          description: description.isEmpty ? 'Bỏ ống heo thủ công' : description,
          timestampMs: now,
        ),
      );
    });
  }

  static Future<void> withdrawFromEnvelope(AppDb db, String envelopeId, int amountVnd, String description) async {
    if (amountVnd <= 0) return;

    await db.transaction(() async {
      final envelopes = await db.getAllSavingsEnvelopes();
      final envelope = envelopes.firstWhere((e) => e.id == envelopeId);

      final newAmount = envelope.currentAmountVnd - amountVnd;
      await db.upsertSavingsEnvelope(
        envelope.copyWith(currentAmountVnd: newAmount).toCompanion(true),
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final logId = 'log_${DateTime.now().microsecondsSinceEpoch}_${envelopeId.hashCode % 1000}';
      await db.insertSavingsLog(
        SavingsLogsCompanion.insert(
          id: logId,
          envelopeId: envelopeId,
          amountVnd: -amountVnd,
          description: description.isEmpty ? 'Sử dụng quỹ' : description,
          timestampMs: now,
        ),
      );
    });
  }
}
