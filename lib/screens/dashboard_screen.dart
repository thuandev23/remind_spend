import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../db/app_db.dart';
import '../models/category.dart';
import '../repositories/transaction_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _txStream = widget.repo.watchAll();
  }

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
              // Map trạng thái 'ai_pending' sang 'others' tạm thời trên dashboard
              final categoryId = (tx.categoryId == 'ai_pending') ? 'others' : (tx.categoryId ?? 'others');
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
                                  widthFactor: pct / 100,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
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
