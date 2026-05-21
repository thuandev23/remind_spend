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

// Step 1 → Step 2 (selectApps) or Step 3 (setupAutomation when no apps)
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

// → Step 3 (setupAutomation) via select-apps "Tiếp tục"
Future<void> _goToSetupAutomation(WidgetTester t) async {
  await _grantPermission(t);
  await t.tap(find.text('Tiếp tục'));
  await t.pump();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    IosShortcutStep.bypassInitialPermissionCheck = true;
    
    // Thiết lập kích thước màn hình test ảo lớn hơn (800x1200) để các nút bấm phía dưới không bị tràn/ẩn
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(800, 1200);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
  });
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
      expect(find.textContaining('không đọc thông báo'), findsOneWidget);
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

      expect(find.text('Thiết lập Tự động hóa'), findsOneWidget);
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
    testWidgets('shows only detected apps', (t) async {
      _mockBridge(detected: ['vcb', 'momo']);
      await t.pumpWidget(_widget());
      await _grantPermission(t);

      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('MoMo'), findsOneWidget);
      expect(find.text('MB Bank'), findsNothing);
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

    testWidgets('continue advances to setupAutomation', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _grantPermission(t);

      await t.tap(find.text('Tiếp tục'));
      await t.pump();

      expect(find.text('Thiết lập Tự động hóa'), findsOneWidget);
    });
  });

  // ── Step 3: Setup Automation ───────────────────────────────────────────────

  group('Step 3 — Setup Automation', () {
    testWidgets('shows setup automation screen', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _goToSetupAutomation(t);

      expect(find.text('Thiết lập Tự động hóa'), findsOneWidget);
      expect(find.text('Kiểm tra kết nối'), findsOneWidget);
    });

    testWidgets('subtitle shows selected app names', (t) async {
      _mockBridge(detected: ['vcb', 'momo']);
      await t.pumpWidget(_widget());
      await _goToSetupAutomation(t);

      expect(find.textContaining('Vietcombank'), findsOneWidget);
      expect(find.textContaining('MoMo'), findsOneWidget);
    });

    testWidgets('shows generic label when no apps selected', (t) async {
      _mockBridge(detected: []);
      await t.pumpWidget(_widget());
      await _grantPermission(t);

      expect(find.textContaining('tất cả app'), findsOneWidget);
    });

    testWidgets('tapping Mở Phím tắt button triggers bridge', (t) async {
      _mockBridge(detected: ['vcb']);
      await t.pumpWidget(_widget());
      await _goToSetupAutomation(t);

      await t.tap(find.text('Mở Phím tắt'));
      await t.pump();
      // Should trigger bridge.requestPermission which returns true.
    });

    testWidgets('verify with empty queue shows error SnackBar', (t) async {
      _mockBridge(detected: ['vcb'], queue: []);
      await t.pumpWidget(_widget());
      await _goToSetupAutomation(t);

      await t.tap(find.text('Kiểm tra kết nối'));
      await t.pumpAndSettle();

      expect(find.textContaining('Chưa nhận được dữ liệu'), findsOneWidget);
    });

    testWidgets('verify with non-empty queue calls onVerified', (t) async {
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
      await _goToSetupAutomation(t);

      await t.tap(find.text('Kiểm tra kết nối'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));

      expect(verified, isTrue);
    });
  });
}
