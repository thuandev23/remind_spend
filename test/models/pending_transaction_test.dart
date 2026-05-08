import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/models/pending_transaction.dart';

void main() {
  group('PendingTransaction.fromMap', () {
    test('parses all fields correctly', () {
      final map = {
        'id': 'sha256_key_001',
        'package_name': 'com.VCB',
        'bank_id': 'vcb',
        'amount_vnd': 50000,
        'sign': 'debit',
        'timestamp_ms': 1700000000000,
        'created_at': 1700000000001,
      };

      final tx = PendingTransaction.fromMap(map);

      expect(tx.id, 'sha256_key_001');
      expect(tx.packageName, 'com.VCB');
      expect(tx.bankId, 'vcb');
      expect(tx.amountVnd, 50000);
      expect(tx.sign, 'debit');
      expect(tx.timestampMs, 1700000000000);
      expect(tx.createdAt, 1700000000001);
    });

    test('amountVnd is always int (không double)', () {
      final map = {
        'id': 'k1',
        'package_name': 'com.VCB',
        'bank_id': 'vcb',
        'amount_vnd': 50000.0,  // native có thể trả về double
        'sign': 'debit',
        'timestamp_ms': 0,
        'created_at': 0,
      };
      final tx = PendingTransaction.fromMap(map);
      expect(tx.amountVnd, isA<int>());
      expect(tx.amountVnd, 50000);
    });

    test('roundtrip fromMap → toMap giữ nguyên dữ liệu', () {
      final original = {
        'id': 'abc123',
        'package_name': 'com.mbmobile',
        'bank_id': 'mb',
        'amount_vnd': 200000,
        'sign': 'credit',
        'timestamp_ms': 9999999,
        'created_at': 8888888,
      };

      final tx = PendingTransaction.fromMap(original);
      final result = tx.toMap();

      expect(result['id'], original['id']);
      expect(result['bank_id'], original['bank_id']);
      expect(result['amount_vnd'], original['amount_vnd']);
      expect(result['sign'], original['sign']);
    });
  });
}
