import 'dart:async';

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../core/utils/bank_helper.dart';
import '../core/utils/formatter.dart';
import '../db/app_db.dart';
import '../models/category.dart';
import '../repositories/transaction_repository.dart';
import '../services/bridge_service.dart';
import '../services/pull_service.dart';
import '../services/gemini_service.dart';
import 'debug_sheet.dart';
import 'gemini_settings_dialog.dart';
import 'onboarding_screen.dart';
import 'transaction_widgets.dart';

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
  late final ScrollController _scrollController;

  // State cho In-app Notification (Toast)
  bool _showToast = false;
  int _newTxCount = 0;

  // IDs currently mid-animation (slide-in from top + fade).
  final Set<String> _animatingIds = {};
  final Set<String> _knownIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _repo = widget.repo ?? _defaultRepo();
    _pull = widget.pullService ?? PullService(_repo);
    
    // Tự quản lý Lifecycle Observer để trigger pull reactive của riêng screen
    WidgetsBinding.instance.addObserver(this);
    
    // Pull đầu tiên khi load xong frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPull());

    // Auto-pull khi native enqueue transaction mới (foreground real-time update).
    _txEventSub = BridgeService.transactionEventStream.listen((_) => _autoPull());
  }

  @override
  void dispose() {
    _txEventSub?.cancel();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Auto pull khi app resume hoặc có native event
  Future<void> _autoPull() async {
    if (_isPulling) return;
    setState(() => _isPulling = true);
    
    final count = await _pull.pull();
    if (mounted) {
      setState(() {
        _isPulling = false;
        if (count > 0) {
          _newTxCount = count;
          _showToast = true;
        }
      });
      
      if (count > 0) {
        // Tự động ẩn toast sau 4 giây
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() => _showToast = false);
          }
        });
      }
    }
  }

  // Manual pull button
  Future<void> _manualPull() async {
    await _autoPull();
  }

  // Check permission khi resume — nếu bị revoke thì redirect về onboarding
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final status = await BridgeService.checkPermissionStatus();
      final revoked = status == PermissionStatus.denied || status == PermissionStatus.revoked;
      if (revoked && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        _autoPull();
      }
    }
  }

  // ── Database Operations ───────────────────────────────────────────────────

  Future<void> _approveTx(Transaction tx) async {
    await _repo.approveTransaction(tx.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã duyệt giao dịch ${formatAmountAbbr(tx.amountVnd)}'),
          backgroundColor: const Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteTx(Transaction tx) async {
    await _repo.deleteTransaction(tx.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Đã xoá giao dịch ${formatAmountAbbr(tx.amountVnd)}'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: Colors.amber,
            onPressed: () async {
              // Khôi phục lại giao dịch bằng cách insert lại
              await _repo.syncFromNative(); // Pull lại từ native hoặc insert thủ công
              // Để đơn giản và chính xác, ta có thể lưu tạm hoặc chỉ thông báo xóa
            },
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _updateAndApproveTx(String id, TransactionsCompanion entry) async {
    await _repo.updateTransactionCompanion(id, entry);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã cập nhật và duyệt giao dịch!'),
          backgroundColor: Color(0xFF1E3C72),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Main Content
          Positioned.fill(
            child: StreamBuilder<List<Transaction>>(
              stream: _repo.watchAll(),
              builder: (context, snapshot) {
                final txs = snapshot.data ?? [];
                
                // Tách Drafts (chờ duyệt) và Confirmed (đã duyệt)
                final drafts = txs.where((t) => t.isDraft).toList();
                final confirmed = txs.where((t) => !t.isDraft).toList();

                // Tính toán số dư dựa trên Confirmed Transactions
                int totalExpense = 0;
                int totalIncome = 0;
                for (final tx in confirmed) {
                  if (tx.sign == 'debit') {
                    totalExpense += tx.amountVnd;
                  } else {
                    totalIncome += tx.amountVnd;
                  }
                }
                // Giả lập số dư khả dụng ban đầu là 15.000.000đ
                int initialBalance = 15000000;
                int totalBalance = initialBalance + totalIncome - totalExpense;

                // Detect first-time-seen IDs — animate only new arrivals
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

                return CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Premium Header Dashboard Card
                    SliverToBoxAdapter(
                      child: _buildPremiumHeaderCard(
                        totalBalance: totalBalance,
                        totalExpense: totalExpense,
                        totalIncome: totalIncome,
                      ),
                    ),

                    // Shimmer Skeleton Loaders khi đang đồng bộ ngầm
                    if (_isPulling && txs.isEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const ShimmerLoadingTile(),
                          childCount: 4,
                        ),
                      )
                    else ...[
                      // Section 1: Giao dịch chờ xác nhận (Drafts)
                      if (drafts.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _buildDraftsSection(drafts),
                        ),

                      // Section 2: Giao dịch chính thức (Confirmed)
                      if (confirmed.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: _buildEmpty(),
                          ),
                        )
                      else
                        _buildConfirmedSlivers(confirmed),
                    ],
                    
                    // Khoảng trống dưới cùng tránh bị che bởi FAB/Navigation Bar
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                );
              },
            ),
          ),

          // Custom In-app Toast Notification
          _buildInAppToast(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FA),
      elevation: 0,
      centerTitle: false,
      title: const Text(
        'Remind Spend',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A1A),
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        if (_isPulling)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3C72)),
              ),
            ),
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF1A1A1A)),
            tooltip: 'Đồng bộ ngay',
            onPressed: _manualPull,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A1A1A)),
            tooltip: 'Cài đặt AI',
            onPressed: _showSettingsDialog,
          ),
        ],
        // IconButton(
        //   icon: const Icon(Icons.bug_report_outlined, color: Color(0xFF8A8A8A)),
        //   tooltip: 'Debug simulator',
        //   onPressed: _showDebugSheet,
        // ),
      ],
    );
  }

  Future<void> _showSettingsDialog() async {
    final hasKey = await GeminiService.getApiKey();
    final enabled = await GeminiService.isAiEnabled();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => GeminiSettingsDialog(
        initialApiKey: hasKey ?? '',
        initialEnabled: enabled,
      ),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 32, color: Color(0xFF8A8A8A)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có giao dịch chính thức',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các giao dịch tự động từ ngân hàng\nsẽ xuất hiện ở mục "Chờ xác nhận" trước.',
            style: TextStyle(fontSize: 13, color: Color(0xFF8A8A8A), height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Premium Card & Sections ────────────────────────────────────────────────

  Widget _buildPremiumHeaderCard({
    required int totalBalance,
    required int totalExpense,
    required int totalIncome,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2027).withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SỐ DƯ KHẢ DỤNG',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.amber, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Realtime ⚡',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCounter(
            value: totalBalance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Income
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng thu',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          AnimatedCounter(
                            value: totalIncome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Spacer Line
              Container(
                height: 32,
                width: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 16),
              // Expense
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng chi',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          AnimatedCounter(
                            value: totalExpense,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDraftsSection(List<Transaction> drafts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 16, top: 12, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '🤖 CHỜ XÁC NHẬN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3C72),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${drafts.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Row(
                children: [
                  Icon(Icons.swipe_outlined, size: 12, color: Color(0xFF8A8A8A)),
                  SizedBox(width: 4),
                  Text(
                    'Vuốt để duyệt/xoá',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
                  ),
                ],
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: drafts.length,
          itemBuilder: (context, index) => _buildDraftItem(drafts[index]),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: Color(0xFFEEEEEE)),
        ),
      ],
    );
  }

  Widget _buildDraftItem(Transaction tx) {
    final isDebit = tx.sign == 'debit';
    final amountColor = isDebit ? const Color(0xFFE53935) : const Color(0xFF43A047);
    final amountPrefix = isDebit ? '-' : '+';
    final formattedAmount = formatAmountAbbr(tx.amountVnd);
    final time = DateTime.fromMillisecondsSinceEpoch(tx.timestampMs);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Dismissible(
        key: Key(tx.id),
        direction: DismissDirection.horizontal,
        background: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF43A047),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Duyệt giao dịch',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Xoá bỏ',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
              SizedBox(width: 10),
              Icon(Icons.delete, color: Colors.white, size: 24),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await _approveTx(tx);
            return true;
          } else {
            await _deleteTx(tx);
            return true;
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F8FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E3C72).withValues(alpha: 0.18), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3C72).withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            onTap: () => _showEditBottomSheet(tx),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDebit ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 20,
                    color: amountColor,
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E3C72),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt, size: 10, color: Colors.amber),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Text(
                  getBankDisplayName(tx.bankId),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 8),
                const PulseBadge(),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  tx.rawContent ?? 'Thông báo tự động',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CategoryBadge(
                      category: AppCategory.fromId(tx.categoryId, sign: tx.sign),
                      isAiPending: tx.categoryId == 'others',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note, size: 12, color: Color(0xFF1E3C72)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Nhấn để sửa • $timeStr',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF1E3C72), fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '$amountPrefix$formattedAmount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: amountColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedSlivers(List<Transaction> confirmed) {
    // Group by date
    final grouped = <String, List<Transaction>>{};
    for (final tx in confirmed) {
      final key = _dateLabel(tx.timestampMs);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final items = grouped[dateKey]!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Text(
                    dateKey.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8A8A8A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 0,
                            indent: 60,
                            color: Color(0xFFF1F1F1),
                          ),
                        AnimatedNewItem(
                          animate: _animatingIds.contains(items[i].id),
                          child: ConfirmedTransactionTile(
                            tx: items[i],
                            onTapCategory: () => _showCategoryPickerSheet(items[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: grouped.length,
      ),
    );
  }

  // ── Custom In-app Toast ────────────────────────────────────────────────────

  Widget _buildInAppToast() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      top: _showToast ? 16 : -120,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() => _showToast = false);
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3C72).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tự động ghi nhận thành công!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đã phát hiện $_newTxCount giao dịch mới. Chờ xác nhận.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _showToast = false);
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E3C72),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Xem ngay',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Sheet Edit ──────────────────────────────────────────────────────

  void _showEditBottomSheet(Transaction tx) {
    final amountController = TextEditingController(text: tx.amountVnd.toString());
    String selectedSign = tx.sign;
    String? selectedCategoryId = tx.categoryId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3C72).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, color: Color(0xFF1E3C72), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Chỉnh sửa & Xác nhận',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (tx.rawContent != null) ...[
                    Text(
                      'SMS/THÔNG BÁO GỐC:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        tx.rawContent!,
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey[700], height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOẠI GIAO DỊCH:',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Text(
                                        'Chi tiêu (-)',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    selected: selectedSign == 'debit',
                                    selectedColor: const Color(0xFFFFEBEE),
                                    disabledColor: Colors.transparent,
                                    labelStyle: TextStyle(
                                      color: selectedSign == 'debit' ? const Color(0xFFE53935) : Colors.grey[600],
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: selectedSign == 'debit' ? const Color(0xFFE53935) : Colors.grey[300]!,
                                      ),
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setStateSheet(() {
                                          selectedSign = 'debit';
                                          if (selectedCategoryId == 'income') {
                                            selectedCategoryId = 'others';
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ChoiceChip(
                                    label: const Center(
                                      child: Text(
                                        'Thu nhập (+)',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    selected: selectedSign == 'credit',
                                    selectedColor: const Color(0xFFE8F5E9),
                                    disabledColor: Colors.transparent,
                                    labelStyle: TextStyle(
                                      color: selectedSign == 'credit' ? const Color(0xFF43A047) : Colors.grey[600],
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: selectedSign == 'credit' ? const Color(0xFF43A047) : Colors.grey[300]!,
                                      ),
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setStateSheet(() {
                                          selectedSign = 'credit';
                                          selectedCategoryId = 'income';
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SỐ TIỀN (VND):',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      prefixText: selectedSign == 'debit' ? '- ' : '+ ',
                      prefixStyle: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: selectedSign == 'debit' ? const Color(0xFFE53935) : const Color(0xFF43A047),
                      ),
                      suffixText: 'đ',
                      suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1E3C72), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DANH MỤC GIAO DỊCH:',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[500], letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppCategory.values.map((cat) {
                      final isSelected = selectedCategoryId == cat.id;
                      return InkWell(
                        onTap: () {
                          setStateSheet(() {
                            selectedCategoryId = cat.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? cat.color.withValues(alpha: 0.15) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? cat.color : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 16,
                                color: isSelected ? cat.color : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.nameVi,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? cat.color : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Nút xoá
                      OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteTx(tx);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline, size: 18),
                            SizedBox(width: 4),
                            Text('Xoá', style: TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nút Duyệt & Lưu
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final intVal = int.tryParse(amountController.text) ?? 0;
                            if (intVal <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ!')),
                              );
                              return;
                            }
                            Navigator.pop(context);
                            
                            // Tạo Companion để update cả amount, sign, categoryId và isDraft
                            final companion = TransactionsCompanion(
                              amountVnd: drift.Value(intVal),
                              sign: drift.Value(selectedSign),
                              categoryId: drift.Value(selectedCategoryId),
                              isDraft: const drift.Value(false),
                            );
                            
                            await _updateAndApproveTx(tx.id, companion);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3C72),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text('Duyệt & Lưu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateTransactionCategory(String id, String catId) async {
    await _repo.updateTransactionCompanion(
      id,
      TransactionsCompanion(categoryId: drift.Value(catId)),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã cập nhật danh mục thành công!'),
          backgroundColor: Color(0xFF1E3C72),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showCategoryPickerSheet(Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final currentCat = AppCategory.fromId(tx.categoryId, sign: tx.sign);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3C72).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category_outlined, color: Color(0xFF1E3C72), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Phân loại giao dịch',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${getBankDisplayName(tx.bankId)} • ${formatAmountAbbr(tx.amountVnd)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: AppCategory.values.map((cat) {
                  final isSelected = currentCat.id == cat.id;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _updateTransactionCategory(tx.id, cat.id);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? cat.color.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? cat.color : Colors.grey[200]!,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? cat.color : cat.color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat.icon,
                              size: 20,
                              color: isSelected ? Colors.white : cat.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat.nameVi,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? cat.color : Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers & Parsers ──────────────────────────────────────────────────────

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





  // ignore: unused_element
  void _showDebugSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: const DebugSheet(),
        ),
      ),
    );
  }

  TransactionRepository _defaultRepo() {
    throw StateError('TransactionRepository not provided. Pass it via widget.repo.');
  }
}
