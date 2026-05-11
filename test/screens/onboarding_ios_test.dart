import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remind_spend/screens/onboarding_ios.dart';

// ── Channel mock helpers ──────────────────────────────────────────────────────

const _ch = MethodChannel('com.example.remind_spend/transaction_bridge');

void _mockBridge({
  List<String> detected = const [],
  List<Map<String, dynamic>> queue = const [],
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ch, (call) async {
    return switch (call.method) {
      'detectInstalledFinanceApps'         => detected,
      'getAndClearQueue'                   => queue,
      'requestPermission'                  => true,
      'requestLocalNotificationPermission' => true,
      _                                    => null,
    };
  });
}

void _clearMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_ch, null);
}

// ── Widget factory ────────────────────────────────────────────────────────────

Widget _widget({VoidCallback? onGrant, VoidCallback? onVerified}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: IosShortcutStep(
          onGrant: onGrant ?? () {},
          onVerified: onVerified ?? () {},
        ),
      ),
    ),
  );
}

// ── Navigation helpers ────────────────────────────────────────────────────────

// Step 1 → Step 2 (selectApps) or Step 3 (installShortcut when no apps)
// Taps the ElevatedButton "Cho phép thông báo" and waits for detection to complete.
Future<void> _grantPermission(WidgetTester t) async {
  await t.tap(find.widgetWithText(ElevatedButton, 'Cho phép thông báo'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

// Step 1 → skip permission → Step 2 or Step 3
Future<void> _skipPermission(WidgetTester t) async {
  await t.tap(find.text('Bỏ qua'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

// → Step 3 (installShortcut) via select-apps "Tiếp tục"
Future<void> _goToInstallShortcut(WidgetTester t) async {
  await _grantPermission(t);
  await t.tap(find.text('Tiếp tục'));
  await t.pump();
}

// → Step 4 (smsAutomation)
Future<void> _goToSmsStep(WidgetTester t) async {
  await _goToInstallShortcut(t);
  await t.tap(find.text('Mở app Phím tắt'));
  await t.pump();
  await t.tap(find.text('Đã cài xong → Tiếp tục'));
  await t.pumpAndSettle();
}

// → Step 5 (notifAutomation) — requires queue non-empty to pass SMS verify
Future<void> _goToNotifStep(WidgetTester t) async {
  await _goToSmsStep(t);
  await t.tap(find.widgetWithText(ElevatedButton, 'Đã setup → Kiểm tra'));
  await t.pump();
  await t.pump(const Duration(milliseconds: 100));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(_clearMock);

  // ── Step 1: Notification Permission ────────────────────────────────────────

  group('Step 1 — Notification Permission', () {
    testWidgets('shows permission screen on first render', (t) async {
      _mockBridge();
      await t.pumpWidget(_widget());

      expect(find.text('Cho phép thông báo'), findsWidgets);
      expect(find.text('Bỏ qua'), findsOneWidget);
    });

    testWidgets('shows reason rows', (t) async {
      _mockBridge();
      await t.pumpWidget(_widget());

      expect(find.textContaining('Thông báo tức thì'), findsOneWidget);
      expect(find.textContaining('không đọc tin nhắn'), findsOneWidget);
      expect(find.textContaining('Cài đặt'), findsOneWidget);
    });

    testWidgets('tapping permission button calls onGrant', (t) async {
      _mockBridge();
      bool granted = false;
      await t.pumpWidget(_widget(onGrant: () => granted = true));

      await t.tap(find.widgetWithText(ElevatedButton, 'Cho phép thông báo'));
      await t.pump();

      expect(granted, isTrue);
    });

    testWidgets('advances to selectApps when apps detected', (t) async {
      _mockBridge(detected: ['vcb', 'momo']);
      await t.pumpWidget(_widget());

      await _grantPermission(t);

      expect(find.text('Bạn dùng app nào?'), findsOneWidget);
    });

    testWidgets('skips selectApps when no apps detected', (t) async {
      _mockBridge(detected: []);
      await t.pumpWidget(_widget());

      await _grantPermission(t);

      expect(find.text('Cài phím tắt'), findsOneWidget);
      expect(find.text('Bạn dùng app nào?'), findsNothing);
    });

    testWidgets('skip button also detects apps and advances', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());

      await _skipPermission(t);

      expect(find.text('Bạn dùng app nào?'), findsOneWidget);
    });
  });

  // ── Step 2: Select Apps ─────────────────────────────────────────────────────

  group('Step 2 — Select Apps', () {
    testWidgets('shows only detected apps, not all apps', (t) async {
      _mockBridge(detected: ['vcb', 'momo']);
      await t.pumpWidget(_widget());
      await _grantPermission(t);

      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('MoMo'), findsOneWidget);
      // Non-detected apps should NOT appear
      expect(find.text('MB Bank'), findsNothing);
      expect(find.text('ZaloPay'), findsNothing);
    });

    testWidgets('shows bank section for detected bank apps', (t) async {
      _mockBridge(detected: ['vcb', 'mb']);
      await t.pumpWidget(_widget());
      await _grantPermission(t);

      expect(find.text('Ngân hàng'), findsOneWidget);
      expect(find.text('Ví điện tử'), findsNothing);
    });

    testWidgets('shows wallet section for detected wallet apps', (t) async {
      _mockBridge(detected: ['momo']);
      await t.pumpWidget(_widget());
      await _grantPermission(t);

      expect(find.text('Ví điện tử'), findsOneWidget);
      expect(find.text('Ngân hàng'), findsNothing);
    });

    testWidgets('tapping chip toggles selection', (t) async {
      _mockBridge(detected: ['vcb', 'momo']);
      await t.pumpWidget(_widget());
      await _grantPermission(t);

      await t.tap(find.text('Vietcombank'));
      await t.pump();
      await t.tap(find.text('Vietcombank'));
      await t.pump();

      expect(find.text('Bạn dùng app nào?'), findsOneWidget);
    });

    testWidgets('continue advances to installShortcut', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _grantPermission(t);

      await t.tap(find.text('Tiếp tục'));
      await t.pump();

      expect(find.text('Cài phím tắt'), findsOneWidget);
    });
  });

  // ── Step 3: Install Shortcut ────────────────────────────────────────────────

  group('Step 3 — Install Shortcut', () {
    testWidgets('shows install shortcut screen', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _goToInstallShortcut(t);

      expect(find.text('Cài phím tắt'), findsOneWidget);
      expect(find.text('Đã cài xong → Tiếp tục'), findsOneWidget);
    });

    testWidgets('continue button disabled until shortcuts opened', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _goToInstallShortcut(t);

      final btn = t.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Đã cài xong → Tiếp tục'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('tapping open shortcuts enables continue button', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _goToInstallShortcut(t);

      await t.tap(find.text('Mở app Phím tắt'));
      await t.pump();

      final btn = t.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Đã cài xong → Tiếp tục'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('continue advances to SMS automation', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _goToSmsStep(t);

      expect(find.text('Tự động hóa SMS'), findsOneWidget);
    });
  });

  // ── Step 4: SMS Automation ──────────────────────────────────────────────────

  group('Step 4 — SMS Automation', () {
    testWidgets('shows SMS automation screen', (t) async {
      _mockBridge(detected: ['vcb', 'mb']);
      await t.pumpWidget(_widget());
      await _goToSmsStep(t);

      expect(find.text('Tự động hóa SMS'), findsOneWidget);
    });

    testWidgets('subtitle shows selected bank names', (t) async {
      _mockBridge(detected: ['vcb', 'mb']);
      await t.pumpWidget(_widget());
      await _goToSmsStep(t);

      expect(find.textContaining('Vietcombank'), findsOneWidget);
      expect(find.textContaining('MB Bank'), findsOneWidget);
    });

    testWidgets('shows generic label when no banks detected', (t) async {
      _mockBridge(detected: []);
      await t.pumpWidget(_widget());
      // No apps → skip selectApps, go straight to install
      await t.tap(find.text('Cho phép thông báo'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      // Now at installShortcut
      await t.tap(find.text('Mở app Phím tắt'));
      await t.pump();
      await t.tap(find.text('Đã cài xong → Tiếp tục'));
      await t.pump();

      expect(find.textContaining('tất cả ngân hàng'), findsOneWidget);
    });

    testWidgets('no progress badge when no wallet apps', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _goToSmsStep(t);

      expect(find.text('1 / 1'), findsNothing);
    });

    testWidgets('shows 1/2 progress badge when MoMo selected', (t) async {
      _mockBridge(detected: ['vcb', 'momo']);
      await t.pumpWidget(_widget());
      await _goToSmsStep(t);

      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('verify with empty queue shows error', (t) async {
      _mockBridge(detected: ['vcb'], queue: []);
      await t.pumpWidget(_widget());
      await _goToSmsStep(t);

      await t.tap(find.widgetWithText(ElevatedButton, 'Đã setup → Kiểm tra'));
      await t.pumpAndSettle();

      expect(find.textContaining('Chưa nhận được dữ liệu'), findsOneWidget);
    });

    testWidgets('verify with non-empty queue calls onVerified (bank only)',
        (t) async {
      bool verified = false;
      _mockBridge(
        detected: ['vcb'],
        queue: [
          {
            'id': 'tx-1',
            'package_name': 'vcb',
            'bank_id': 'vcb',
            'amount_vnd': 100000,
            'sign': 'credit',
            'timestamp_ms': 1_700_000_000_000,
            'created_at': 1_700_000_000_000,
            'raw_content': null,
          }
        ],
      );
      await t.pumpWidget(_widget(onVerified: () => verified = true));
      await _goToSmsStep(t);

      await t.tap(find.widgetWithText(ElevatedButton, 'Đã setup → Kiểm tra'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(verified, isTrue);
    });

    testWidgets('verify passes → advances to notif step when wallet selected',
        (t) async {
      _mockBridge(
        detected: ['vcb', 'momo'],
        queue: [
          {
            'id': 'tx-1',
            'package_name': 'vcb',
            'bank_id': 'vcb',
            'amount_vnd': 100000,
            'sign': 'credit',
            'timestamp_ms': 1_700_000_000_000,
            'created_at': 1_700_000_000_000,
            'raw_content': null,
          }
        ],
      );
      await t.pumpWidget(_widget());
      await _goToSmsStep(t);

      await t.tap(find.widgetWithText(ElevatedButton, 'Đã setup → Kiểm tra'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(find.text('Tự động hóa Thông báo'), findsOneWidget);
    });
  });

  // ── Step 5: Notification Automation ────────────────────────────────────────

  group('Step 5 — Notification Automation', () {
    testWidgets('shows notification step for MoMo', (t) async {
      _mockBridge(
        detected: ['vcb', 'momo'],
        queue: [
          {
            'id': 'tx-1',
            'package_name': 'vcb',
            'bank_id': 'vcb',
            'amount_vnd': 100000,
            'sign': 'credit',
            'timestamp_ms': 1_700_000_000_000,
            'created_at': 1_700_000_000_000,
            'raw_content': null,
          }
        ],
      );
      await t.pumpWidget(_widget());
      await _goToNotifStep(t);

      expect(find.text('Tự động hóa Thông báo'), findsOneWidget);
      expect(find.textContaining('MoMo'), findsWidgets);
      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('cycles MoMo → ZaloPay when both selected', (t) async {
      _mockBridge(
        detected: ['momo', 'zalopay'],
        queue: [
          {
            'id': 'tx-1',
            'package_name': 'momo',
            'bank_id': 'momo',
            'amount_vnd': 150000,
            'sign': 'credit',
            'timestamp_ms': 1_700_000_000_000,
            'created_at': 1_700_000_000_000,
            'raw_content': null,
          }
        ],
      );
      await t.pumpWidget(_widget());
      await _goToNotifStep(t);

      // MoMo at 2/3
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.textContaining('MoMo'), findsWidgets);

      await t.ensureVisible(find.text('Bỏ qua (chưa dùng iOS 18)'));
      await t.pump();
      await t.tap(find.text('Bỏ qua (chưa dùng iOS 18)'));
      await t.pump();

      // ZaloPay at 3/3
      expect(find.text('3 / 3'), findsOneWidget);
      expect(find.textContaining('ZaloPay'), findsWidgets);
    });

    testWidgets('skip button calls onVerified on last wallet', (t) async {
      bool verified = false;
      _mockBridge(
        detected: ['vcb', 'momo'],
        queue: [
          {
            'id': 'tx-1',
            'package_name': 'vcb',
            'bank_id': 'vcb',
            'amount_vnd': 100000,
            'sign': 'credit',
            'timestamp_ms': 1_700_000_000_000,
            'created_at': 1_700_000_000_000,
            'raw_content': null,
          }
        ],
      );
      await t.pumpWidget(_widget(onVerified: () => verified = true));
      await _goToNotifStep(t);

      await t.ensureVisible(find.text('Bỏ qua (chưa dùng iOS 18)'));
      await t.pump();
      await t.tap(find.text('Bỏ qua (chưa dùng iOS 18)'));
      await t.pump();

      expect(verified, isTrue);
    });

    testWidgets('iOS 18 warning banner is shown', (t) async {
      _mockBridge(
        detected: ['vcb', 'momo'],
        queue: [
          {
            'id': 'tx-1',
            'package_name': 'vcb',
            'bank_id': 'vcb',
            'amount_vnd': 100000,
            'sign': 'credit',
            'timestamp_ms': 1_700_000_000_000,
            'created_at': 1_700_000_000_000,
            'raw_content': null,
          }
        ],
      );
      await t.pumpWidget(_widget());
      await _goToNotifStep(t);

      expect(find.textContaining('iOS 18'), findsWidgets);
    });
  });

  // ── Bank-only flow ──────────────────────────────────────────────────────────

  group('Bank-only flow', () {
    testWidgets('SMS verify → done without notification step', (t) async {
      bool verified = false;
      _mockBridge(
        detected: ['vcb', 'mb'],
        queue: [
          {
            'id': 'tx-1',
            'package_name': 'vcb',
            'bank_id': 'vcb',
            'amount_vnd': 100000,
            'sign': 'credit',
            'timestamp_ms': 1_700_000_000_000,
            'created_at': 1_700_000_000_000,
            'raw_content': null,
          }
        ],
      );
      await t.pumpWidget(_widget(onVerified: () => verified = true));
      await _goToSmsStep(t);

      await t.tap(find.widgetWithText(ElevatedButton, 'Đã setup → Kiểm tra'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(verified, isTrue);
      expect(find.text('Tự động hóa Thông báo'), findsNothing);
    });
  });
}
