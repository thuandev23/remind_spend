// Các hàm tiện ích định dạng tiền tệ và số tiền của ứng dụng Remind Spend.

/// Định dạng tiền tệ đầy đủ dạng: 1.200.000 đ
String formatMoneyVnd(int amount) {
  final isNegative = amount < 0;
  final absAmount = amount.abs();
  final str = absAmount.toString();
  final buffer = StringBuffer();
  
  int count = 0;
  for (int i = str.length - 1; i >= 0; i--) {
    buffer.write(str[i]);
    count++;
    if (count % 3 == 0 && i > 0) {
      buffer.write('.');
    }
  }
  
  final formattedAbs = buffer.toString().split('').reversed.join('');
  return '${isNegative ? '-' : ''}$formattedAbs đ';
}

/// Định dạng số tiền viết tắt dạng: 1.2tr đ hoặc 150k đ
String formatAmountAbbr(int amount) {
  if (amount >= 1000000) {
    final m = amount / 1000000;
    final formatted = m == m.truncateToDouble() ? m.toInt().toString() : m.toStringAsFixed(1);
    return '${formatted}tr đ';
  }
  if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}k đ';
  }
  return '$amount đ';
}
