import 'dart:async';

import 'package:flutter/material.dart';

import '../services/bridge_service.dart';
import 'onboarding_android.dart';
import 'onboarding_ios.dart';
import 'onboarding_widgets.dart';
import 'transaction_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
//
// Routing và state management cho onboarding flow.
// Platform-specific steps được tách sang:
//   - onboarding_android.dart  (AndroidNotificationStep, AndroidBatteryStep)
//   - onboarding_ios.dart      (IosShortcutStep)
//   - onboarding_widgets.dart  (shared UI components)
//
// Android flow:  Step 0 (notification) → Step 1 (battery) → Done
// iOS flow:      Step 0 (shortcuts setup) → Done
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final Widget Function()? onComplete;
  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  int _step = 0; // 0 = notif/shortcuts, 1 = battery, 2 = done
  ManufacturerInfo? _mfrInfo;
  bool _loading = true;
  bool _waitingForPermission = false;

  StreamSubscription<PermissionStatus>? _permSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    _permSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Dùng cho battery step: re-check khi user quay lại từ Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _step == 1) {
      _recheckBattery();
    }
  }

  Future<void> _init() async {
    final mfr    = await BridgeService.getManufacturerInfo();
    final status = await BridgeService.checkPermissionStatus();
    final bat    = await BridgeService.checkBatteryOptimization();

    if (!mounted) return;
    setState(() {
      _mfrInfo = mfr;
      _loading = false;
      if (status == PermissionStatus.granted) {
        _step = bat ? 2 : 1;
      }
    });

    if (_step == 2) { _navigateToDone(); return; }

    // iOS không dùng ContentObserver stream — permission model khác hoàn toàn
    if (mfr.type != ManufacturerType.ios) {
      _subscribePermission();
    }
  }

  // Android: ContentObserver trên enabled_notification_listeners → auto-advance
  void _subscribePermission() {
    _permSub = BridgeService.permissionStatusStream.listen((status) {
      if (!mounted || _step != 0) return;
      if (status == PermissionStatus.granted) {
        setState(() {
          _waitingForPermission = false;
          _step = 1;
        });
        _recheckBattery();
      }
    });
  }

  Future<void> _recheckBattery() async {
    final bat = await BridgeService.checkBatteryOptimization();
    if (!mounted) return;
    if (bat) {
      _navigateToDone();
    } else {
      setState(() => _step = 1);
    }
  }

  void _navigateToDone() {
    _permSub?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => widget.onComplete?.call() ?? const TransactionListScreen(),
      ),
    );
  }

  Future<void> _onGrantNotification() async {
    setState(() => _waitingForPermission = true);
    final isIos = _mfrInfo?.type == ManufacturerType.ios;
    if (isIos) {
      await BridgeService.requestLocalNotificationPermission();
    } else {
      await BridgeService.requestPostNotificationsPermission();
    }
    await BridgeService.requestPermission();
    // Android: permissionStatusStream tự detect khi user bật quyền
    // iOS: IosShortcutStep tự xử lý verify flow
  }

  Future<void> _onGrantBattery() async {
    await BridgeService.requestBatteryOptimizationWhitelist();
    // didChangeAppLifecycleState re-check khi user quay lại
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildStepIndicator(),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildCurrentStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 20),
        const Text(
          'Thiết lập\nRemind Spend',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chỉ cần ${(_mfrInfo?.type == ManufacturerType.ios || _step > 0) ? "1 bước" : "2 bước"} để tự động ghi nhận giao dịch.',
          style: const TextStyle(fontSize: 15, color: Color(0xFF8A8A8A)),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final isIos = _mfrInfo?.type == ManufacturerType.ios;
    if (isIos) {
      return Row(
        children: [
          OnboardingStepDot(label: '1', active: true, done: false),
        ],
      );
    }
    return Row(
      children: [
        OnboardingStepDot(label: '1', active: _step == 0, done: _step > 0),
        OnboardingStepLine(done: _step > 0),
        OnboardingStepDot(label: '2', active: _step == 1, done: _step > 1),
      ],
    );
  }

  Widget _buildCurrentStep() {
    final isIos = _mfrInfo?.type == ManufacturerType.ios;

    return switch (_step) {
      0 when isIos => IosShortcutStep(
          onGrant: _onGrantNotification,
          onVerified: _navigateToDone,
        ),
      0 => AndroidNotificationStep(
          mfrInfo: _mfrInfo,
          waiting: _waitingForPermission,
          onGrant: _onGrantNotification,
          onRetry: () => setState(() => _waitingForPermission = false),
        ),
      1 => AndroidBatteryStep(
          mfrInfo: _mfrInfo,
          onGrant: _onGrantBattery,
          onSkip: _navigateToDone,
        ),
      _ => const Center(child: Text('Đang chuyển...')),
    };
  }
}
