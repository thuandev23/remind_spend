import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/db/app_db.dart';
import 'package:remind_spend/services/savings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDb db;

  setUp(() async {
    db = AppDb.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // Helper tạo hũ tích luỹ nhanh
  SavingsEnvelopesCompanion makeEnvelope({
    required String id,
    required String name,
    int targetAmount = 0,
    int currentAmount = 0,
    int percent = 0,
    String colorHex = '#2ECC71',
    int iconCode = 0xf0160,
  }) {
    return SavingsEnvelopesCompanion.insert(
      id: id,
      name: name,
      targetAmountVnd: Value(targetAmount),
      currentAmountVnd: Value(currentAmount),
      autoAllocationPercent: Value(percent),
      colorHex: colorHex,
      iconCode: iconCode,
      isActive: const Value(true),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  group('SavingsService - Quản lý Hũ tài chính (CRUD)', () {
    test('1. Tạo và lấy danh sách hũ tích luỹ chính xác', () async {
      final list1 = await db.getAllSavingsEnvelopes();
      expect(list1, isEmpty);

      // Thêm hũ mới
      final env = makeEnvelope(id: 'env_1', name: 'Mua Macbook Air', targetAmount: 30000000, percent: 15);
      await db.upsertSavingsEnvelope(env);

      final list2 = await db.getAllSavingsEnvelopes();
      expect(list2, hasLength(1));
      expect(list2.first.id, 'env_1');
      expect(list2.first.name, 'Mua Macbook Air');
      expect(list2.first.targetAmountVnd, 30000000);
      expect(list2.first.autoAllocationPercent, 15);
    });

    test('2. Cập nhật và Xoá hũ tích luỹ chính xác', () async {
      final env = makeEnvelope(id: 'env_1', name: 'Mua Macbook Air', targetAmount: 30000000, percent: 15);
      await db.upsertSavingsEnvelope(env);

      // Cập nhật tên và số dư hiện tại
      final updated = makeEnvelope(id: 'env_1', name: 'Mua Macbook Air M3', targetAmount: 30000000, currentAmount: 5000000, percent: 20);
      await db.upsertSavingsEnvelope(updated);

      final listAfterUpdate = await db.getAllSavingsEnvelopes();
      expect(listAfterUpdate.first.name, 'Mua Macbook Air M3');
      expect(listAfterUpdate.first.currentAmountVnd, 5000000);
      expect(listAfterUpdate.first.autoAllocationPercent, 20);

      // Xoá hũ
      await db.deleteSavingsEnvelope('env_1');
      final listAfterDelete = await db.getAllSavingsEnvelopes();
      expect(listAfterDelete, isEmpty);
    });
  group('SavingsService - Nạp & Rút thủ công', () {
    test('3. Nạp tiền vào hũ cập nhật chính xác số dư và lưu logs', () async {
      final env = makeEnvelope(id: 'env_1', name: 'Quỹ khẩn cấp', currentAmount: 1000000);
      await db.upsertSavingsEnvelope(env);

      // Nạp thêm 500,000 VND
      await SavingsService.depositToEnvelope(db, 'env_1', 500000, 'Thưởng dự án');

      // Kiểm tra số dư mới
      final envelopes = await db.getAllSavingsEnvelopes();
      expect(envelopes.first.currentAmountVnd, 1500000);

      // Kiểm tra logs
      final logs = await db.getEnvelopeLogs('env_1');
      expect(logs, hasLength(1));
      expect(logs.first.amountVnd, 500000);
      expect(logs.first.description, 'Thưởng dự án');
    });

    test('4. Rút tiền từ hũ cập nhật chính xác số dư và lưu logs', () async {
      final env = makeEnvelope(id: 'env_1', name: 'Mua Macbook', currentAmount: 10000000);
      await db.upsertSavingsEnvelope(env);

      // Rút 2,000,000 VND mua sắm phụ kiện
      await SavingsService.withdrawFromEnvelope(db, 'env_1', 2000000, 'Mua chuột Magic Mouse');

      // Kiểm tra số dư mới
      final envelopes = await db.getAllSavingsEnvelopes();
      expect(envelopes.first.currentAmountVnd, 8000000);

      // Kiểm tra logs
      final logs = await db.getEnvelopeLogs('env_1');
      expect(logs, hasLength(1));
      expect(logs.first.amountVnd, -2000000);
      expect(logs.first.description, 'Mua chuột Magic Mouse');
    });
  });

  group('SavingsService - Tự động trích lập thu nhập (Auto-Allocation Engine)', () {
    test('5. Tự động trích lập chính xác khi nhận thu nhập Credit', () async {
      // 1. Tạo hũ 1 trích lập 15%
      final env1 = makeEnvelope(id: 'env_macbook', name: 'Mua Macbook', percent: 15);
      await db.upsertSavingsEnvelope(env1);

      // 2. Tạo hũ 2 trích lập 10%
      final env2 = makeEnvelope(id: 'env_emergency', name: 'Quỹ khẩn cấp', percent: 10);
      await db.upsertSavingsEnvelope(env2);

      // 3. Tạo hũ 3 trích lập 0% (Không trích lập tự động)
      final env3 = makeEnvelope(id: 'env_travel', name: 'Du lịch', percent: 0);
      await db.upsertSavingsEnvelope(env3);

      // 4. Kích hoạt trích lập tự động từ thu nhập lương 20,000,000 VND
      await SavingsService.autoAllocateCredit(db, 20000000, 'Lương tháng 5');

      // 5. Kiểm tra kết quả
      final list = await db.getAllSavingsEnvelopes();
      final macbook = list.firstWhere((e) => e.id == 'env_macbook');
      final emergency = list.firstWhere((e) => e.id == 'env_emergency');
      final travel = list.firstWhere((e) => e.id == 'env_travel');

      // Hũ Macbook trích 15% của 20M = 3,000,000đ
      expect(macbook.currentAmountVnd, 3000000);

      // Hũ Quỹ khẩn cấp trích 10% của 20M = 2,000,000đ
      expect(emergency.currentAmountVnd, 2000000);

      // Hũ Du lịch không trích = 0đ
      expect(travel.currentAmountVnd, 0);

      // 6. Kiểm tra logs trích lập tự động của hũ Macbook
      final macbookLogs = await db.getEnvelopeLogs('env_macbook');
      expect(macbookLogs, hasLength(1));
      expect(macbookLogs.first.amountVnd, 3000000);
      expect(macbookLogs.first.description, 'Tự động trích lập 15% từ: Lương tháng 5');

      // Kiểm tra logs trích lập tự động của hũ Quỹ khẩn cấp
      final emergencyLogs = await db.getEnvelopeLogs('env_emergency');
      expect(emergencyLogs, hasLength(1));
      expect(emergencyLogs.first.amountVnd, 2000000);
      expect(emergencyLogs.first.description, 'Tự động trích lập 10% từ: Lương tháng 5');
    });

    test('6. Không trích lập từ giao dịch <= 0 VND hoặc khi không có hũ hoạt động trích lập', () async {
      final env = makeEnvelope(id: 'env_macbook', name: 'Mua Macbook', percent: 15);
      await db.upsertSavingsEnvelope(env);

      // Thu nhập bằng 0
      await SavingsService.autoAllocateCredit(db, 0, 'Không làm gì');
      final envelopes = await db.getAllSavingsEnvelopes();
      expect(envelopes.first.currentAmountVnd, 0);
    });
  });
});
}
