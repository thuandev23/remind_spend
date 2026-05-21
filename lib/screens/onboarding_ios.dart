import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bridge_service.dart';
import '../services/pull_service.dart';
import 'onboarding_widgets.dart';

// ── App metadata ──────────────────────────────────────────────────────────────

class _AppInfo {
  final String id;
  final String name;
  const _AppInfo(this.id, this.name);
}

const _supportedApps = [
  _AppInfo('vcb', 'Vietcombank'),
  _AppInfo('mb', 'MB Bank'),
  _AppInfo('bidv', 'BIDV'),
  _AppInfo('tcb', 'Techcombank'),
  _AppInfo('acb', 'ACB'),
  _AppInfo('vtb', 'Vietinbank'),
  _AppInfo('vpb', 'VPBank'),
  _AppInfo('agr', 'Agribank'),
  _AppInfo('tpb', 'TPBank'),
  _AppInfo('scb', 'Sacombank'),
  _AppInfo('momo', 'MoMo'),
  _AppInfo('zalopay', 'ZaloPay'),
];

// ── Step enum ─────────────────────────────────────────────────────────────────

enum _Step { notifPermission, selectApps, setupAutomation }

// ── IosShortcutStep ───────────────────────────────────────────────────────────

class IosShortcutStep extends StatefulWidget {
  final VoidCallback onGrant;
  final VoidCallback onVerified;
  final PullService? pullService;

  // Static flag to bypass the async checkPermissionStatus during tests,
  // preventing async initialization frames that break widget tests.
  static bool bypassInitialPermissionCheck = false;

  const IosShortcutStep({
    super.key,
    required this.onGrant,
    required this.onVerified,
    this.pullService,
  });

  @override
  State<IosShortcutStep> createState() => _IosShortcutStepState();
}

class _IosShortcutStepState extends State<IosShortcutStep> {
  _Step _step = _Step.notifPermission;

  bool _permissionRequesting = false;
  bool _detecting = false;
  bool _showEnglishGuide = false;
  late bool _initializing; // Change to late bool

  Set<String> _detectedIds = {};
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _initializing = !IosShortcutStep.bypassInitialPermissionCheck;
    _verifyStartedAt = DateTime.now();
    if (_initializing) {
      _checkInitialPermission();
    }
  }

  Future<void> _checkInitialPermission() async {
    final status = await BridgeService.checkPermissionStatus();
    if (!mounted) return;
    
    if (status == PermissionStatus.granted) {
      // If already granted, instantly check installed finance apps and advance
      final detected = await BridgeService.detectInstalledFinanceApps();
      if (!mounted) return;
      setState(() {
        _detectedIds = detected.toSet();
        _selectedIds = detected.toSet();
        _step = detected.isNotEmpty ? _Step.selectApps : _Step.setupAutomation;
        _initializing = false;
      });
    } else {
      // Not granted, show the permission screen
      setState(() {
        _initializing = false;
      });
    }
  }

  bool _verifying = false;
  DateTime? _verifyStartedAt;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  List<_AppInfo> get _selectedApps =>
      _supportedApps.where((a) => _selectedIds.contains(a.id)).toList();

  // ── Navigation ───────────────────────────────────────────────────────────────

  Future<void> _onRequestPermission() async {
    widget.onGrant(); // notify parent
    setState(() => _permissionRequesting = true);
    await BridgeService.requestLocalNotificationPermission();
    if (!mounted) return;
    await _advanceFromPermission();
  }

  Future<void> _advanceFromPermission() async {
    setState(() {
      _permissionRequesting = false;
      _detecting = true;
    });
    final detected = await BridgeService.detectInstalledFinanceApps();
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _detectedIds = detected.toSet();
      _selectedIds = detected.toSet();
      _step = detected.isNotEmpty ? _Step.selectApps : _Step.setupAutomation;
    });
  }

  void _onSelectAppsDone() {
    setState(() {
      _step = _Step.setupAutomation;
    });
  }

  Future<void> _verifyAndFinish() async {
    setState(() {
      _verifying = true;
      _verifyStartedAt ??= DateTime.now();
    });
    final items = await BridgeService.getAndClearQueue();
    if (!mounted) return;

    final success = items.isNotEmpty || _pullServiceHadRecentSuccess();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kết nối thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      _finishOnboarding();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Chưa nhận được dữ liệu. Hãy chạy thử shortcut với nội dung mẫu rồi bấm lại.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      setState(() => _verifying = false);
    }
  }

  bool _pullServiceHadRecentSuccess() {
    final svc = widget.pullService;
    final at = _verifyStartedAt;
    if (svc == null || at == null) return false;
    final pullAt = svc.lastPullAt;
    return pullAt != null && pullAt.isAfter(at) && svc.lastPullCount > 0;
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ios_setup_complete', true);
    if (!mounted) return;
    widget.onVerified();
  }

  Future<void> _openShortcuts() => BridgeService.requestPermission();

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
          ),
        ),
      );
    }

    return switch (_step) {
      _Step.notifPermission => _buildNotifPermission(),
      _Step.selectApps => _buildSelectApps(),
      _Step.setupAutomation => _buildSetupAutomation(),
    };
  }

  // ── Step 1: Notification Permission ──────────────────────────────────────────

  Widget _buildNotifPermission() {
    final busy = _permissionRequesting || _detecting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingStepCard(
          icon: Icons.notifications_active_outlined,
          title: 'Cho phép thông báo',
          body:
              'App hiển thị cảnh báo ngay khi có giao dịch — giúp bạn theo dõi thu chi theo thời gian thực.',
        ),
        const SizedBox(height: 24),
        const _ReasonRow(
          icon: Icons.flash_on_outlined,
          text: 'Thông báo tức thì khi phát sinh giao dịch',
        ),
        const SizedBox(height: 12),
        const _ReasonRow(
          icon: Icons.lock_outline,
          text: 'App không đọc thông báo cá nhân của bạn',
        ),
        const SizedBox(height: 12),
        const _ReasonRow(
          icon: Icons.tune_outlined,
          text: 'Có thể điều chỉnh bất kỳ lúc nào trong Cài đặt',
        ),
        const SizedBox(height: 32),
        if (busy)
          const Center(child: CircularProgressIndicator())
        else
          OnboardingPrimaryButton(
            label: 'Cho phép thông báo',
            onTap: _onRequestPermission,
          ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: busy ? null : _advanceFromPermission,
            child: const Text(
              'Bỏ qua',
              style: TextStyle(color: Color(0xFF8A8A8A)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Select Apps ───────────────────────────────────────────────────────

  Widget _buildSelectApps() {
    final detectedApps = _supportedApps
        .where((a) => _detectedIds.contains(a.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingStepCard(
          icon: Icons.apps_outlined,
          title: 'Bạn dùng app nào?',
          body:
              'Chúng tôi đã tìm thấy các app tài chính đang cài trên máy. Bật/tắt theo nhu cầu thực tế.',
        ),
        const SizedBox(height: 20),
        if (detectedApps.isNotEmpty)
          _buildAppSection(
            title: 'Ứng dụng tài chính',
            subtitle: 'Đọc giao dịch qua Thông báo',
            apps: detectedApps,
            badgeLabel: 'iOS 18+',
            badgeColor: const Color(0xFF9C27B0),
          ),
        const SizedBox(height: 32),
        OnboardingPrimaryButton(
          label: 'Tiếp tục',
          onTap: _selectedIds.isEmpty ? _onSelectAppsDone : _onSelectAppsDone,
        ),
      ],
    );
  }

  Widget _buildAppSection({
    required String title,
    required String subtitle,
    required List<_AppInfo> apps,
    required String badgeLabel,
    required Color badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: apps.map((app) {
            final selected = _selectedIds.contains(app.id);
            return GestureDetector(
              onTap: () => setState(() {
                selected
                    ? _selectedIds.remove(app.id)
                    : _selectedIds.add(app.id);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  app.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF3A3A3A),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 3: Setup Notification Automation ─────────────────────────────────────

  Widget _buildSetupAutomation() {
    final names = _selectedApps.isEmpty
        ? 'tất cả app'
        : _selectedApps.map((a) => a.name).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AutomationHeader(
          icon: Icons.notifications_outlined,
          title: 'Thiết lập Tự động hóa',
          subtitle: 'Áp dụng cho: $names',
          badge: 'iOS 18+',
        ),
        const SizedBox(height: 20),
        
        // ── iCloud Shortcut Download Card ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFF000000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bước 1: Tải Phím tắt mẫu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tải phím tắt "Log Bank Transaction" từ iCloud',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Mở iCloud Link tải shortcut thật
                    const url = 'https://www.icloud.com/shortcuts/24ef3ab2330a47d2bb34e16d48259dfb'; // iCloud URL của Shortcut mẫu
                    // Gọi qua bridge_service hoặc launchUrl
                    // Trong context này, ta có thể copy link hoặc mở trực tiếp
                    Clipboard.setData(const ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔗 Đã sao chép liên kết iCloud Shortcut vào bộ nhớ tạm!'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    // Mở safari để cài đặt phím tắt
                    await BridgeService.requestPermission(); // Mở Shortcuts app trực tiếp
                  },
                  icon: const Icon(Icons.install_mobile_rounded, size: 18),
                  label: const Text(
                    'Cài đặt Phím tắt từ iCloud',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _showEnglishGuide
                            ? 'Important: Open the downloaded Shortcut -> Ensure the "Message Text" field is bound to the blue "Shortcut Input" variable to receive dynamic messages.'
                            : 'Lưu ý quan trọng: Mở Phím tắt vừa tải -> Đảm bảo ô "Message Text" đã được gán biến "Phím tắt đầu vào" (Shortcut Input) màu xanh dương để nhận tin nhắn động tự động.',
                        style: const TextStyle(fontSize: 11, color: Colors.white, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Step 2: Automation Guide (Prioritizing Vietnamese) ──────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Bước 2: Tạo Tự động hóa (Automation)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(width: 8), // Khoảng cách nhỏ giữa tiêu đề và nút bấm
            // Nút chuyển đổi ngôn ngữ tinh tế
            GestureDetector(
              onTap: () => setState(() => _showEnglishGuide = !_showEnglishGuide),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Text(
                  _showEnglishGuide ? '🇻🇳 Tiếng Việt' : '🇬🇧 English Guide',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3C72),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Hiển thị checklist tương ứng dựa trên state (Mặc định là Tiếng Việt)
        _showEnglishGuide
            ? _ChecklistCard(
                items: const [
                  'Open Shortcuts app -> Go to "Automation" tab -> Tap (+).',
                  'Select "Message" trigger (perfect for bank transaction SMS).',
                  'Sender: Select your bank sender, or Contains: enter "GD" or "VND".',
                  'Select "Run Immediately" (Crucial!). Turn off "Notify When Run".',
                  'Tap Next -> Choose "New Blank Automation" -> Tap "Add Action".',
                  'Search and add "Run Shortcut" -> Select "Log Bank Transaction".',
                  'Expand action details -> Set Shortcut Input to the incoming "Message".'
                ],
              )
            : _ChecklistCard(
                items: const [
                  'Mở app Phím tắt (Shortcuts) -> chọn tab Tự động hóa -> bấm (+).',
                  'Chọn tác vụ kích hoạt "Tin nhắn" (Message) (để bắt SMS biến động số dư).',
                  'Mục Người gửi: chọn ngân hàng của bạn, hoặc mục Chứa: nhập "GD" hoặc "VND".',
                  'Mục Thời điểm chạy: CHỌN "Chạy ngay lập tức" (Run Immediately). Tắt "Thông báo khi chạy".',
                  'Nhấn Tiếp tục -> Chọn "Tự động hóa trống mới" -> Thêm tác vụ.',
                  'Tìm tác vụ "Chạy phím tắt" (Run Shortcut) -> Chọn phím tắt "Log Bank Transaction".',
                  'Bấm mở rộng chi tiết tác vụ -> ở mục Đầu vào (Input), chọn "Tin nhắn" -> "Văn bản" (Text).'
                ],
              ),
        const SizedBox(height: 20),

        // ── Test & Verify Area ──────────────────────────────────────────────────
        const Text(
          'Bước 3: Chạy thử & Xác nhận kết nối',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 10),
        _buildSmsTestCard(),
        const SizedBox(height: 24),
        
        Row(
          children: [
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _openShortcuts,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Mở Phím tắt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _verifying ? null : _verifyAndFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kiểm tra kết nối',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmsTestCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sao chép chuỗi tin nhắn giao dịch mẫu dưới đây:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5A5A5A)),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: SelectableText(
                    'GD: +100,000 VND SD: 5,000,000 VND',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      const ClipboardData(
                        text: 'GD: +100,000 VND SD: 5,000,000 VND',
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📋 Đã copy nội dung mẫu vào bộ nhớ tạm'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: Color(0xFF5A5A5A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '💡 Hướng dẫn chạy thử: Mở app Phím tắt -> Bấm chạy Shortcut "Log Bank Transaction" -> Dán tin nhắn trên -> Quay lại app bấm "Kiểm tra kết nối".',
            style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A), height: 1.3),
          ),
        ],
      ),
    );
  }
}


// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _ReasonRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ReasonRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF3A3A3A)),
          ),
        ),
      ],
    );
  }
}


class _AutomationHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;

  const _AutomationHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
  });

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
          Row(
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
              const Spacer(),
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A5A)),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  final List<String> items;
  const _ChecklistCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10, top: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${e.key + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3A3A3A),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
