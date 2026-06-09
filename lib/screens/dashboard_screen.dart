import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../db/app_db.dart';
import '../models/category.dart';
import '../repositories/transaction_repository.dart';
import '../services/budget_service.dart';
import 'budget_screen.dart';
import 'regex_rules_screen.dart';
// import 'savings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final TransactionRepository repo;

  const DashboardScreen({super.key, required this.repo});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Khoảng thời gian đang lọc: 0 = Tháng này, 1 = Tháng trước, 2 = 6 tháng qua
  int _selectedPeriod = 0;
  
  // Index của phần biểu đồ tròn đang được người dùng chạm vào (mặc định -1 là chưa chạm)
  int _touchedPieIndex = -1;

  late final Stream<List<Transaction>> _txStream;
  Map<String, int> _budgets = {};
  bool _loadingBudgets = true;

  @override
  void initState() {
    super.initState();
    _txStream = widget.repo.watchAll();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final budgets = await BudgetService.getAllBudgets();
    if (mounted) {
      setState(() {
        _budgets = budgets;
        _loadingBudgets = false;
      });
    }
  }

  Future<void> _goToBudgetScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetScreen(repo: widget.repo),
      ),
    );
    _loadBudgets(); // Làm mới dữ liệu ngân sách sau khi quay lại
  }

  Future<void> _goToRegexRulesScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegexRulesScreen(repo: widget.repo),
      ),
    );
  }

  /*
  Future<void> _goToSavingsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavingsScreen(db: widget.repo.db),
      ),
    );
  }
  */


  // Helper format tiền tệ VND
  String _formatVnd(num amount) {
    final cleanAmount = amount.abs().toInt();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final match = cleanAmount.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$match đ';
  }

  // Format tiền tệ rút gọn cho nhãn trục biểu đồ cột (ví dụ 1.2M, 500K)
  String _formatShortVnd(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  // Lấy danh sách giao dịch tương ứng với khoảng thời gian đã chọn
  List<Transaction> _filterTransactionsByPeriod(List<Transaction> allTransactions) {
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    
    // Tháng trước
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0, 23, 59, 59, 999);

    // 6 tháng qua
    final startOfSixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    return allTransactions.where((tx) {
      final txDate = DateTime.fromMillisecondsSinceEpoch(tx.timestampMs);
      
      // Không thống kê các giao dịch nháp (Chưa được duyệt)
      if (tx.isDraft) return false;

      if (_selectedPeriod == 0) {
        return txDate.isAfter(startOfThisMonth) || txDate.isAtSameMomentAs(startOfThisMonth);
      } else if (_selectedPeriod == 1) {
        return (txDate.isAfter(startOfLastMonth) || txDate.isAtSameMomentAs(startOfLastMonth)) &&
            txDate.isBefore(endOfLastMonth);
      } else {
        return txDate.isAfter(startOfSixMonthsAgo) || txDate.isAtSameMomentAs(startOfSixMonthsAgo);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Thống kê chi tiêu',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            fontFamily: 'SF Pro Display',
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.code_rounded, color: Color(0xFF1A1A1A)),
          //   tooltip: 'Quản lý Regex Rules',
          //   onPressed: _goToRegexRulesScreen,
          // ),
          /*
          IconButton(
            icon: const Icon(Icons.savings_rounded, color: Color(0xFFFF7597)),
            tooltip: 'Hũ tích luỹ Kakeibo',
            onPressed: _goToSavingsScreen,
          ),
          */
          IconButton(
            icon: const Icon(Icons.track_changes_rounded, color: Color(0xFF1A1A1A)),
            tooltip: 'Quản lý ngân sách',
            onPressed: _goToBudgetScreen,
          ),
        ],

      ),
      body: StreamBuilder<List<Transaction>>(
        stream: _txStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            );
          }

          final allTransactions = snapshot.data ?? [];
          final filteredTransactions = _filterTransactionsByPeriod(allTransactions);

          // Tính toán tổng quan tài chính
          int totalIncome = 0;
          int totalExpense = 0;
          
          for (final tx in filteredTransactions) {
            if (tx.sign == 'credit') {
              totalIncome += tx.amountVnd;
            } else {
              totalExpense += tx.amountVnd;
            }
          }
          final netFlow = totalIncome - totalExpense;

          // Phân nhóm chi tiêu theo danh mục
          final Map<String, int> categorySpending = {};
          for (final tx in filteredTransactions) {
            if (tx.sign == 'debit') {
              final categoryId = tx.categoryId ?? 'others';
              categorySpending[categoryId] = (categorySpending[categoryId] ?? 0) + tx.amountVnd;
            }
          }

          // Sắp xếp danh mục từ cao đến thấp để vẽ chart và chú thích trực quan hơn
          final sortedCategories = categorySpending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
            physics: const BouncingScrollPhysics(),
            children: [
              // Bộ lọc thời gian (Tab selector)
              _buildPeriodSelector(),
              const SizedBox(height: 24),

              // Thẻ Tóm tắt tài chính dạng Grid
              _buildFinancialSummary(totalIncome, totalExpense, netFlow),
              const SizedBox(height: 24),

              /*
              // Panel Hũ tài chính Kakeibo
              _buildSavingsDashboardPanel(),
              const SizedBox(height: 24),
              */

              // Panel ngân sách tổng quan tháng này (Chỉ hiển thị khi đang lọc Tháng này)
              if (_selectedPeriod == 0 && !_loadingBudgets) ...[
                _buildBudgetOverviewPanel(totalExpense, categorySpending),
                const SizedBox(height: 24),
              ],

              // Biểu đồ tròn - Phân bổ chi tiêu (Pie Chart Panel)
              _buildPieChartPanel(totalExpense, sortedCategories),
              const SizedBox(height: 24),

              // Biểu đồ cột - Biến động qua các tháng (Trend Panel)
              _buildMonthlyTrendPanel(allTransactions),
            ],
          );
        },
      ),
    );
  }

  /*
  // WIDGET: Panel Hũ tài chính Kakeibo tích hợp Dashboard Premium Glassmorphism
  Widget _buildSavingsDashboardPanel() {
    return StreamBuilder<List<SavingsEnvelope>>(
      stream: widget.repo.db.watchAllSavingsEnvelopes(),
      builder: (context, snapshot) {
        final envelopes = snapshot.data ?? [];
        final activeEnvelopes = envelopes.where((e) => e.isActive).toList();
        if (activeEnvelopes.isEmpty) {
          return const SizedBox.shrink();
        }

        int totalSavings = 0;
        for (final e in activeEnvelopes) {
          totalSavings += e.currentAmountVnd;
        }

        return DashboardSavingsPanel(
          activeEnvelopes: activeEnvelopes,
          totalSavings: totalSavings,
          formatVnd: _formatVnd,
          onTap: _goToSavingsScreen,
        );
      },
    );
  }
  */

  // WIDGET: Bộ lọc khoảng thời gian
  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodTab(0, 'Tháng này'),
          _buildPeriodTab(1, 'Tháng trước'),
          _buildPeriodTab(2, '6 tháng qua'),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(int index, String title) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPeriod = index;
            _touchedPieIndex = -1; // Reset selection khi đổi khoảng thời gian
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Thẻ tổng kết tài chính (Grid)
  Widget _buildFinancialSummary(int income, int expense, int netFlow) {
    return Column(
      children: [
        // Thẻ Net Flow lớn chính giữa
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tích lũy ròng',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${netFlow >= 0 ? "+" : ""}${_formatVnd(netFlow)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: netFlow >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF2D55),
                  fontFamily: 'SF Pro Display',
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Thu nhập & Chi tiêu song song
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34C759).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            size: 16,
                            color: Color(0xFF34C759),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Thu nhập',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E8E93),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatVnd(income),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34C759),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.trending_down_rounded,
                            size: 16,
                            color: Color(0xFFFF9500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Chi tiêu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF8E8E93),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatVnd(expense),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF9500),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // WIDGET: Panel Tóm tắt Ngân sách tháng này (Glassmorphism)
  Widget _buildBudgetOverviewPanel(int totalExpense, Map<String, int> categorySpending) {
    int totalBudget = 0;
    for (final val in _budgets.values) {
      totalBudget += val;
    }

    if (totalBudget == 0) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.track_changes_rounded, color: Color(0xFF8E8E93), size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa thiết lập ngân sách',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Đặt hạn mức để kiểm soát chi tiêu kỷ luật hơn!',
                    style: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _goToBudgetScreen,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.08),
                foregroundColor: const Color(0xFF007AFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Thiết lập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    final double percent = totalExpense / totalBudget;
    final Color overallColor = percent >= 1.0
        ? const Color(0xFFFF2D55) // Đỏ
        : percent >= 0.8
            ? const Color(0xFFFF9500) // Vàng
            : const Color(0xFF34C759); // Xanh lá

    // Phân tích danh mục vượt ngưỡng (>= 80% hoặc >= 100% ngân sách)
    final List<Map<String, dynamic>> dangerCategories = [];
    for (final cat in AppCategory.values) {
      if (cat.id == 'income') continue;
      final budget = _budgets[cat.id] ?? 0;
      if (budget <= 0) continue;
      final spent = categorySpending[cat.id] ?? 0;
      final double ratio = spent / budget;
      if (ratio >= 0.8) {
        dangerCategories.add({
          'category': cat,
          'spent': spent,
          'budget': budget,
          'ratio': ratio,
        });
      }
    }

    // Sắp xếp các danh mục nguy hiểm theo độ nghiêm trọng giảm dần (vượt hạn mức nhiều nhất lên đầu)
    dangerCategories.sort((a, b) => (b['ratio'] as double).compareTo(a['ratio'] as double));

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: _goToBudgetScreen,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.track_changes_rounded, color: Color(0xFF1A1A1A), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Giám sát ngân sách tháng',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          percent >= 1.0
                              ? 'Vượt hạn mức! ⚠️'
                              : 'Đã dùng ${(percent * 100).toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: overallColor),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFC7C7CC)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatVnd(totalExpense),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ ${_formatVnd(totalBudget)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Thanh tiến trình ngân sách đổi màu sinh động
                Stack(
                  children: [
                    Container(
                      height: 5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent.clamp(0.0, 1.0),
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: overallColor,
                          borderRadius: BorderRadius.circular(2.5),
                          boxShadow: [
                            BoxShadow(
                              color: overallColor.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // SMART ALERTS BANNER (Nếu có danh mục chạm hoặc vượt ngưỡng chi tiêu)
                if (dangerCategories.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.03), // Hồng nhạt cao cấp tối giản
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.10),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notification_important_rounded,
                              color: Color(0xFFFF3B30),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'CẢNH BÁO CHI TIÊU VƯỢT NGƯỠNG',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF3B30),
                                letterSpacing: 0.5,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${dangerCategories.length} danh mục bị ảnh hưởng',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF3B30),
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dangerCategories.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = dangerCategories[index];
                            final cat = item['category'] as AppCategory;
                            final spent = item['spent'] as int;
                            final budget = item['budget'] as int;
                            final ratio = item['ratio'] as double;
                            final isOverLimit = ratio >= 1.0;

                            return Row(
                              children: [
                                // Icon đại diện danh mục
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cat.color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    cat.icon,
                                    color: cat.color,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Thông tin chi tiêu cụ thể
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.nameVi,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1A1A1A),
                                          fontFamily: 'SF Pro Display',
                                        ),
                                      ),
                                      const SizedBox(height: 1.5),
                                      Text(
                                        'Đã tiêu: ${_formatVnd(spent)} / Hạn mức: ${_formatVnd(budget)}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF8E8E93),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'SF Pro Text',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Badge thông tin phần trăm nguy hiểm
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isOverLimit
                                        ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
                                        : const Color(0xFFFF9500).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isOverLimit
                                        ? 'Vượt ${( (ratio - 1.0) * 100 ).toInt()}% ⚠️'
                                        : 'Đã dùng ${(ratio * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isOverLimit ? const Color(0xFFFF3B30) : const Color(0xFFFF9500),
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Biểu đồ tròn phân bổ chi tiêu
  Widget _buildPieChartPanel(int totalExpense, List<MapEntry<String, int>> sortedCategories) {
    if (totalExpense == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 48, color: Color(0xFFC7C7CC)),
              SizedBox(height: 12),
              Text(
                'Không có dữ liệu chi tiêu trong kỳ này',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Xác định thông tin hiển thị tại tâm hình tròn
    String centerTitle = 'Tổng chi';
    String centerValue = _formatVnd(totalExpense);
    Color centerColor = const Color(0xFF1A1A1A);

    if (_touchedPieIndex != -1 && _touchedPieIndex < sortedCategories.length) {
      final touchedEntry = sortedCategories[_touchedPieIndex];
      final cat = AppCategory.fromId(touchedEntry.key);
      centerTitle = cat.nameVi;
      centerValue = _formatVnd(touchedEntry.value);
      centerColor = cat.color;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bổ chi tiêu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              fontFamily: 'SF Pro Display',
            ),
          ),
          const SizedBox(height: 20),
          
          // Khu vực Biểu đồ tròn
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                // Biểu đồ Pie Chart
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        final touchedSection = pieTouchResponse?.touchedSection;
                        if (touchedSection == null || !event.isInterestedForInteractions) {
                          if (_touchedPieIndex != -1) {
                            setState(() {
                              _touchedPieIndex = -1;
                            });
                          }
                          return;
                        }
                        
                        final index = touchedSection.touchedSectionIndex;
                        if (_touchedPieIndex != index) {
                          setState(() {
                            _touchedPieIndex = index;
                          });
                        }
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 65,
                    sections: _buildPieSections(totalExpense, sortedCategories),
                  ),
                ),
                // Panel kính mờ ở tâm hiển thị thông tin khi chạm
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  centerTitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8E8E93),
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  centerValue,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: centerColor,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danh sách chú thích (Legend)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedCategories.length,
            separatorBuilder: (context, index) => const Divider(height: 16, color: Color(0xFFE5E5EA)),
            itemBuilder: (context, index) {
              final entry = sortedCategories[index];
              final cat = AppCategory.fromId(entry.key);
              final pct = (entry.value / totalExpense) * 100;
              final isTouched = _touchedPieIndex == index;

              // Lấy budget nếu là Tháng này
              final budget = _selectedPeriod == 0 ? (_budgets[cat.id] ?? 0) : 0;
              final double budgetPercent = budget > 0 ? (entry.value / budget) : 0.0;
              
              // Màu sắc progress bar của legend: đổi màu theo ngân sách nếu có thiết lập ngân sách
              final Color legendProgressColor = budget > 0
                  ? (budgetPercent >= 1.0
                      ? const Color(0xFFFF2D55) // Đỏ
                      : budgetPercent >= 0.8
                          ? const Color(0xFFFF9500) // Vàng
                          : const Color(0xFF34C759)) // Xanh lá
                  : cat.color;

              return InkWell(
                onTap: () {
                  setState(() {
                    _touchedPieIndex = isTouched ? -1 : index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isTouched ? cat.color.withValues(alpha: 0.06) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Icon đại diện tròn
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat.icon,
                          size: 16,
                          color: cat.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Tên danh mục & Thanh tiến trình tỉ lệ phần trăm
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.nameVi,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isTouched ? FontWeight.w600 : FontWeight.w500,
                                color: const Color(0xFF1A1A1A),
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Thanh progress hiển thị trực quan
                            Stack(
                              children: [
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E5EA),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: (budget > 0 ? budgetPercent.clamp(0.0, 1.0) : (pct / 100)),
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: legendProgressColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Thông tin nhãn nhỏ giải thích ở dưới
                            Text(
                              budget > 0
                                  ? 'Ngân sách: Đã chi ${_formatVnd(entry.value)} / ${_formatVnd(budget)} (${(budgetPercent * 100).toStringAsFixed(0)}%)'
                                  : 'Tỉ lệ: ${pct.toStringAsFixed(1)}% chi tiêu toàn bộ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: budget > 0 ? legendProgressColor : const Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Số tiền & Tỷ lệ %
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatVnd(entry.value),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8E8E93),
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // TẠO SECTIONS CHO PIE CHART
  List<PieChartSectionData> _buildPieSections(int totalExpense, List<MapEntry<String, int>> sortedCategories) {
    return List.generate(sortedCategories.length, (i) {
      final isTouched = i == _touchedPieIndex;
      final radius = isTouched ? 24.0 : 16.0;
      final entry = sortedCategories[i];
      final cat = AppCategory.fromId(entry.key);

      return PieChartSectionData(
        color: cat.color,
        value: entry.value.toDouble(),
        title: '', // Không vẽ text trực tiếp lên lát cắt để giữ UI cực tinh giản
        radius: radius,
        showTitle: false,
      );
    });
  }

  // WIDGET: Biểu đồ cột xu hướng chi tiêu 6 tháng gần nhất
  Widget _buildMonthlyTrendPanel(List<Transaction> allTransactions) {
    // 1. Phân chia 6 tháng gần nhất từ hiện tại lùi về sau
    final now = DateTime.now();
    final List<DateTime> months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    // 2. Tính toán tổng chi tiêu của từng tháng
    final List<double> monthlyExpenses = List.filled(6, 0.0);
    
    for (final tx in allTransactions) {
      if (tx.isDraft || tx.sign != 'debit') continue;
      
      final txDate = DateTime.fromMillisecondsSinceEpoch(tx.timestampMs);
      
      for (int i = 0; i < 6; i++) {
        final targetMonth = months[i];
        if (txDate.year == targetMonth.year && txDate.month == targetMonth.month) {
          monthlyExpenses[i] += tx.amountVnd.toDouble();
          break;
        }
      }
    }

    // Tìm giá trị max để tự động scale trục Y
    double maxVal = 0;
    for (final val in monthlyExpenses) {
      if (val > maxVal) maxVal = val;
    }
    // Backup nếu ko có chi tiêu nào
    if (maxVal == 0) maxVal = 1000000;
    // Làm tròn lên mức đẹp nhất để làm mốc trục Y
    final double yLimit = (maxVal * 1.15);

    // Tính toán tỷ lệ biến động % giữa tháng này và tháng trước (2 tháng cuối trong list 6 tháng)
    double percentComparison = 0;
    bool hasComparison = false;
    final double thisMonthExp = monthlyExpenses[5];
    final double lastMonthExp = monthlyExpenses[4];
    
    if (lastMonthExp > 0) {
      percentComparison = ((thisMonthExp - lastMonthExp) / lastMonthExp) * 100;
      hasComparison = true;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Xu hướng chi tiêu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'SF Pro Display',
                ),
              ),
              if (hasComparison)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: percentComparison <= 0
                        ? const Color(0xFF34C759).withValues(alpha: 0.1)
                        : const Color(0xFFFF2D55).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        percentComparison <= 0 ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                        size: 14,
                        color: percentComparison <= 0 ? const Color(0xFF34C759) : const Color(0xFFFF2D55),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${percentComparison.abs().toStringAsFixed(0)}% so với thg trước',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: percentComparison <= 0 ? const Color(0xFF34C759) : const Color(0xFFFF2D55),
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Khu vực vẽ biểu đồ cột
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: yLimit,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A1A1A),
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        _formatVnd(rod.toY),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          fontFamily: 'SF Pro Display',
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == yLimit) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            _formatShortVnd(value),
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                              fontFamily: 'SF Pro Display',
                            ),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 6) return const SizedBox();
                        final dt = months[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'T${dt.month}',
                            style: TextStyle(
                              color: index == 5 ? const Color(0xFF007AFF) : const Color(0xFF8E8E93),
                              fontWeight: index == 5 ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 11,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFE5E5EA),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(6, (i) {
                  final expenseVal = monthlyExpenses[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: expenseVal,
                        gradient: LinearGradient(
                          colors: i == 5
                              ? [const Color(0xFF007AFF), const Color(0xFF00C6FF)] // Tháng này nổi bật hơn
                              : [const Color(0xFF8E8E93), const Color(0xFFC7C7CC)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 14,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PREMIUM SAVINGS DASHBOARD PANEL WIDGET ───────────────────────────────────

class DashboardSavingsPanel extends StatefulWidget {
  final List<SavingsEnvelope> activeEnvelopes;
  final int totalSavings;
  final String Function(num) formatVnd;
  final VoidCallback onTap;

  const DashboardSavingsPanel({
    super.key,
    required this.activeEnvelopes,
    required this.totalSavings,
    required this.formatVnd,
    required this.onTap,
  });

  @override
  State<DashboardSavingsPanel> createState() => _DashboardSavingsPanelState();
}

class _DashboardSavingsPanelState extends State<DashboardSavingsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF5856D6).withOpacity(0.16), // Viền tím-xanh hi-tech mỏng tinh tế
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5856D6).withOpacity(0.04), // Ánh phát sáng mờ nhẹ neon
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Nền chất lỏng sóng ngang cuộn mượt mà mờ ảo Glassmorphism
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _DashboardLiquidPainter(
                        animationValue: _controller.value,
                        baseColor: const Color(0xFF007AFF),
                      ),
                    );
                  },
                ),
              ),

              // 2. Tấm lọc kính mờ BackdropFilter tạo chiều sâu sang trọng
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.white.withOpacity(0.76), // Nền mờ kính siêu xịn
                  ),
                ),
              ),

              // 3. Nội dung hiển thị sắc nét ở trên cùng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Icon hũ neon phát sáng nhè nhẹ
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: Color(0xFF007AFF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    
                    // Thông số
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Hũ tài chính Kakeibo 🐷',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1C1C1E),
                              fontFamily: 'SF Pro Display',
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            'Tổng tích luỹ: ${widget.formatVnd(widget.totalSavings)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF5856D6),
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Mũi tên và số lượng hũ hoạt động
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5856D6).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.activeEnvelopes.length} hũ',
                            style: const TextStyle(
                              color: Color(0xFF5856D6),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF8E8E93),
                          size: 13,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardLiquidPainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;

  _DashboardLiquidPainter({required this.animationValue, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = baseColor.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = const Color(0xFF5856D6).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    final path2 = Path();

    final double midY = size.height * 0.55;
    
    path1.moveTo(0, size.height);
    path2.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 3.0) {
      final relativeX = x / size.width;
      // Sóng 1
      final y1 = midY + 7 * sin((relativeX * 2 * pi * 1.2) + (animationValue * 2 * pi));
      path1.lineTo(x, y1);
      // Sóng 2
      final y2 = midY + 5 * cos((relativeX * 2 * pi * 1.5) - (animationValue * 2 * pi) + pi / 4);
      path2.lineTo(x, y2);
    }

    path1.lineTo(size.width, size.height);
    path1.close();
    path2.lineTo(size.width, size.height);
    path2.close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _DashboardLiquidPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
