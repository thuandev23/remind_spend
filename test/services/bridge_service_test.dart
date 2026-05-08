import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/models/bank_rule.dart';
import 'package:remind_spend/services/bridge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // In test environment all MethodChannel calls throw MissingPluginException.
  // These tests verify the graceful fallback behavior for each method.

  group('BridgeService — MissingPluginException fallbacks', () {
    test('getAndClearQueue returns empty list when plugin absent', () async {
      final result = await BridgeService.getAndClearQueue();
      expect(result, isEmpty);
    });

    test('checkPermissionStatus returns denied when plugin absent', () async {
      final status = await BridgeService.checkPermissionStatus();
      expect(status, PermissionStatus.denied);
    });

    test('requestPermission returns false when plugin absent', () async {
      final result = await BridgeService.requestPermission();
      expect(result, isFalse);
    });

    test('getManufacturerInfo returns stock fallback when plugin absent',
        () async {
      final info = await BridgeService.getManufacturerInfo();
      expect(info.type, ManufacturerType.stock);
      expect(info.manufacturer, 'Unknown');
      expect(info.model, 'Unknown');
    });

    test('checkBatteryOptimization returns true when plugin absent', () async {
      final result = await BridgeService.checkBatteryOptimization();
      expect(result, isTrue);
    });

    test('requestBatteryOptimizationWhitelist completes without error when plugin absent',
        () async {
      await expectLater(
        BridgeService.requestBatteryOptimizationWhitelist(),
        completes,
      );
    });

    test('clearIdempotencyCache completes without error when plugin absent',
        () async {
      await expectLater(
        BridgeService.clearIdempotencyCache(),
        completes,
      );
    });

    test('updateRegexConfig completes without error when plugin absent',
        () async {
      await expectLater(
        BridgeService.updateRegexConfig([]),
        completes,
      );
    });
  });

  group('BridgeService — permission status parsing', () {
    // Test the string-to-enum parsing via checkPermissionStatus with mock channel.
    const channel = MethodChannel('com.example.remind_spend/transaction_bridge');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    void mockStatus(String status) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkPermissionStatus') return status;
        return null;
      });
    }

    test('granted string maps to PermissionStatus.granted', () async {
      mockStatus('granted');
      expect(await BridgeService.checkPermissionStatus(),
          PermissionStatus.granted);
    });

    test('denied string maps to PermissionStatus.denied', () async {
      mockStatus('denied');
      expect(
          await BridgeService.checkPermissionStatus(), PermissionStatus.denied);
    });

    test('revoked string maps to PermissionStatus.revoked', () async {
      mockStatus('revoked');
      expect(await BridgeService.checkPermissionStatus(),
          PermissionStatus.revoked);
    });

    test('restricted string maps to PermissionStatus.restricted', () async {
      mockStatus('restricted');
      expect(await BridgeService.checkPermissionStatus(),
          PermissionStatus.restricted);
    });

    test('not_applicable string maps to PermissionStatus.restricted (iOS)', () async {
      mockStatus('not_applicable');
      expect(await BridgeService.checkPermissionStatus(),
          PermissionStatus.restricted);
    });

    test('unknown string falls back to PermissionStatus.denied', () async {
      mockStatus('unknown_value');
      expect(
          await BridgeService.checkPermissionStatus(), PermissionStatus.denied);
    });
  });

  group('BridgeService — manufacturer type parsing', () {
    const channel = MethodChannel('com.example.remind_spend/transaction_bridge');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    void mockManufacturer(String type) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'getManufacturerInfo') {
          return {'manufacturer': 'Test', 'model': 'TestModel', 'type': type};
        }
        return null;
      });
    }

    test('miui type parses correctly', () async {
      mockManufacturer('miui');
      final info = await BridgeService.getManufacturerInfo();
      expect(info.type, ManufacturerType.miui);
    });

    test('oneui type parses correctly', () async {
      mockManufacturer('oneui');
      final info = await BridgeService.getManufacturerInfo();
      expect(info.type, ManufacturerType.oneui);
    });

    test('coloros type parses correctly', () async {
      mockManufacturer('coloros');
      final info = await BridgeService.getManufacturerInfo();
      expect(info.type, ManufacturerType.coloros);
    });

    test('unknown type falls back to stock', () async {
      mockManufacturer('unknown_oem');
      final info = await BridgeService.getManufacturerInfo();
      expect(info.type, ManufacturerType.stock);
    });
  });

  group('BridgeService — updateRegexConfig', () {
    const channel = MethodChannel('com.example.remind_spend/transaction_bridge');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('sends serialised rule list to native channel', () async {
      List<dynamic>? captured;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'updateRegexConfig') {
          captured = call.arguments as List<dynamic>;
        }
        return null;
      });

      const rule = BankRule(
        bankId: 'vcb',
        packageNames: ['com.VCB'],
        patterns: [r'([0-9]+) VND'],
        sign: 'debit',
      );
      await BridgeService.updateRegexConfig([rule]);

      expect(captured, isNotNull);
      expect(captured!.length, 1);
      final sent = Map<String, dynamic>.from(captured!.first as Map);
      expect(sent['bank_id'], 'vcb');
      expect(sent['sign'], 'debit');
      expect((sent['package_names'] as List).first, 'com.VCB');
    });
  });

  group('BridgeService — PlatformException propagation', () {
    const channel = MethodChannel('com.example.remind_spend/transaction_bridge');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('PlatformException from checkPermissionStatus is rethrown as BridgeError',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'TEST_ERROR', message: 'test');
      });

      expect(
        () => BridgeService.checkPermissionStatus(),
        throwsA(isA<BridgeError>().having(
          (e) => e.code,
          'code',
          'TEST_ERROR',
        )),
      );
    });
  });
}
