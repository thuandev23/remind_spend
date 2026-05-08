import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/core/app_exception.dart';
import 'package:remind_spend/db/app_db.dart';
import 'package:remind_spend/repositories/transaction_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel =
      MethodChannel('com.example.remind_spend/transaction_bridge');

  late AppDb db;
  late TransactionRepository repo;

  setUp(() {
    db = AppDb.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    await db.close();
  });

  void mockQueue(List<Map<String, dynamic>> items) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'getAndClearQueue') return items;
      return null;
    });
  }

  void mockQueueError() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      throw PlatformException(code: 'DB_ERROR', message: 'native db failed');
    });
  }

  // ── syncFromNative: happy path ─────────────────────────────────────────────

  test('syncFromNative persists valid transactions and returns count', () async {
    mockQueue([makeTxMap('k1', 50000), makeTxMap('k2', 75000)]);

    final count = await repo.syncFromNative();

    expect(count, 2);
    expect(await db.getAll(), hasLength(2));
  });

  test('syncFromNative returns 0 when native queue is empty', () async {
    mockQueue([]);
    expect(await repo.syncFromNative(), 0);
    expect(await db.getAll(), isEmpty);
  });

  test('syncFromNative in test environment (MissingPlugin) returns 0', () async {
    // No mock registered → MissingPluginException → BridgeService returns [].
    expect(await repo.syncFromNative(), 0);
  });

  test('syncFromNative is idempotent — duplicate ids not double-counted', () async {
    mockQueue([makeTxMap('dup', 50000)]);
    await repo.syncFromNative();

    mockQueue([makeTxMap('dup', 99000)]); // same id
    await repo.syncFromNative();

    final stored = await db.getAll();
    expect(stored, hasLength(1));
    expect(stored[0].amountVnd, 50000); // first write wins
  });

  // ── syncFromNative: validation ─────────────────────────────────────────────

  test('drops transaction with amount <= 0', () async {
    mockQueue([makeTxMap('bad', 0), makeTxMap('good', 1000)]);
    final count = await repo.syncFromNative();
    expect(count, 1);
    expect((await db.getAll()).single.id, 'good');
  });

  test('drops transaction with negative amount', () async {
    mockQueue([makeTxMap('neg', -500)]);
    expect(await repo.syncFromNative(), 0);
  });

  test('drops transaction with invalid sign', () async {
    mockQueue([makeTxMap('bad', 1000, sign: 'unknown')]);
    expect(await repo.syncFromNative(), 0);
  });

  test('drops transaction with empty bankId', () async {
    mockQueue([makeTxMap('bad', 1000, bankId: '')]);
    expect(await repo.syncFromNative(), 0);
  });

  test('accepts sign "debit"', () async {
    mockQueue([makeTxMap('d1', 5000, sign: 'debit')]);
    await repo.syncFromNative();
    expect((await db.getAll()).single.sign, 'debit');
  });

  test('accepts sign "credit"', () async {
    mockQueue([makeTxMap('c1', 5000, sign: 'credit')]);
    await repo.syncFromNative();
    expect((await db.getAll()).single.sign, 'credit');
  });

  // ── syncFromNative: error path ─────────────────────────────────────────────

  test('throws BridgePullException on platform channel error', () async {
    mockQueueError();
    expect(
      () => repo.syncFromNative(),
      throwsA(isA<BridgePullException>()),
    );
  });

  // ── watchAll / getAll ──────────────────────────────────────────────────────

  test('watchAll streams empty list initially', () {
    expect(repo.watchAll(), emits(isEmpty));
  });

  test('watchAll streams updated list after sync', () async {
    mockQueue([makeTxMap('w1', 1000)]);

    final stream = repo.watchAll();
    await expectLater(stream, emits(isEmpty));

    await repo.syncFromNative();
    await expectLater(
      stream,
      emits(predicate<List<Transaction>>(
          (list) => list.length == 1 && list[0].id == 'w1')),
    );
  });

  test('getAll returns transactions newest-first by timestampMs', () async {
    mockQueue([
      makeTxMap('old', 1000, timestampMs: 1000),
      makeTxMap('new', 2000, timestampMs: 9000),
    ]);

    await repo.syncFromNative();

    final rows = await repo.getAll();
    expect(rows[0].id, 'new');
    expect(rows[1].id, 'old');
  });
}

Map<String, dynamic> makeTxMap(
  String id,
  int amount, {
  String sign = 'debit',
  String bankId = 'vcb',
  int timestampMs = 1_700_000_000_000,
}) =>
    {
      'id': id,
      'package_name': bankId,
      'bank_id': bankId,
      'amount_vnd': amount,
      'sign': sign,
      'timestamp_ms': timestampMs,
      'created_at': timestampMs,
    };
