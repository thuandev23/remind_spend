import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remind_spend/db/app_db.dart';
import 'package:remind_spend/services/budget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel =
      MethodChannel('com.example.remind_spend/transaction_bridge');

  late AppDb db;
  final List<Map<String, dynamic>> sentNotifications = [];

  setUp(() async {
    // Khởi tạo SharedPreferences mock trống ban đầu cho mỗi test case
    SharedPreferences.setMockInitialValues({});
    db = AppDb.forTesting(NativeDatabase.memory());
    sentNotifications.clear();

    // Mock MethodChannel để bắt các cuộc gọi sendLocalNotification
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      if (call.method == 'sendLocalNotification') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        sentNotifications.add(args);
        return true;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
    await db.close();
  });

  // Helper để tạo dòng giao dịch chèn vào DB
  TransactionsCompanion makeTx({
    required String id,
    required int amount,
    required String categoryId,
    String sign = 'debit',
    bool isDraft = false,
    required int timestampMs,
  }) {
    return TransactionsCompanion.insert(
      id: id,
      bankId: 'vcb',
      amountVnd: amount,
      sign: sign,
      categoryId: Value(categoryId),
      isDraft: Value(isDraft),
      timestampMs: timestampMs,
      createdAt: timestampMs,
    );
  }

  group('BudgetService - Quản lý Ngân sách (CRUD)', () {
    test('1. setBudget và getBudget hoạt động chính xác với SharedPreferences', () async {
      // Mặc định ban đầu chưa set thì budget phải bằng 0
      expect(await BudgetService.getBudget('food'), 0);

      // Thiết lập hạn mức mới
      final success = await BudgetService.setBudget('food', 3000000);
      expect(success, isTrue);

      // Lấy lại hạn mức vừa thiết lập
      expect(await BudgetService.getBudget('food'), 3000000);
    });

    test('2. getAllBudgets trả về ngân sách của tất cả danh mục ngoại trừ income', () async {
      await BudgetService.setBudget('food', 2500000);
      await BudgetService.setBudget('transport', 1000000);
      await BudgetService.setBudget('income', 50000000); // income không nên nằm trong getAllBudgets

      final allBudgets = await BudgetService.getAllBudgets();

      expect(allBudgets['food'], 2500000);
      expect(allBudgets['transport'], 1000000);
      expect(allBudgets.containsKey('income'), isFalse);
      expect(allBudgets['shopping'], 0); // Danh mục khác chưa set mặc định là 0
    });
  });

  group('BudgetService - Tính toán chi tiêu thực tế trong tháng', () {
    test('3. getCategoryExpenseThisMonth tính tổng chính xác cho tháng hiện tại', () async {
      final now = DateTime.now();
      final startMs = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final midMs = DateTime(now.year, now.month, 15).millisecondsSinceEpoch;
      
      // Các mốc thời gian ngoài tháng hiện tại
      final prevMonthMs = DateTime(now.year, now.month - 1, 15).millisecondsSinceEpoch;
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      final nextMonthMs = DateTime(nextYear, nextMonth, 15).millisecondsSinceEpoch;

      // Chèn các giao dịch hợp lệ
      await db.insertTransaction(makeTx(id: 'tx1', amount: 500000, categoryId: 'food', timestampMs: startMs));
      await db.insertTransaction(makeTx(id: 'tx2', amount: 300000, categoryId: 'food', timestampMs: midMs));

      // Chèn các giao dịch không hợp lệ (không được cộng vào tổng chi tiêu)
      await db.insertTransaction(makeTx(id: 'tx_other_cat', amount: 400000, categoryId: 'shopping', timestampMs: midMs));
      await db.insertTransaction(makeTx(id: 'tx_credit', amount: 1000000, categoryId: 'food', sign: 'credit', timestampMs: midMs));
      await db.insertTransaction(makeTx(id: 'tx_draft', amount: 200000, categoryId: 'food', isDraft: true, timestampMs: midMs));
      await db.insertTransaction(makeTx(id: 'tx_prev_month', amount: 600000, categoryId: 'food', timestampMs: prevMonthMs));
      await db.insertTransaction(makeTx(id: 'tx_next_month', amount: 700000, categoryId: 'food', timestampMs: nextMonthMs));

      final totalExpense = await BudgetService.getCategoryExpenseThisMonth(db, 'food');
      
      // Chỉ tx1 (500,000) và tx2 (300,000) là hợp lệ. Tổng phải là 800,000 VND
      expect(totalExpense, 800000);
    });
  });

  group('BudgetService - Kiểm tra ngân sách & Cảnh báo chi tiêu (Smart Alert)', () {
    test('4. checkAndNotifyBudget bỏ qua nếu categoryId null hoặc income hoặc budget chưa set', () async {
      await BudgetService.checkAndNotifyBudget(db, null);
      await BudgetService.checkAndNotifyBudget(db, 'income');
      await BudgetService.checkAndNotifyBudget(db, 'food'); // budget chưa set (=0)

      expect(sentNotifications, isEmpty);
    });

    test('5. checkAndNotifyBudget gửi cảnh báo 80% và chặn spam thông minh', () async {
      final now = DateTime.now();
      final midMs = DateTime(now.year, now.month, 15).millisecondsSinceEpoch;

      // Thiết lập ngân sách là 1,000,000 VND
      await BudgetService.setBudget('shopping', 1000000);

      // 1. Chi tiêu 790,000 VND (< 80%) -> Không có thông báo
      await db.insertTransaction(makeTx(id: 'tx1', amount: 790000, categoryId: 'shopping', timestampMs: midMs));
      await BudgetService.checkAndNotifyBudget(db, 'shopping');
      expect(sentNotifications, isEmpty);

      // 2. Chi tiêu thêm 20,000 VND -> Tổng 810,000 VND (81% >= 80%) -> Gửi cảnh báo 80% lần đầu
      await db.insertTransaction(makeTx(id: 'tx2', amount: 200000, categoryId: 'shopping', timestampMs: midMs)); // Thực tế tổng là 990,000 VND (99%)
      await BudgetService.checkAndNotifyBudget(db, 'shopping');
      expect(sentNotifications, hasLength(1));
      expect(sentNotifications.first['title'], '⚠️ Cảnh báo chi tiêu!');
      expect(sentNotifications.first['body'], contains('vượt quá 80% ngân sách'));

      // Xoá danh sách để test chặn spam
      sentNotifications.clear();

      // 3. Gọi lại checkAndNotifyBudget mà chi tiêu vẫn ở ngưỡng 80%-100% -> Chặn không gửi lại (Tránh spam)
      await BudgetService.checkAndNotifyBudget(db, 'shopping');
      expect(sentNotifications, isEmpty);
    });

    test('6. checkAndNotifyBudget gửi cảnh báo 100% và chặn spam thông minh', () async {
      final now = DateTime.now();
      final midMs = DateTime(now.year, now.month, 15).millisecondsSinceEpoch;

      // Thiết lập ngân sách là 1,000,000 VND
      await BudgetService.setBudget('food', 1000000);

      // Chi tiêu 1,050,000 VND (105% >= 100%)
      await db.insertTransaction(makeTx(id: 'tx1', amount: 1050000, categoryId: 'food', timestampMs: midMs));
      await BudgetService.checkAndNotifyBudget(db, 'food');

      // Phải gửi cảnh báo 100%
      expect(sentNotifications, hasLength(1));
      expect(sentNotifications.first['title'], '⚠️ Vượt hạn mức chi tiêu!');
      expect(sentNotifications.first['body'], contains('vượt quá 100% ngân sách'));

      sentNotifications.clear();

      // Gọi lại -> Chặn không gửi trùng
      await BudgetService.checkAndNotifyBudget(db, 'food');
      expect(sentNotifications, isEmpty);
    });

    test('7. Tự động reset cờ cảnh báo thông minh khi chi tiêu giảm dưới ngưỡng', () async {
      final now = DateTime.now();
      final midMs = DateTime(now.year, now.month, 15).millisecondsSinceEpoch;

      await BudgetService.setBudget('entertainment', 1000000);

      // 1. Chi tiêu 850,000 VND -> Gửi thông báo 80%
      await db.insertTransaction(makeTx(id: 'tx1', amount: 850000, categoryId: 'entertainment', timestampMs: midMs));
      await BudgetService.checkAndNotifyBudget(db, 'entertainment');
      expect(sentNotifications, hasLength(1));
      expect(sentNotifications.first['title'], '⚠️ Cảnh báo chi tiêu!');

      sentNotifications.clear();

      // 2. Người dùng xoá giao dịch tx1 -> Chi tiêu về 0 VND (< 80%)
      // Gọi checkAndNotifyBudget để đồng bộ trạng thái và reset cờ
      await db.customStatement('DELETE FROM transactions WHERE id = ?', ['tx1']);
      await BudgetService.checkAndNotifyBudget(db, 'entertainment');
      expect(sentNotifications, isEmpty);

      // 3. Chi tiêu lại 850,000 VND -> Do cờ đã được reset thành công, hệ thống PHẢI gửi lại cảnh báo 80%
      await db.insertTransaction(makeTx(id: 'tx2', amount: 850000, categoryId: 'entertainment', timestampMs: midMs));
      await BudgetService.checkAndNotifyBudget(db, 'entertainment');
      expect(sentNotifications, hasLength(1));
      expect(sentNotifications.first['title'], '⚠️ Cảnh báo chi tiêu!');
    });
  });
}
