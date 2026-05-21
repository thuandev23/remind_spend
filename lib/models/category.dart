import 'package:flutter/material.dart';

class AppCategory {
  final String id;
  final String nameVi;
  final String nameEn;
  final IconData icon;
  final Color color;

  const AppCategory({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.color,
  });

  /// Lấy tên danh mục dựa theo ngôn ngữ đang chọn
  String getLocalizedName(bool isEnglish) => isEnglish ? nameEn : nameVi;

  // Danh mục định nghĩa sẵn (Premium Palette)
  static const food = AppCategory(
    id: 'food',
    nameVi: 'Ăn uống',
    nameEn: 'Food & Drinks',
    icon: Icons.fastfood_rounded,
    color: Color(0xFFFF9500), // Cam rực rỡ
  );

  static const transport = AppCategory(
    id: 'transport',
    nameVi: 'Di chuyển',
    nameEn: 'Transport',
    icon: Icons.directions_car_rounded,
    color: Color(0xFF007AFF), // Xanh iOS
  );

  static const shopping = AppCategory(
    id: 'shopping',
    nameVi: 'Mua sắm',
    nameEn: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Color(0xFFFF2D55), // Hồng đậm sang trọng
  );

  static const bills = AppCategory(
    id: 'bills',
    nameVi: 'Hóa đơn',
    nameEn: 'Bills & Utilities',
    icon: Icons.receipt_long_rounded,
    color: Color(0xFFAF52DE), // Tím hoàng gia
  );

  static const entertainment = AppCategory(
    id: 'entertainment',
    nameVi: 'Giải trí',
    nameEn: 'Entertainment',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFFFFCC00), // Vàng nghệ thuật
  );

  static const income = AppCategory(
    id: 'income',
    nameVi: 'Thu nhập',
    nameEn: 'Income',
    icon: Icons.trending_up_rounded,
    color: Color(0xFF34C759), // Xanh lá may mắn
  );

  static const others = AppCategory(
    id: 'others',
    nameVi: 'Khác',
    nameEn: 'Others',
    icon: Icons.more_horiz_rounded,
    color: Color(0xFF8E8E93), // Xám thanh lịch
  );

  static const values = [
    food,
    transport,
    shopping,
    bills,
    entertainment,
    income,
    others,
  ];

  /// Ánh xạ ID sang đối tượng AppCategory tương ứng
  static AppCategory fromId(String? id, {String sign = 'debit'}) {
    if (id == null) {
      return sign == 'credit' ? income : others;
    }
    return values.firstWhere(
      (c) => c.id == id,
      orElse: () => sign == 'credit' ? income : others,
    );
  }
}
