import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/app_db.dart';
import '../models/category.dart';
import '../repositories/transaction_repository.dart';
import '../services/budget_service.dart';
import '../core/utils/formatter.dart';

class BudgetScreen extends StatefulWidget {
  final TransactionRepository repo;

  const BudgetScreen({super.key, required this.repo});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Map<String, int> _budgets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    final budgets = await BudgetService.getAllBudgets();
    if (mounted) {
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    }
  }

  // Helper format tiền tệ VND
  String _formatVnd(num amount) {
    final cleanAmount = amount.abs().toInt();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final match = cleanAmount.toString().replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$match đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '🎯 Quản lý ngân sách',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
              ),
            )
          : StreamBuilder<List<Transaction>>(
              stream: widget.repo.watchAll(),
              builder: (context, snapshot) {
                final allTransactions = snapshot.data ?? [];
                
                // Lọc giao dịch tháng này, đã duyệt, là chi tiêu
                final now = DateTime.now();
                final startOfThisMonth = DateTime(now.year, now.month, 1);
                
                final thisMonthExpenses = allTransactions.where((tx) {
                  if (tx.isDraft || tx.sign != 'debit') return false;
                  final txDate = DateTime.fromMillisecondsSinceEpoch(tx.timestampMs);
                  return txDate.isAfter(startOfThisMonth) || txDate.isAtSameMomentAs(startOfThisMonth);
                }).toList();

                // Tính toán tổng số tiền đã chi của từng danh mục
                final Map<String, int> categorySpending = {};
                for (final tx in thisMonthExpenses) {
                  final catId = tx.categoryId ?? 'others';
                  categorySpending[catId] = (categorySpending[catId] ?? 0) + tx.amountVnd;
                }

                // Tính tổng chi tiêu và tổng ngân sách
                int totalExpense = 0;
                int totalBudget = 0;
                
                for (final cat in AppCategory.values) {
                  if (cat.id == 'income') continue;
                  final expense = categorySpending[cat.id] ?? 0;
                  final budget = _budgets[cat.id] ?? 0;
                  
                  totalExpense += expense;
                  totalBudget += budget;
                }

                final double totalPercent = totalBudget > 0 ? (totalExpense / totalBudget) : 0.0;
                final Color overallColor = totalPercent >= 1.0
                    ? const Color(0xFFFF2D55) // Đỏ
                    : totalPercent >= 0.8
                        ? const Color(0xFFFF9500) // Vàng
                        : const Color(0xFF34C759); // Xanh lá

                return ListView(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Thẻ tổng quan ngân sách cao cấp
                    _buildOverallBudgetCard(totalExpense, totalBudget, totalPercent, overallColor),
                    const SizedBox(height: 28),

                    const Text(
                      'HẠN MỨC THEO DANH MỤC',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF8E8E93),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Danh sách các danh mục chi tiêu lập ngân sách
                    ...AppCategory.values.where((c) => c.id != 'income').map((cat) {
                      final expense = categorySpending[cat.id] ?? 0;
                      final budget = _budgets[cat.id] ?? 0;
                      return _buildCategoryBudgetTile(cat, expense, budget);
                    }),
                  ],
                );
              },
            ),
    );
  }

  // WIDGET: Thẻ tóm tắt ngân sách tổng thể
  Widget _buildOverallBudgetCard(int expense, int budget, double percent, Color color) {
    final formattedPercent = (percent * 100).toStringAsFixed(1);
    
    return Container(
      width: double.infinity,
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
                'NGÂN SÁCH THÁNG NÀY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              if (budget > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Text(
                    percent >= 1.0 ? 'Vượt hạn mức! ⚠️' : '$formattedPercent% đã dùng',
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Chưa thiết lập hạn mức 🎯',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatVnd(expense),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              if (budget > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '/ ${_formatVnd(budget)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Thanh tiến trình ngân sách tổng thể
          Stack(
            children: [
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (budget > 0)
                FractionallySizedBox(
                  widthFactor: percent.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: Hàng danh mục ngân sách
  Widget _buildCategoryBudgetTile(AppCategory cat, int expense, int budget) {
    final double percent = budget > 0 ? (expense / budget) : 0.0;
    
    final Color progressColor = percent >= 1.0
        ? const Color(0xFFFF2D55) // Đỏ
        : percent >= 0.8
            ? const Color(0xFFFF9500) // Vàng
            : const Color(0xFF34C759); // Xanh lá

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showSetupBudgetSheet(cat, budget),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon danh mục hình tròn sang xịn mịn
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cat.icon, size: 20, color: cat.color),
                ),
                const SizedBox(width: 14),

                // Tên & Tiến trình chi tiết
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cat.nameVi,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          // Hiển thị số tiền Đã chi / Hạn mức
                          if (budget > 0)
                            Text(
                              '${_formatVnd(expense)} / ${_formatVnd(budget)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: percent >= 1.0 ? const Color(0xFFFF2D55) : const Color(0xFF8E8E93),
                              ),
                            )
                          else
                            const Text(
                              'Chưa thiết lập',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar của danh mục
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
                          if (budget > 0)
                            FractionallySizedBox(
                              widthFactor: percent.clamp(0.0, 1.0),
                              child: Container(
                                height: 5,
                                decoration: BoxDecoration(
                                  color: progressColor,
                                  borderRadius: BorderRadius.circular(2.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (budget > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đã dùng ${(percent * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: progressColor,
                              ),
                            ),
                            if (percent < 1.0)
                              Text(
                                'Còn lại ${_formatVnd(budget - expense)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFC7C7CC)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET: Bottom Sheet thiết lập ngân sách
  void _showSetupBudgetSheet(AppCategory cat, int currentBudget) {
    final amountController = TextEditingController(
      text: currentBudget > 0 ? _formatPlainNumber(currentBudget) : '',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: formKey,
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

                    // Header Sheet
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ngân sách ${cat.nameVi}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Thiết lập hạn mức chi tiêu hàng tháng',
                              style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'HẠN MỨC MỚI (VND):',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8E8E93),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Input Form
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        suffixText: 'đ',
                        suffixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                        hintText: 'Nhập số tiền...',
                        hintStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cat.color, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng nhập số tiền!';
                        final parsed = int.tryParse(val.replaceAll('.', '')) ?? 0;
                        if (parsed <= 0) return 'Số tiền phải lớn hơn 0!';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Đề xuất hạn mức nhanh (Gợi ý UX tuyệt đẹp)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [1000000, 2000000, 3000000, 5000000, 10000000].map((val) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(
                                formatAmountAbbr(val),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              backgroundColor: const Color(0xFFF2F2F7),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onPressed: () {
                                setStateSheet(() {
                                  amountController.text = _formatPlainNumber(val);
                                  // Chuyển đổi qua custom formatter để hiển thị dấu chấm phần nghìn
                                  final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                                  amountController.text = val.toString().replaceAllMapped(reg, (Match m) => '${m[1]}.');
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Actions Button
                    Row(
                      children: [
                        if (currentBudget > 0) ...[
                          OutlinedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await BudgetService.setBudget(cat.id, 0);
                              await BudgetService.checkAndNotifyBudget(widget.repo.db, cat.id);
                              await _loadBudgets();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF2D55),
                              side: const BorderSide(color: Color(0xFFFFCDD2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            child: const Text('Xoá', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final intVal = int.parse(amountController.text.replaceAll('.', ''));
                                Navigator.pop(context);
                                
                                await BudgetService.setBudget(cat.id, intVal);
                                // Trigger cảnh báo ngân sách realtime ngay lập tức!
                                await BudgetService.checkAndNotifyBudget(widget.repo.db, cat.id);
                                await _loadBudgets();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cat.color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            child: const Text('Thiết lập hạn mức', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatPlainNumber(int value) {
    return value.toString();
  }
}

// ── Custom Currency Input Formatter ──────────────────────────────────────────

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = cleanText.replaceAllMapped(reg, (Match m) => '${m[1]}.');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

