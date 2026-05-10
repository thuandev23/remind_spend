import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/bridge_service.dart';
import 'onboarding_widgets.dart';

// ─── iOS Step: Shortcuts Setup ────────────────────────────────────────────────
//
// iOS không có NotificationListenerService. Luồng thay thế:
//   1. User tải Shortcut mẫu (1-tap install via ShortcutInstaller.installURL)
//   2. Thiết lập Automation trong Shortcuts app để chạy khi nhận SMS ngân hàng
//   3. Khi SMS đến → Shortcut chạy LogTransactionIntent → ghi vào KeychainQueue
//   4. App pull từ KeychainQueue khi resume
// ─────────────────────────────────────────────────────────────────────────────
class IosShortcutStep extends StatefulWidget {
  final VoidCallback onGrant;
  final VoidCallback onVerified;

  const IosShortcutStep({
    super.key,
    required this.onGrant,
    required this.onVerified,
  });

  @override
  State<IosShortcutStep> createState() => _IosShortcutStepState();
}

class _IosShortcutStepState extends State<IosShortcutStep> {
  bool _isManual = false;
  bool _verifying = false;

  static const _storage = FlutterSecureStorage();

  Future<void> _checkConnection() async {
    setState(() => _verifying = true);

    if (kDebugMode) await BridgeService.mockTransaction();

    final items = await BridgeService.getAndClearQueue();
    if (!mounted) return;

    if (items.isNotEmpty) {
      await _storage.write(key: 'ios_setup_complete', value: 'true');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Kết nối thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onVerified();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Chưa nhận được dữ liệu. Hãy thử chạy phím tắt trước.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingStepCard(
          icon: _isManual ? Icons.menu_book_outlined : Icons.auto_fix_high_outlined,
          title: _isManual ? 'Hướng dẫn thủ công' : 'Thiết lập iOS Shortcuts',
          body: _isManual
              ? 'Nếu cách tự động không hoạt động, hãy làm theo các bước chi tiết sau.'
              : 'iOS không cho phép đọc thông báo trực tiếp. Bạn cần phím tắt để gửi dữ liệu vào app.',
        ),
        const SizedBox(height: 16),
        if (!_isManual) ..._autoGuide() else ..._manualGuide(),
        const SizedBox(height: 32),
        OnboardingPrimaryButton(
          label: _isManual ? 'Mở app Phím tắt' : 'Tải Phím tắt mẫu',
          onTap: widget.onGrant,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _verifying ? null : _checkConnection,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1A1A1A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _verifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Kiểm tra kết nối',
                    style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _isManual = !_isManual),
            child: Text(
              _isManual ? 'Quay lại cách tự động' : 'Xem hướng dẫn thủ công',
              style: const TextStyle(color: Color(0xFF8A8A8A)),
            ),
          ),
        ),
        if (kDebugMode) _debugButton(),
      ],
    );
  }

  List<Widget> _autoGuide() => [
        const OnboardingGuideRow(number: '1', text: 'Tải phím tắt mẫu bằng nút bên dưới.'),
        const SizedBox(height: 12),
        const OnboardingGuideRow(number: '2', text: 'Vào app Phím tắt → Tự động hóa → Thêm giao dịch.'),
        const SizedBox(height: 12),
        const OnboardingGuideRow(number: '3', text: 'Bấm "Kiểm tra kết nối" để hoàn tất.'),
      ];

  List<Widget> _manualGuide() => [
        const OnboardingGuideRow(number: '1', text: 'Mở app Phím tắt → Tạo phím tắt mới tên "LogTransaction".'),
        const SizedBox(height: 12),
        const OnboardingGuideRow(number: '2', text: 'Thêm tác vụ "Run App Intent" của Remind Spend.'),
        const SizedBox(height: 12),
        const OnboardingGuideRow(number: '3', text: 'Thiết lập Automation chạy phím tắt này khi có SMS.'),
      ];

  Widget _debugButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: TextButton(
          onPressed: () async {
            await BridgeService.mockTransaction();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🧪 Mock transaction injected')),
              );
            }
          },
          child: const Text(
            '[DEBUG] Inject mock transaction',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
          ),
        ),
      ),
    );
  }
}
