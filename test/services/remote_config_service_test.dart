import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:remind_spend/db/app_db.dart';
import 'package:remind_spend/models/bank_rule.dart';
import 'package:remind_spend/services/remote_config_service.dart';

AppDb _makeDb() => AppDb.forTesting(NativeDatabase.memory());

const _remotePayload = {
  'rules': [
    {
      'bank_id': 'test_bank',
      'package_names': ['com.test'],
      'patterns': [r'([0-9]+)'],
      'amount_group': 1,
      'sign': 'debit',
    }
  ]
};

http.Client _clientWith({int status = 200, Map<String, dynamic>? body}) =>
    MockClient(
      (_) async => http.Response(jsonEncode(body ?? _remotePayload), status),
    );

http.Client _failingClient() =>
    MockClient((_) async => throw Exception('network error'));

RemoteConfigService _svc(
  AppDb db, {
  http.Client? client,
  String url = 'https://example.com/config.json',
}) =>
    RemoteConfigService(db, client: client, configUrl: url);

void main() {
  group('RemoteConfigService', () {
    late AppDb db;

    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    // ── Tier 1 ───────────────────────────────────────────────────────────────

    test('Tier 1: returns remote rules', () async {
      final rules = await _svc(db, client: _clientWith()).resolve();

      expect(rules.length, 1);
      expect(rules.first.bankId, 'test_bank');
    });

    test('Tier 1: caches rules in Drift after successful fetch', () async {
      await _svc(db, client: _clientWith()).resolve();

      final cached = await db.getAllRegexConfig();
      expect(cached.length, 1);
      expect(cached.first.bankId, 'test_bank');
    });

    test('Tier 1: non-200 falls back through Tier 2 to Tier 3', () async {
      final rules = await _svc(db, client: _clientWith(status: 500)).resolve();

      expect(rules, isNotEmpty);
      expect(rules.any((r) => r.bankId == 'vcb'), isTrue);
    });

    test('Tier 1: empty rule set falls back to Tier 3', () async {
      final rules = await _svc(
        db,
        client: _clientWith(body: {'rules': []}),
      ).resolve();

      expect(rules.any((r) => r.bankId == 'vcb'), isTrue);
    });

    test('Tier 1: network failure falls back to Tier 2 cache', () async {
      // Seed the cache via a successful fetch first
      await _svc(db, client: _clientWith()).resolve();

      // Now fail the network — should hit Tier 2
      final rules = await _svc(db, client: _failingClient()).resolve();

      expect(rules.length, 1);
      expect(rules.first.bankId, 'test_bank');
    });

    // ── Tier 2 ───────────────────────────────────────────────────────────────

    test('Tier 2: fresh cache used when URL not configured', () async {
      // Seed via explicit URL, then query without URL (env default is '')
      await _svc(db, client: _clientWith()).resolve();

      final rules = await _svc(db, url: '').resolve();

      expect(rules.length, 1);
      expect(rules.first.bankId, 'test_bank');
    });

    test('Tier 2: expired cache (>7 days) falls back to Tier 3', () async {
      final oldFetchedAt =
          DateTime.now().millisecondsSinceEpoch - 8 * 24 * 60 * 60 * 1000;
      await db.upsertRegexConfig(
        BankRule(
          bankId: 'old_bank',
          packageNames: ['com.old'],
          patterns: [r'([0-9]+)'],
          sign: 'debit',
        ).toCacheCompanion(1, fetchedAt: oldFetchedAt),
      );

      final rules = await _svc(db, url: '').resolve();

      expect(rules.any((r) => r.bankId == 'vcb'), isTrue);
      expect(rules.any((r) => r.bankId == 'old_bank'), isFalse);
    });

    // ── Tier 3 ───────────────────────────────────────────────────────────────

    test('Tier 3: hardcoded rules used when no URL and no cache', () async {
      final rules = await _svc(db, url: '').resolve();

      expect(rules, equals(hardcodedRules));
    });

    test('hardcodedRules contains expected banks', () {
      final bankIds = hardcodedRules.map((r) => r.bankId).toSet();
      expect(bankIds, containsAll(['vcb', 'mb', 'tcb', 'acb', 'momo', 'zalopay']));
    });
  });
}
