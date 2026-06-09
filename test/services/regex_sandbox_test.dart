import 'dart:convert';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remind_spend/db/app_db.dart';
import 'package:remind_spend/models/bank_rule.dart';
import 'package:remind_spend/services/regex_sync_service.dart';
import 'package:remind_spend/services/remote_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel =
      MethodChannel('com.example.remind_spend/transaction_bridge');

  late AppDb db;
  late RemoteConfigService remoteService;
  final List<BankRule> capturedRules = [];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDb.forTesting(NativeDatabase.memory());
    remoteService = RemoteConfigService(db);
    capturedRules.clear();

    // Mock MethodChannel để bắt các cuộc gọi updateRegexConfig
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'updateRegexConfig') {
        final List<dynamic> args = call.arguments as List<dynamic>;
        capturedRules.addAll(args.map((r) => BankRule.fromJson(Map<String, dynamic>.from(r as Map))));
        return null;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    await db.close();
  });

  // Helper hàm testParse mô phỏng logic Sandbox trên UI Flutter
  Map<String, dynamic> testParse(String text, String patternStr) {
    if (patternStr.isEmpty) {
      return {'matched': false, 'error': null, 'amount': null};
    }
    try {
      final regex = RegExp(patternStr, caseSensitive: false);
      final match = regex.firstMatch(text);
      if (match != null) {
        if (match.groupCount >= 1) {
          final amountStr = match.group(1);
          if (amountStr != null) {
            final cleanStr = amountStr.replaceAll(RegExp(r'[^0-9]'), '');
            final parsed = int.tryParse(cleanStr);
            if (parsed != null && parsed > 0) {
              return {'matched': true, 'error': null, 'amount': parsed};
            }
          }
        }
        return {'matched': false, 'error': 'Group 1 empty', 'amount': null};
      }
    } catch (e) {
      return {'matched': false, 'error': e.toString(), 'amount': null};
    }
    return {'matched': false, 'error': 'No match', 'amount': null};
  }

  group('Regex Sandbox - So khớp Realtime Parser', () {
    test('1. So khớp tin nhắn mẫu thành công và trích xuất đúng số tiền', () {
      // Test pattern VCB
      final res = testParse(
        'GD: -150,000 VND tai Highlands Coffee. SD: 5,000,000 VND.',
        r'GD: ?-([0-9,.]+) ?VND',
      );
      expect(res['matched'], isTrue);
      expect(res['amount'], 150000);
      expect(res['error'], isNull);

      // Test pattern ACB
      final resAcb = testParse(
        'ACB: Tru tai khoan 1,250,000 VND tai sieu thi.',
        r'Tru tai khoan ([0-9,.]+) VND',
      );
      expect(resAcb['matched'], isTrue);
      expect(resAcb['amount'], 1250000);
      expect(resAcb['error'], isNull);
    });

    test('2. Trả về lỗi khi không tìm thấy kết quả khớp trong tin nhắn mẫu', () {
      final res = testParse(
        'Tin nhan khong lien quan den ngan hang',
        r'GD: ?-([0-9,.]+) ?VND',
      );
      expect(res['matched'], isFalse);
      expect(res['amount'], isNull);
      expect(res['error'], 'No match');
    });

    test('3. Trả về lỗi an toàn khi Regex pattern bị sai cú pháp (không crash)', () {
      final res = testParse(
        'ACB: Tru tai khoan 150,000 VND',
        r'Tru tai khoan ([0-9,.]+ VND', // Thiếu ngoặc đóng )
      );
      expect(res['matched'], isFalse);
      expect(res['amount'], isNull);
      expect(res['error'], contains('FormatException'));
    });
  });

  group('CustomRegexRules - SQLite CRUD & Migration', () {
    test('4. Thực hiện CRUD Custom Regex Rules vào Drift SQLite thành công', () async {
      // 1. Kiểm tra ban đầu rỗng
      var rules = await db.getAllCustomRegexRules();
      expect(rules, isEmpty);

      // 2. Thêm mới Custom Rule
      final ruleCompanion = CustomRegexRulesCompanion.insert(
        id: 'rule1',
        bankId: 'vcb_custom',
        name: 'VCB Custom',
        packageNamesJson: jsonEncode(['com.VCB']),
        patternsJson: jsonEncode([r'GD: ?-([0-9,.]+) ?VND']),
        sign: 'debit',
        isActive: const Value(true),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await db.upsertCustomRegexRule(ruleCompanion);
      
      rules = await db.getAllCustomRegexRules();
      expect(rules, hasLength(1));
      expect(rules.first.id, 'rule1');
      expect(rules.first.name, 'VCB Custom');

      // 3. Sửa Custom Rule (Đổi trạng thái Active)
      final updateCompanion = CustomRegexRulesCompanion(
        id: const Value('rule1'),
        isActive: const Value(false),
      );
      await db.updateCustomRegexRule('rule1', updateCompanion);

      rules = await db.getAllCustomRegexRules();
      expect(rules.first.isActive, isFalse);

      // 4. Xoá Custom Rule
      await db.deleteCustomRegexRule('rule1');
      rules = await db.getAllCustomRegexRules();
      expect(rules, isEmpty);
    });
  });

  group('RegexSyncService - Hợp nhất & Ưu tiên Rules (Unified Sync)', () {
    test('5. syncAllRules gộp Custom Rules và System Rules, Custom Rules xếp đầu danh sách', () async {
      // 1. Thêm 1 Custom Rule hoạt động
      final custom1 = CustomRegexRulesCompanion.insert(
        id: 'c1',
        bankId: 'acb_custom',
        name: 'ACB Custom',
        packageNamesJson: jsonEncode(['com.acb']),
        patternsJson: jsonEncode([r'Tru tai khoan ([0-9,.]+) VND']),
        sign: 'debit',
        isActive: const Value(true),
        createdAt: 1000,
      );
      await db.upsertCustomRegexRule(custom1);

      // 2. Thêm 1 Custom Rule bị tắt (isActive = false, không được đồng bộ)
      final custom2 = CustomRegexRulesCompanion.insert(
        id: 'c2',
        bankId: 'momo_custom',
        name: 'Momo Custom',
        packageNamesJson: jsonEncode(['com.mservice']),
        patternsJson: jsonEncode([r'chi ([0-9,.]+) đ']),
        sign: 'debit',
        isActive: const Value(false),
        createdAt: 2000,
      );
      await db.upsertCustomRegexRule(custom2);

      // 3. Thực hiện đồng bộ hợp nhất
      await RegexSyncService.syncAllRules(db, remoteService);

      // 4. Xác nhận cuộc gọi MethodChannel nhận được rules gộp
      expect(capturedRules, isNotEmpty);
      
      // Custom rule c1 phải nằm ngay ĐẦU DANH SÁCH (index 0) để ưu tiên matching trước
      expect(capturedRules.first.bankId, 'acb_custom');
      expect(capturedRules.first.patterns.first, r'Tru tai khoan ([0-9,.]+) VND');
      expect(capturedRules.first.sign, 'debit');

      // Custom rule c2 (bị tắt) không được xuất hiện
      final hasC2 = capturedRules.any((r) => r.bankId == 'momo_custom');
      expect(hasC2, isFalse);

      // Theo sau c1 phải là các system rules mặc định (như vcb, mb...) từ remote config fallback
      final hasVcbSystem = capturedRules.any((r) => r.bankId == 'vcb');
      expect(hasVcbSystem, isTrue);
      
      // ACB hệ thống vẫn tồn tại đằng sau custom rule
      final acbRules = capturedRules.where((r) => r.bankId == 'acb').toList();
      expect(acbRules, isNotEmpty);
    });
  });
}
