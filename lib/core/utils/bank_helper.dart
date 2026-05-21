// Bộ tiện ích phân tích và hỗ trợ hiển thị thông tin ngân hàng.

/// Lấy tên thương hiệu hiển thị chính thức của ngân hàng dựa trên mã định danh.
String getBankDisplayName(String bankId) {
  return switch (bankId.toLowerCase()) {
    'vcb' => 'Vietcombank',
    'mb' => 'MB Bank',
    'tcb' => 'Techcombank',
    'acb' => 'ACB',
    'bidv' => 'BIDV',
    'vtb' => 'Vietinbank',
    'momo' => 'MoMo',
    'zalopay' => 'ZaloPay',
    _ => bankId.toUpperCase(),
  };
}
