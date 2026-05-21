import 'package:flutter/material.dart';

import '../services/bridge_service.dart';
import 'onboarding_widgets.dart';

// ─── Android Step 1: Notification Listener Permission ────────────────────────
class AndroidNotificationStep extends StatelessWidget {
  final ManufacturerInfo? mfrInfo;
  final bool waiting;
  final VoidCallback onGrant;
  final VoidCallback onRetry;

  const AndroidNotificationStep({
    super.key,
    required this.mfrInfo,
    required this.waiting,
    required this.onGrant,
    required this.onRetry,
  });

  List<String> get _pathSteps {
    return switch (mfrInfo?.type) {
      ManufacturerType.miui => [
          'Mở app Bảo mật (Security)',
          'Chọn Quyền → Truy cập thông báo',
          'Bật công tắc cho Remind Spend',
        ],
      ManufacturerType.oneui => [
          'Vào Cài đặt → Thông báo',
          'Chọn Cài đặt thông báo nâng cao',
          'Chọn Truy cập thông báo → Remind Spend → Bật',
        ],
      ManufacturerType.coloros => [
          'Vào Cài đặt → Quản lý ứng dụng',
          'Chọn Quyền → Truy cập thông báo',
          'Bật công tắc cho Remind Spend',
        ],
      _ => [
          'Vào Cài đặt → Ứng dụng',
          'Chọn Quyền đặc biệt → Truy cập thông báo',
          'Bật công tắc cho Remind Spend',
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return waiting ? _buildWaiting() : _buildIdle();
  }

  Widget _buildIdle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingStepCard(
          icon: Icons.notifications_outlined,
          title: 'Truy cập thông báo',
          body: 'App cần đọc thông báo từ ứng dụng ngân hàng để tự động '
              'ghi nhận khi bạn chi tiêu.',
        ),
        const SizedBox(height: 20),
        const OnboardingInfoRow(icon: Icons.lock_outline,     text: 'Không gửi dữ liệu ra ngoài'),
        const SizedBox(height: 10),
        const OnboardingInfoRow(icon: Icons.phone_android,    text: 'Chỉ đọc thông báo ngân hàng'),
        const SizedBox(height: 10),
        const OnboardingInfoRow(icon: Icons.storage_outlined, text: 'Lưu trữ riêng trên máy của bạn'),
        const SizedBox(height: 28),
        _PathGuide(steps: _pathSteps, header: 'Sau khi nhấn nút, làm theo các bước:'),
        const SizedBox(height: 28),
        OnboardingPrimaryButton(label: 'Mở cài đặt', onTap: onGrant),
      ],
    );
  }

  Widget _buildWaiting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1A1A1A)),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang chờ bạn cấp quyền...',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'App sẽ tự động tiếp tục khi bạn bật quyền.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _PathGuide(steps: _pathSteps, header: 'Trong cài đặt vừa mở:'),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: const Text(
              'Quay lại',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Android Step 2: Battery Optimization ────────────────────────────────────
class AndroidBatteryStep extends StatelessWidget {
  final ManufacturerInfo? mfrInfo;
  final VoidCallback onGrant;
  final VoidCallback onSkip;

  const AndroidBatteryStep({
    super.key,
    required this.mfrInfo,
    required this.onGrant,
    required this.onSkip,
  });

  String get _guide {
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
      ManufacturerType.miui    => 'MIUI (Xiaomi)',
      ManufacturerType.oneui   => 'Samsung One UI',
      ManufacturerType.coloros => 'ColorOS (OPPO/Realme)',
      _                        => 'Android',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingStepCard(
          icon: Icons.battery_charging_full_outlined,
          title: 'Cho phép chạy ngầm',
          body: _guide,
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
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF856404)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Detected: $_manufacturerName',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF856404)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        OnboardingPrimaryButton(label: 'Mở cài đặt pin', onTap: onGrant),
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

// ─── Internal: Path guide box ─────────────────────────────────────────────────
class _PathGuide extends StatelessWidget {
  final List<String> steps;
  final String header;

  const _PathGuide({required this.steps, required this.header});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A8A8A),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: e.key < steps.length - 1 ? 10 : 0),
                child: OnboardingGuideRow(number: '${e.key + 1}', text: e.value),
              )),
        ],
      ),
    );
  }
}
