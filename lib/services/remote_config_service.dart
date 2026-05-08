import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_logger.dart';
import '../db/app_db.dart';
import '../models/bank_rule.dart';
import 'bridge_service.dart';

const _tag = 'RemoteConfigService';

/// 3-tier regex config resolution.
///
/// Tier 1 — Remote API  (fetched on app start, background refresh)
/// Tier 2 — Drift cache (last successful fetch, valid for 7 days)
/// Tier 3 — Hardcoded   (built-in fallback, never stale)
///
/// Set the config URL at build time:
///   flutter build apk --dart-define=REGEX_CONFIG_URL=https://example.com/config.json
class RemoteConfigService {
  static const _envConfigUrl =
      String.fromEnvironment('REGEX_CONFIG_URL', defaultValue: '');
  static const _timeoutMs = 2000;
  static const _cacheMaxAgeMs = 7 * 24 * 60 * 60 * 1000; // 7 days

  final AppDb _db;
  final http.Client _client;
  final String _configUrl;

  RemoteConfigService(this._db, {http.Client? client, String? configUrl})
      : _client = client ?? http.Client(),
        _configUrl = configUrl ?? _envConfigUrl;

  /// Returns the best available set of rules via the 3-tier fallback.
  /// Never throws — Tier 3 is always available.
  Future<List<BankRule>> resolve() async {
    // ── Tier 1: Remote API ────────────────────────────────────────────────
    if (_configUrl.isNotEmpty) {
      try {
        final rules = await _fetchRemote();
        await _saveToCache(rules);
        _pushToNative(rules); // fire-and-forget
        AppLogger.info(_tag, 'Tier 1: ${rules.length} rules from remote');
        return rules;
      } catch (e) {
        AppLogger.warn(_tag, 'Tier 1 failed, falling back: $e');
      }
    }

    // ── Tier 2: Local Drift cache ─────────────────────────────────────────
    try {
      final cached = await _loadFromCache();
      if (cached.isNotEmpty) {
        _pushToNative(cached); // fire-and-forget
        AppLogger.info(_tag, 'Tier 2: ${cached.length} rules from cache');
        return cached;
      }
    } catch (e) {
      AppLogger.warn(_tag, 'Tier 2 failed: $e');
    }

    // ── Tier 3: Hardcoded fallback ────────────────────────────────────────
    AppLogger.warn(_tag, 'Tier 3: using hardcoded rules');
    return hardcodedRules;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<List<BankRule>> _fetchRemote() async {
    final uri = Uri.parse(_configUrl);
    final response = await _client
        .get(uri)
        .timeout(const Duration(milliseconds: _timeoutMs));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rules = (decoded['rules'] as List<dynamic>)
        .map((r) => BankRule.fromJson(r as Map<String, dynamic>))
        .toList();
    if (rules.isEmpty) throw Exception('Empty rule set from remote');
    return rules;
  }

  Future<void> _saveToCache(List<BankRule> rules) async {
    final version = DateTime.now().millisecondsSinceEpoch;
    await _db.clearRegexConfig();
    for (final rule in rules) {
      await _db.upsertRegexConfig(rule.toCacheCompanion(version));
    }
  }

  Future<List<BankRule>> _loadFromCache() async {
    final entries = await _db.getAllRegexConfig();
    if (entries.isEmpty) return [];

    final cutoff = DateTime.now().millisecondsSinceEpoch - _cacheMaxAgeMs;
    final fresh = entries.where((e) => e.fetchedAt >= cutoff).toList();
    if (fresh.isEmpty) {
      AppLogger.warn(_tag, 'Cache expired (>7 days old)');
      return [];
    }
    return fresh.map((e) => e.toBankRule()).toList();
  }

  void _pushToNative(List<BankRule> rules) {
    BridgeService.updateRegexConfig(rules).catchError((Object e) {
      AppLogger.warn(_tag, 'pushToNative failed: $e');
    });
  }
}

// ── Tier 3: Hardcoded fallback ────────────────────────────────────────────────
// Mirrors Android RegexConfigLoader.hardcodedRules and iOS BankRegexParser.rules.
// Update here AND in native code when adding new banks.
const hardcodedRules = [
  BankRule(
    bankId: 'vcb',
    packageNames: ['com.VCB'],
    patterns: [
      r'GD: ?-([0-9,.]+) ?VND',
      r'Debit: ?([0-9,.]+) ?VND',
      r'So du TK[^:]*: ?([0-9,.]+) ?VND',
      r'So du: ?([0-9,.]+) ?VND',
    ],
    sign: 'debit',
  ),
  BankRule(
    bankId: 'mb',
    packageNames: ['com.mbmobile'],
    patterns: [
      r'(?:chi|giao dịch)[^0-9]*([0-9,.]+) ?đ',
      r'Số dư: ?([0-9,.]+) ?đ',
      r'So du: ?([0-9,.]+)',
    ],
    sign: 'debit',
  ),
  BankRule(
    bankId: 'tcb',
    packageNames: ['com.techcombank.mb.portal'],
    patterns: [
      r'GD: ?-([0-9,.]+)VND',
      r'([0-9,.]+) VND',
    ],
    sign: 'debit',
  ),
  BankRule(
    bankId: 'acb',
    packageNames: ['com.acb'],
    patterns: [
      r'([0-9,.]+) VND',
      r'([0-9,.]+)VND',
    ],
    sign: 'debit',
  ),
  BankRule(
    bankId: 'momo',
    packageNames: ['com.mservice.momotransfer'],
    patterns: [
      r'(?:chi|thanh toán)[^0-9]*([0-9,.]+)đ',
      r'Bạn đã (?:chi|gửi)[^0-9]*([0-9,.]+)(?:đ|VND)',
    ],
    sign: 'debit',
  ),
  BankRule(
    bankId: 'zalopay',
    packageNames: ['com.vnpay.zalopay'],
    patterns: [
      r'(?:chi|thanh toán)[^0-9]*([0-9,.]+)(?:đ|VND)',
    ],
    sign: 'debit',
  ),
];
