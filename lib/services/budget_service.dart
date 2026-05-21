import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/app_db.dart';
import '../models/category.dart';
import 'bridge_service.dart';
import '../core/utils/formatter.dart';

class BudgetService {
  static const String _budgetPrefix = 'budget_';
  static const String _notified80Prefix = 'notified_80_';
  static const String _notified100Prefix = 'notified_100_';

  /// Thiết lập hạn mức ngân sách cho một danh mục
  static Future<bool> setBudget(String categoryId, int amountVnd) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt('$_budgetPrefix$categoryId', amountVnd);
  }

  /// Lấy hạn mức ngân sách của một danh mục (mặc định là 0 nếu chưa thiết lập)
  static Future<int> getBudget(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_budgetPrefix$categoryId') ?? 0;
  }

  /// Lấy hạn mức ngân sách của tất cả danh mục chi tiêu (loại bỏ 'income')
  static Future<Map<String, int>> getAllBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgets = <String, int>{};
    for (final cat in AppCategory.values) {
      if (cat.id == 'income') continue;
      budgets[cat.id] = prefs.getInt('$_budgetPrefix${cat.id}') ?? 0;
    }
    return budgets;
  }

  /// Tính tổng chi tiêu thực tế (isDraft == false, sign == 'debit') của danh mục trong tháng hiện tại
  static Future<int> getCategoryExpenseThisMonth(AppDb db, String categoryId) async {
    final now = DateTime.now();
    final startMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    // Lấy đầu tháng sau làm cận trên (dùng lessThan)
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    final endMs = DateTime(nextYear, nextMonth, 1).millisecondsSinceEpoch;

    final query = db.select(db.transactions)
      ..where((t) =>
          t.categoryId.equals(categoryId) &
          t.sign.equals('debit') &
          t.isDraft.equals(false) &
          t.timestampMs.isBiggerOrEqualValue(startMs) &
          t.timestampMs.isSmallerThanValue(endMs));

    final rows = await query.get();
    int total = 0;
    for (final row in rows) {
      total += row.amountVnd;
    }
    return total;
  }

  /// Kiểm tra ngân sách và gửi thông báo nếu vượt ngưỡng 80% hoặc 100%
  static Future<void> checkAndNotifyBudget(AppDb db, String? categoryId) async {
    if (categoryId == null || categoryId == 'income') return;

    final budget = await getBudget(categoryId);
    if (budget <= 0) return; // Chưa thiết lập hạn mức hoặc hạn mức bằng 0

    final expense = await getCategoryExpenseThisMonth(db, categoryId);
    final percent = expense / budget;

    final now = DateTime.now();
    final monthKey = '${now.year}_${now.month}';
    final notified80Key = '$_notified80Prefix${categoryId}_$monthKey';
    final notified100Key = '$_notified100Prefix${categoryId}_$monthKey';

    final prefs = await SharedPreferences.getInstance();
    final notified80 = prefs.getBool(notified80Key) ?? false;
    final notified100 = prefs.getBool(notified100Key) ?? false;

    final category = AppCategory.fromId(categoryId);

    if (percent >= 1.0) {
      if (!notified100) {
        // Gửi thông báo vượt 100% ngân sách
        final title = '⚠️ Vượt hạn mức chi tiêu!';
        final body = 'Danh mục "${category.nameVi}" đã vượt quá 100% ngân sách tháng này. Đã chi: ${formatMoneyVnd(expense)} / Hạn mức: ${formatMoneyVnd(budget)}.';
        await BridgeService.sendLocalNotification(title, body);
        
        // Đánh dấu cả hai cờ 80% và 100% để tránh gửi lặp
        await prefs.setBool(notified80Key, true);
        await prefs.setBool(notified100Key, true);
      }
    } else if (percent >= 0.8) {
      if (!notified80) {
        // Gửi thông báo vượt 80% ngân sách
        final title = '⚠️ Cảnh báo chi tiêu!';
        final body = 'Danh mục "${category.nameVi}" đã tiêu dùng vượt quá 80% ngân sách tháng này. Đã chi: ${formatMoneyVnd(expense)} / Hạn mức: ${formatMoneyVnd(budget)}.';
        await BridgeService.sendLocalNotification(title, body);

        await prefs.setBool(notified80Key, true);
        // Reset cờ 100% để nếu sau đó chi tiêu tăng tiếp thì vẫn cảnh báo 100%
        await prefs.setBool(notified100Key, false);
      }
    } else {
      // Dưới 80%, reset các cờ để nếu người dùng xoá bớt giao dịch rồi thêm lại thì vẫn nhận được cảnh báo
      if (notified80 || notified100) {
        await prefs.setBool(notified80Key, false);
        await prefs.setBool(notified100Key, false);
      }
    }
  }
}
