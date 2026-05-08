class PendingTransaction {
  final String id;           // SHA256 idempotency key
  final String packageName;
  final String bankId;
  final int amountVnd;       // đơn vị: đồng — không bao giờ double
  final String sign;         // "debit" | "credit"
  final int timestampMs;
  final int createdAt;

  const PendingTransaction({
    required this.id,
    required this.packageName,
    required this.bankId,
    required this.amountVnd,
    required this.sign,
    required this.timestampMs,
    required this.createdAt,
  });

  factory PendingTransaction.fromMap(Map<String, dynamic> map) {
    return PendingTransaction(
      id: map['id'] as String,
      packageName: map['package_name'] as String,
      bankId: map['bank_id'] as String,
      amountVnd: (map['amount_vnd'] as num).toInt(),
      sign: map['sign'] as String,
      timestampMs: (map['timestamp_ms'] as num).toInt(),
      createdAt: (map['created_at'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'package_name': packageName,
        'bank_id': bankId,
        'amount_vnd': amountVnd,
        'sign': sign,
        'timestamp_ms': timestampMs,
        'created_at': createdAt,
      };

  @override
  String toString() =>
      'PendingTransaction(id: $id, bank: $bankId, amount: $amountVnd, sign: $sign)';
}
