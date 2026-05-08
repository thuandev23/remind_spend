import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/db/app_db.dart';

void main() {
  late AppDb db;

  setUp(() {
    db = AppDb.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  // ── insertTransaction ──────────────────────────────────────────────────────

  test('insertTransaction persists a row', () async {
    await db.insertTransaction(makeEntry('k1', 50000));
    final rows = await db.getAll();
    expect(rows.length, 1);
    expect(rows[0].id, 'k1');
  });

  test('insertTransaction with duplicate id is silently ignored', () async {
    await db.insertTransaction(makeEntry('dup', 50000));
    await db.insertTransaction(makeEntry('dup', 99000)); // same id

    final rows = await db.getAll();
    expect(rows.length, 1);
    expect(rows[0].amountVnd, 50000); // first write wins
  });

  test('getAll returns rows newest-first', () async {
    await db.insertTransaction(makeEntry('old', 1000, timestampMs: 1000));
    await db.insertTransaction(makeEntry('new', 2000, timestampMs: 9000));
    await db.insertTransaction(makeEntry('mid', 1500, timestampMs: 5000));

    final rows = await db.getAll();
    expect(rows.map((r) => r.id).toList(), ['new', 'mid', 'old']);
  });

  test('getAll returns empty list when table is empty', () async {
    expect(await db.getAll(), isEmpty);
  });

  // ── watchAll ───────────────────────────────────────────────────────────────

  test('watchAll emits initial empty list', () async {
    expect(db.watchAll(), emits(isEmpty));
  });

  test('watchAll emits updated list after insert', () async {
    final stream = db.watchAll();

    // First emission: empty
    await expectLater(stream, emits(isEmpty));

    // Insert, then stream should emit the new row
    await db.insertTransaction(makeEntry('w1', 30000));
    await expectLater(
      stream,
      emits(predicate<List<Transaction>>((list) =>
          list.length == 1 && list[0].id == 'w1')),
    );
  });

  // ── Amount integrity ───────────────────────────────────────────────────────

  test('amountVnd is stored and retrieved exactly (Int64)', () async {
    const large = 9_999_999_999; // > 32-bit max
    await db.insertTransaction(makeEntry('big', large));
    final rows = await db.getAll();
    expect(rows[0].amountVnd, large);
  });

  test('sign is stored verbatim', () async {
    await db.insertTransaction(makeEntry('d', 1000, sign: 'debit'));
    await db.insertTransaction(makeEntry('c', 2000, sign: 'credit'));

    final rows = await db.getAll();
    final signs = rows.map((r) => r.sign).toSet();
    expect(signs, containsAll(['debit', 'credit']));
  });

  test('syncedAt defaults to null', () async {
    await db.insertTransaction(makeEntry('s1', 1000));
    final rows = await db.getAll();
    expect(rows[0].syncedAt, isNull);
  });
}

// ── Test helpers ──────────────────────────────────────────────────────────────

TransactionsCompanion makeEntry(
  String id,
  int amount, {
  String sign = 'debit',
  int timestampMs = 1_700_000_000_000,
}) =>
    TransactionsCompanion.insert(
      id: id,
      bankId: 'vcb',
      amountVnd: amount,
      sign: sign,
      timestampMs: timestampMs,
      createdAt: 1_700_000_000_000,
    );
