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

  @override
  void initState() {
    super.initState();
    // Lấy instance từ widget hoặc tạo mới (cho trường hợp navigate trực tiếp)
    _repo = widget.repo ?? _defaultRepo();
    _pull = widget.pullService ?? PullService(_repo);
    _pull.start();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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
      if (status != PermissionStatus.granted && mounted) {
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
            // Transactions for this date
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 0,
                  indent: 60,
                  color: Color(0xFFEEEEEE),
                ),
                itemBuilder: (context, i) => _TransactionTile(tx: items[i]),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _DebugSheet(),
    );
  }

  TransactionRepository _defaultRepo() {
    // Fallback — thực tế nên inject từ main.dart
    throw StateError(
        'TransactionRepository not provided. Pass it via widget.repo.');
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final perm = await BridgeService.checkPermissionStatus();
    final mfr = await BridgeService.getManufacturerInfo();
    final bat = await BridgeService.checkBatteryOptimization();
    if (!mounted) return;
    setState(() {
      _permStatus = perm;
      _mfrInfo = mfr;
      _battery = bat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Debug Info',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _DebugRow(
              label: 'Notification permission',
              value: _permStatus?.name ?? '...'),
          _DebugRow(
              label: 'Battery exempt',
              value: _battery ? '✅ yes' : '⚠️ no'),
          _DebugRow(
              label: 'Manufacturer',
              value: _mfrInfo?.manufacturer ?? '...'),
          _DebugRow(
              label: 'ROM type',
              value: _mfrInfo?.type.name ?? '...'),
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