import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/db/app_db.dart';
import 'package:remind_spend/repositories/transaction_repository.dart';
import 'package:remind_spend/services/pull_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel =
      MethodChannel('com.example.remind_spend/transaction_bridge');

  late AppDb db;
  late TransactionRepository repo;
  late PullService service;

  setUp(() {
    db = AppDb.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);
    service = PullService(repo);
  });

  tearDown(() async {
    service.stop();
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

  // ── pull() ────────────────────────────────────────────────────────────────

  test('pull() persists items and returns count', () async {
    mockQueue([_txMap('p1', 10000), _txMap('p2', 20000)]);
    expect(await service.pull(), 2);
    expect(await db.getAll(), hasLength(2));
  });

  test('pull() returns 0 when queue is empty', () async {
    mockQueue([]);
    expect(await service.pull(), 0);
  });

  test('pull() swallows BridgePullException and returns 0', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      throw PlatformException(code: 'ERR', message: 'fail');
    });

    // PullService should not rethrow — fire-and-forget contract.
    expect(await service.pull(), 0);
  });

  test('concurrent pull() calls are coalesced — DB not hit twice', () async {
    var callCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'getAndClearQueue') {
        callCount++;
        // Small delay to make the first pull "in progress" when the second starts.
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return [_txMap('x$callCount', 1000)];
      }
      return null;
    });

    // Fire two pulls concurrently.
    final results = await Future.wait([service.pull(), service.pull()]);

    // One of them was skipped (returned 0), the other wrote 1 row.
    expect(results, containsAll([0, 1]));
    expect(await db.getAll(), hasLength(1));
  });

  // ── lifecycle ─────────────────────────────────────────────────────────────

  test('start() / stop() do not throw', () {
    service.start();
    service.stop();
  });

  test('didChangeAppLifecycleState resumed triggers a pull', () async {
    mockQueue([_txMap('lc', 5000)]);
    service.start();

    service.didChangeAppLifecycleState(AppLifecycleState.resumed);

    // The pull is fire-and-forget; give it a tick to complete.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await db.getAll(), hasLength(1));
  });

  test('didChangeAppLifecycleState paused does not trigger a pull', () async {
    mockQueue([_txMap('lc', 5000)]);
    service.start();

    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(await db.getAll(), isEmpty);
  });
}

Map<String, dynamic> _txMap(String id, int amount) => {
      'id': id,
      'package_name': 'vcb',
      'bank_id': 'vcb',
      'amount_vnd': amount,
      'sign': 'debit',
      'timestamp_ms': 1_700_000_000_000,
      'created_at': 1_700_000_000_000,
    };
