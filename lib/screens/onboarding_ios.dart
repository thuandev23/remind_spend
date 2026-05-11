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

  Set<String> _detectedIds = {};
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    final status = await BridgeService.checkPermissionStatus();
    if (status == PermissionStatus.granted && mounted) {
      _advanceFromPermission();
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
          subtitle: 'Cho: $names',
          badge: 'iOS 18+',
        ),
        const SizedBox(height: 20),
        _ChecklistCard(
          items: const [
            'Tải phím tắt "Log Bank Transaction" qua link bên dưới.',
            'Vào tab Tự động hóa → Thêm (+).',
            'Chọn "Thông báo từ ứng dụng" → Chọn các app của bạn.',
            'Hành động: chạy "Log Bank Transaction".',
            'Truyền đầu vào là [Nội dung thông báo].',
            'Tắt "Hỏi trước khi chạy" → Lưu.',
          ],
        ),
        const SizedBox(height: 16),
        _buildSmsTestCard(),
        const SizedBox(height: 20),
        _OpenShortcutsButton(onTap: _openShortcuts),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
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
                    'Đã setup → Kiểm tra',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmsTestCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chạy thử shortcut với nội dung mẫu:',
            style: TextStyle(fontSize: 13, color: Color(0xFF5A5A5A)),
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
                        content: Text('Đã copy nội dung mẫu'),
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
          const SizedBox(height: 6),
          const Text(
            'Mở Phím tắt → chạy "Log Bank Transaction" → dán nội dung trên → quay lại bấm Kiểm tra.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
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

class _OpenShortcutsButton extends StatelessWidget {
  final Future<void> Function() onTap;
  const _OpenShortcutsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.open_in_new, size: 16),
        label: const Text('Mở app Phím tắt'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          side: const BorderSide(color: Color(0xFF1A1A1A)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
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
