import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/sms_presets.dart';
import '../services/bridge_service.dart';

class DebugSheet extends StatefulWidget {
  const DebugSheet({super.key});

  @override
  State<DebugSheet> createState() => _DebugSheetState();
}

class _DebugSheetState extends State<DebugSheet> {
  PermissionStatus? _permStatus;
  ManufacturerInfo? _mfrInfo;
  bool _battery = false;

  final _smsController = TextEditingController(
    text: 'Ban da nhan 100,000d tu ngan hang MB',
  );

  bool _simulating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final perm = await BridgeService.checkPermissionStatus();
    final mfr  = await BridgeService.getManufacturerInfo();
    final bat  = await BridgeService.checkBatteryOptimization();
    if (!mounted) return;
    setState(() {
      _permStatus = perm;
      _mfrInfo    = mfr;
      _battery    = bat;
    });
  }

  Future<void> _simulate() async {
    setState(() => _simulating = true);
    try {
      final ok = await BridgeService.simulateBankNotification(_smsController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Đã đẩy giao dịch tự động thành công!' : '❌ SMS không match pattern nào'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    } on BridgeError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ ${e.message}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _simulating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Debug Simulator',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1E3C72))),
          const SizedBox(height: 16),
          DebugRow(label: 'Permission',    value: _permStatus?.name ?? '...'),
          DebugRow(label: 'Battery exempt', value: _battery ? '✅ yes' : '⚠️ no'),
          DebugRow(label: 'Manufacturer',  value: _mfrInfo?.manufacturer ?? '...'),
          DebugRow(label: 'ROM type',      value: _mfrInfo?.type.name ?? '...'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await BridgeService.clearIdempotencyCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Idempotency cache cleared')),
                  );
                }
              },
              child: const Text('Clear idempotency cache'),
            ),
          ),
          if (kDebugMode && Platform.isIOS) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final err = await BridgeService.getLastExtensionError();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(err == null ? '✅ Extension: no errors' : '❌ Extension: $err'),
                    backgroundColor: err == null ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 8),
                  ));
                },
                child: const Text('⚠️ Last extension error'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final text = await BridgeService.getLastReceivedText();
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Last Received Text'),
                      content: Text(text ?? 'No text received yet.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'))
                      ],
                    ),
                  );
                },
                child: const Text('📝 Last received text'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final info = await BridgeService.debugKeychainPeek();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Keychain: count=${info['count']} status=${info['status']} err=${info['error']}'),
                    duration: const Duration(seconds: 6),
                  ));
                },
                child: const Text('🔑 Keychain peek (debug)'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Simulate bank notification',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chạy qua BankRegexParser → PendingTransaction.\nKiểm tra flow nhận diện SMS và hiển thị UI.',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: smsPresets.map((p) => ActionChip(
              label: Text(p.$1, style: const TextStyle(fontSize: 11)),
              padding: EdgeInsets.zero,
              onPressed: () => _smsController.text = p.$2,
            )).toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _smsController,
            decoration: InputDecoration(
              labelText: 'SMS text',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _simulating ? null : _simulate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3C72),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _simulating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simulate'),
            ),
          ),
        ],
      ),
    );
  }
}

class DebugRow extends StatelessWidget {
  final String label;
  final String value;
  const DebugRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8A))),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}
