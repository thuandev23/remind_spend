import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/services/categorization_service.dart';

void main() {
  group('CategorizationService - Phân loại Giao dịch Tự động', () {
    test('1. Giao dịch nhận tiền (credit) phải luôn phân loại là income', () {
      expect(CategorizationService.classify('Nhan luong thang 5', 'credit'), 'income');
      expect(CategorizationService.classify('GD +5,000,000đ tu A', 'credit'), 'income');
      expect(CategorizationService.classify(null, 'credit'), 'income');
    });

    test('2. Phân loại Ăn uống (food) - Bao gồm cả có dấu và không dấu', () {
      expect(CategorizationService.classify('Thanh toan tai grabfood', 'debit'), 'food');
      expect(CategorizationService.classify('Ca phe Highlands Coffee', 'debit'), 'food');
      expect(CategorizationService.classify('An sang o tiem banh mi', 'debit'), 'food');
      expect(CategorizationService.classify('Uong tra sua Phuc Long', 'debit'), 'food');
      expect(CategorizationService.classify('Chi tieu tai nha hang Sen', 'debit'), 'food');
    });

    test('3. Phân loại Di chuyển (transport) - Hỗ trợ các hãng xe, xăng xe', () {
      expect(CategorizationService.classify('Chuyen di GrabCar nhan dip mua', 'debit'), 'transport');
      expect(CategorizationService.classify('Thanh toan hoa don do xang xe', 'debit'), 'transport');
      expect(CategorizationService.classify('Mua ve may bay Vietjet Air', 'debit'), 'transport');
      expect(CategorizationService.classify('Dat xe limousine di Da Lat', 'debit'), 'transport');
    });

    test('4. Phân loại Giải trí (entertainment)', () {
      expect(CategorizationService.classify('Gia han thue bao Netflix hang thang', 'debit'), 'entertainment');
      expect(CategorizationService.classify('Mua 2 ve xem phim tai CGV Cinema', 'debit'), 'entertainment');
      expect(CategorizationService.classify('Nap game Steam Wallet', 'debit'), 'entertainment');
    });

    test('5. Phân loại Hóa đơn & Tiện ích (bills)', () {
      expect(CategorizationService.classify('Dong tien dien ky 05/2026', 'debit'), 'bills');
      expect(CategorizationService.classify('Thanh toan tien nuoc sach', 'debit'), 'bills');
      expect(CategorizationService.classify('Nap tien dien thoai Mobifone', 'debit'), 'bills');
      expect(CategorizationService.classify('Dong cuoc Internet thue bao', 'debit'), 'bills');
    });

    test('6. Phân loại Mua sắm (shopping)', () {
      expect(CategorizationService.classify('Mua quan ao tai Uniqlo', 'debit'), 'shopping');
      expect(CategorizationService.classify('Don hang Shopee hoan tat', 'debit'), 'shopping');
      expect(CategorizationService.classify('Di sieu thi WinMart mua do dung', 'debit'), 'shopping');
      expect(CategorizationService.classify('Circle K thanh toan qua QR', 'debit'), 'shopping');
    });

    test('7. Phân loại Khác (others)', () {
      expect(CategorizationService.classify('GD chuyen khoan cho nguoi dung B', 'debit'), 'others');
      expect(CategorizationService.classify('', 'debit'), 'others');
      expect(CategorizationService.classify(null, 'debit'), 'others');
    });
  });
}
