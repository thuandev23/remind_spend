import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../db/app_db.dart';
import '../repositories/transaction_repository.dart';
import '../services/bridge_service.dart';
import '../services/pull_service.dart';
import 'onboarding_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionListScreen
//
// Main screen sau khi đã có permission.
// Stream watchAll() từ Drift — tự update khi có giao dịch mới.
// Pull thủ công bằng nút refresh (và tự pull khi resume qua PullService).
// ─────────────────────────────────────────────────────────────────────────────
class TransactionListScreen extends StatefulWidget {
  final TransactionRepository? repo;
  final PullService? pullService;

  const TransactionListScreen({super.key, this.repo, this.pullService});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with WidgetsBindingObserver {
  late final TransactionRepository _repo;
  late final PullService _pull;
  bool _isPulling = false;
  StreamSubscription<void>? _txEventSub;

  // IDs seen at least once — prevents re-animating on every StreamBuilder rebuild.
  final Set<String> _knownIds = {};
  // IDs currently mid-animation (slide-in from top + fade).
  final Set<String> _animatingIds = {};

  @override
  void initState() {
    super.initState();
    // Lấy instance từ widget hoặc tạo mới (cho trường hợp navigate trực tiếp)
    _repo = widget.repo ?? _defaultRepo();
    _pull = widget.pullService ?? PullService(_repo);
    _pull.start();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pull.pull());

    // Auto-pull khi native enqueue transaction mới (foreground real-time update).
    _txEventSub = BridgeService.transactionEventStream.listen((_) => _pull.pull());

  }

  @override
  void dispose() {
    _txEventSub?.cancel();
    _pull.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Manual pull button
  Future<void> _manualPull() async {
    if (_isPulling) return;
    setState(() => _isPulling = true);
    await _pull.pull();
    if (mounted) setState(() => _isPulling = false);
  }

  // Check permission khi resume — nếu bị revoke thì redirect về onboarding
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final status = await BridgeService.checkPermissionStatus();
      // restricted = iOS "not_applicable" — App Intents always available, no revoke possible.
      // Only redirect when permission was explicitly denied or revoked by the user.
      final revoked = status == PermissionStatus.denied || status == PermissionStatus.revoked;
      if (revoked && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: _buildAppBar(),
      body: StreamBuilder<List<Transaction>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final txs = snapshot.data ?? [];
          if (txs.isEmpty) return _buildEmpty();

          // Detect first-time-seen IDs — animate only new arrivals, not initial load.
          final incoming = txs.map((t) => t.id).toSet();
          if (_knownIds.isNotEmpty) {
            final newIds = incoming.difference(_knownIds);
            if (newIds.isNotEmpty) {
              _animatingIds.addAll(newIds);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _animatingIds.removeAll(newIds));
              });
            }
          }
          _knownIds.addAll(incoming);

          return _buildList(txs);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF7F7F5),
      elevation: 0,
      title: const Text(
        'Giao dịch',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
      ),
      actions: [
        if (_isPulling)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1A)),
            tooltip: 'Đồng bộ ngay',
            onPressed: _manualPull,
          ),
        IconButton(
          icon: const Icon(Icons.bug_report_outlined, color: Color(0xFF8A8A8A)),
          tooltip: 'Debug info',
          onPressed: _showDebugSheet,
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 36, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có giao dịch nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thực hiện giao dịch qua app ngân hàng.\nThông báo sẽ được tự động ghi nhận.',
            style: TextStyle(fontSize: 14, color: Color(0xFF8A8A8A), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _manualPull,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Kiểm tra ngay'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFFDDDDDD)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Transaction> txs) {
    // Group by date
    final grouped = <String, List<Transaction>>{};
    for (final tx in txs) {
      final key = _dateLabel(tx.timestampMs);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final items = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A8A8A),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Transactions for this date — Column avoids nested ListView/shrinkWrap jank.
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 0,
                        indent: 60,
                        color: Color(0xFFEEEEEE),
                      ),
                    _AnimatedNewItem(
                      animate: _animatingIds.contains(items[i].id),
                      child: _TransactionTile(tx: items[i]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _dateLabel(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDay = DateTime(dt.year, dt.month, dt.day);

    if (txDay == today) return 'Hôm nay';
    if (txDay == yesterday) return 'Hôm qua';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  // Debug sheet — chỉ hiện trong debug build
  void _showDebugSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: const _DebugSheet(),
        ),
      ),
    );
  }

  TransactionRepository _defaultRepo() {
    // Fallback — thực tế nên inject từ main.dart
    throw StateError(
        'TransactionRepository not provided. Pass it via widget.repo.');
  }
}

// ─── New-item slide-in animation ──────────────────────────────────────────────
class _AnimatedNewItem extends StatelessWidget {
  final bool animate;
  final Widget child;
  const _AnimatedNewItem({required this.animate, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      // Pass child through so Flutter doesn't rebuild it on every animation tick.
      child: child,
      builder: (_, value, inner) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, -14 * (1 - value)),
          child: inner,
        ),
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final Transaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDebit = tx.sign == 'debit';
    final amountColor =
        isDebit ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final amountPrefix = isDebit ? '-' : '+';
    final formattedAmount = _formatAmount(tx.amountVnd);
    final time = DateTime.fromMillisecondsSinceEpoch(tx.timestampMs);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDebit
              ? const Color(0xFFFFEBEE)
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
          size: 18,
          color: amountColor,
        ),
      ),
      title: Text(
        _bankName(tx.bankId),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
      ),
      subtitle: Text(
        timeStr,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
      ),
      trailing: Text(
        '$amountPrefix$formattedAmount',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: amountColor,
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    if (amount >= 1000000) {
      final m = amount / 1000000;
      final formatted = m == m.truncateToDouble()
          ? m.toInt().toString()
          : m.toStringAsFixed(1);
      return '${formatted}tr đ';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k đ';
    }
    return '$amount đ';
  }

  String _bankName(String bankId) {
    return switch (bankId) {
      'vcb' => 'Vietcombank',
      'mb' => 'MB Bank',
      'tcb' => 'Techcombank',
      'acb' => 'ACB',
      'bidv' => 'BIDV',
      'vtb' => 'Vietinbank',
      'momo' => 'MoMo',
      'zalopay' => 'ZaloPay',
      _ => bankId.toUpperCase(),
    };
  }
}

// ─── Debug Sheet ──────────────────────────────────────────────────────────────
class _DebugSheet extends StatefulWidget {
  const _DebugSheet();

  @override
  State<_DebugSheet> createState() => _DebugSheetState();
}

class _DebugSheetState extends State<_DebugSheet> {
  PermissionStatus? _permStatus;
  ManufacturerInfo? _mfrInfo;
  bool _battery = false;

  final _smsController = TextEditingController(
    text: 'Ban da nhan 100,000d tu ngan hang MB',
  );

  static const _presets = [
    ('MB credit',      'Ban da nhan 100,000d tu ngan hang MB'),
    ('MB debit',       'chi 50,000d phi dich vu MB'),
    ('VCB credit',     'GD: +1,234,567 VND. So du: 10,000,000VND'),
    ('VCB debit',      'GD: -250,000 VND. So du: 9,750,000VND'),
    ('TCB credit',     'GD: +500,000 VND vao TK Techcombank'),
    ('BIDV credit',    'Tang 300,000 VND vao TK BIDV'),
    ('MoMo credit',    'Ban da nhan 75,000d tu Nguyen Van A qua MoMo'),
    ('ZaloPay credit', 'Ban da nhan 50,000d tu B qua ZaloPay'),
  ];
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
        content: Text(ok ? '✅ Enqueued — kéo refresh để thấy' : '❌ SMS không match pattern nào'),
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
          const Text('Debug Info',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _DebugRow(label: 'Permission',    value: _permStatus?.name ?? '...'),
          _DebugRow(label: 'Battery exempt', value: _battery ? '✅ yes' : '⚠️ no'),
          _DebugRow(label: 'Manufacturer',  value: _mfrInfo?.manufacturer ?? '...'),
          _DebugRow(label: 'ROM type',      value: _mfrInfo?.type.name ?? '...'),
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
          // iOS-only: simulate bank SMS notification (equivalent of ADB broadcast on Android)
          if (kDebugMode && Platform.isIOS) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Simulate bank notification (iOS)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chạy qua BankRegexParser → KeychainQueue.\nTương đương ADB broadcast trên Android.',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A8A8A)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _presets.map((p) => ActionChip(
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
                  backgroundColor: const Color(0xFF1A1A1A),
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
        ],
      ),
    );
  }
}

class _DebugRow extends StatelessWidget {
  final String label;
  final String value;
  const _DebugRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF8A8A8A)))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }
}