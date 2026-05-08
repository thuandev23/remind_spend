import 'package:flutter/material.dart';
import '../services/bridge_service.dart';
import 'transaction_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
//
// Hiển thị khi app chưa có notification permission.
// Flow:
//   Step 1 — Xin notification listener access
//   Step 2 — Xin battery optimization exemption (nếu cần)
//   Done   — Navigate sang TransactionListScreen
//
// Detect manufacturer để show đúng hướng dẫn step-by-step.
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  final Widget Function()? onComplete;
  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  int _step = 0; // 0 = notif, 1 = battery, 2 = done
  ManufacturerInfo? _mfrInfo;
  bool _loading = true;
  bool _checkingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Khi user quay lại từ Settings → re-check permission
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checkingPermission) {
      _checkingPermission = false;
      _recheck();
    }
  }

  Future<void> _init() async {
    final mfr = await BridgeService.getManufacturerInfo();
    final status = await BridgeService.checkPermissionStatus();
    final battery = await BridgeService.checkBatteryOptimization();

    if (!mounted) return;
    setState(() {
      _mfrInfo = mfr;
      _loading = false;
      if (status == PermissionStatus.granted) {
        _step = battery ? 2 : 1;
      } else {
        _step = 0;
      }
    });

    if (_step == 2) _navigateToDone();
  }

  Future<void> _recheck() async {
    final status = await BridgeService.checkPermissionStatus();
    final battery = await BridgeService.checkBatteryOptimization();
    if (!mounted) return;

    if (status == PermissionStatus.granted && battery) {
      _navigateToDone();
    } else if (status == PermissionStatus.granted) {
      setState(() => _step = 1);
    }
  }

  void _navigateToDone() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            widget.onComplete?.call() ?? const TransactionListScreen(),
      ),
    );
  }

  Future<void> _onGrantNotification() async {
    _checkingPermission = true;
    await BridgeService.requestPermission();
    // Không navigate ngay — đợi didChangeAppLifecycleState khi user quay lại
  }

  Future<void> _onGrantBattery() async {
    _checkingPermission = true;
    await BridgeService.requestBatteryOptimizationWhitelist();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
              Expanded(child: _buildCurrentStep()),
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
          'Chỉ cần ${_step == 0 ? "2 bước" : "1 bước"} để tự động ghi nhận giao dịch.',
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF8A8A8A),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _StepDot(label: '1', active: _step == 0, done: _step > 0),
        _StepLine(done: _step > 0),
        _StepDot(label: '2', active: _step == 1, done: _step > 1),
      ],
    );
  }

  Widget _buildCurrentStep() {
    return switch (_step) {
      0 => _NotificationStep(onGrant: _onGrantNotification),
      1 => _BatteryStep(
          mfrInfo: _mfrInfo,
          onGrant: _onGrantBattery,
          onSkip: _navigateToDone,
        ),
      _ => const _DoneStep(),
    };
  }
}

// ─── Step: Notification Permission ───────────────────────────────────────────
class _NotificationStep extends StatelessWidget {
  final VoidCallback onGrant;
  const _NotificationStep({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepCard(
          icon: Icons.notifications_outlined,
          title: 'Truy cập thông báo',
          body:
              'App cần đọc thông báo từ ứng dụng ngân hàng để tự động ghi nhận khi bạn chi tiêu.\n\n'
              'Dữ liệu được mã hoá và chỉ lưu trên thiết bị của bạn.',
        ),
        const SizedBox(height: 24),
        const _InfoRow(
          icon: Icons.lock_outline,
          text: 'Không gửi dữ liệu ra ngoài',
        ),
        const SizedBox(height: 10),
        const _InfoRow(
          icon: Icons.phone_android,
          text: 'Chỉ đọc thông báo ngân hàng',
        ),
        const Spacer(),
        _PrimaryButton(
          label: 'Cấp quyền truy cập',
          onTap: onGrant,
        ),
        const SizedBox(height: 12),
        const Text(
          'Chọn "Remind Spend" trong danh sách và bật công tắc.',
          style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Step: Battery Optimization ──────────────────────────────────────────────
class _BatteryStep extends StatelessWidget {
  final ManufacturerInfo? mfrInfo;
  final VoidCallback onGrant;
  final VoidCallback onSkip;

  const _BatteryStep({
    required this.mfrInfo,
    required this.onGrant,
    required this.onSkip,
  });

  String get _manufacturerGuide {
    return switch (mfrInfo?.type) {
      ManufacturerType.miui =>
        'Vào Cài đặt → Ứng dụng → Remind Spend → Tiết kiệm pin → Không hạn chế.\n\n'
        'Sau đó tìm "Tự khởi động" và bật cho Remind Spend.',
      ManufacturerType.oneui =>
        'Vào Cài đặt → Chăm sóc thiết bị → Pin → Giới hạn ứng dụng.\n\n'
        'Xoá Remind Spend khỏi danh sách ứng dụng ngủ.',
      ManufacturerType.coloros =>
        'Vào Cài đặt → Quản lý ứng dụng → Remind Spend → Tiêu thụ pin → Không hạn chế.',
      _ =>
        'Cho phép app hoạt động ngầm để không bỏ lỡ giao dịch khi màn hình tắt.',
    };
  }

  String get _manufacturerName {
    return switch (mfrInfo?.type) {
      ManufacturerType.miui => 'MIUI (Xiaomi)',
      ManufacturerType.oneui => 'Samsung One UI',
      ManufacturerType.coloros => 'ColorOS (OPPO/Realme)',
      _ => 'Android',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepCard(
          icon: Icons.battery_charging_full_outlined,
          title: 'Cho phép chạy ngầm',
          body: _manufacturerGuide,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3CD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFF856404)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Detected: $_manufacturerName',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF856404)),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _PrimaryButton(
          label: 'Mở cài đặt pin',
          onTap: onGrant,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSkip,
          child: const Text(
            'Bỏ qua, tôi sẽ thiết lập sau',
            style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
          ),
        ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Đang chuyển...'),
    );
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final String label;
  final bool active;
  final bool done;

  const _StepDot(
      {required this.label, required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final bg = done
        ? const Color(0xFF1A1A1A)
        : active
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFE0E0E0);
    final fg = (done || active) ? Colors.white : const Color(0xFF8A8A8A);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool done;
  const _StepLine({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        color: done ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _StepCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5A5A5A),
                  height: 1.55)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4CAF50)),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3A))),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child:
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}