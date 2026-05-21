class CategorizationService {
  /// Tự động phân loại tin nhắn giao dịch dựa trên từ khóa và loại giao dịch (sign)
  static String classify(String? rawContent, String sign) {
    if (sign == 'credit') {
      return 'income';
    }

    if (rawContent == null || rawContent.trim().isEmpty) {
      return 'others';
    }

    // Chuyển sang chữ thường không dấu để so khớp chính xác
    final normalized = _normalizeText(rawContent);
    // 1. Ăn uống (Food & Drinks) - Check trước để bắt grabfood, shopeefood
    if (_hasKeyword(normalized, [
      'food', 'grabfood', 'shopeefood', 'baemin', 'cafe', 'highlands',
      'phuc long', 'starbucks', 'nha hang', 'an uong', 'an sang', 'tiem banh',
      'tra sua', 'kfc', 'mcdonald', 'lotteria', 'pizza', 'milktea', 'coffee',
      'the coffee house', 'toco toco', 'gong cha', 'pho', 'bun bo', 'quan an'
    ])) {
      return 'food';
    }

    // 2. Di chuyển (Transport) - Check sau để bắt grab, be còn lại
    if (_hasKeyword(normalized, [
      'grab', 'be', 'taxi', 'xang', 'do xang', 've may bay', 'tau hoa',
      'limousine', 'xe khach', 'bebike', 'grabcar', 'bus', 'vietjet',
      'vietnam airlines', 'bamboo airways', 'gas station', 've tau', 'phuong trang'
    ])) {
      return 'transport';
    }

    // 3. Giải trí (Entertainment)
    if (_hasKeyword(normalized, [
      'netflix', 'spotify', 'cgv', 'rap chieu phim', 'rap phim', 've xem phim',
      'game', 'steam', 'playstation', 'xbox', 'nintendo', 'concert', 'bar',
      'club', 'pub', 'karaoke', 'billiard', 'rap rap', 'rap rap chieu'
    ])) {
      return 'entertainment';
    }

    // 4. Hóa đơn & Tiện ích (Bills)
    if (_hasKeyword(normalized, [
      'dien', 'nuoc', 'wifi', 'internet', 'cuoc thue bao', 'dong tien dien',
      'dong nuoc', 'nap tien dt', 'hoc phi', 'tuition', 'insurance', 'bao hiem',
      'chung cu', 'phi dich vu', 'truyen hinh', 'vtv cab', 'fpt play'
    ])) {
      return 'bills';
    }

    // 5. Mua sắm (Shopping) - Check sau cùng để bắt shopee còn lại
    if (_hasKeyword(normalized, [
      'shopee', 'lazada', 'tiki', 'sieu thi', 'winmart', 'coopmart', 'bach hoa xanh',
      'mua sam', 'dich vu', 'apple', 'google play', 'payoo', 'zara', 'uniqlo',
      'hm', 'fashion', 'clothes', 'store', 'tiki.vn', 'circle k', '7-eleven',
      'gs25', 'family mart', 'aeon', 'lotte', 'watson', 'guardian'
    ])) {
      return 'shopping';
    }

    return 'others';
  }

  static bool _hasKeyword(String normalizedText, List<String> keywords) {
    for (final kw in keywords) {
      if (normalizedText.contains(kw)) {
        return true;
      }
    }
    return false;
  }

  static String _normalizeText(String text) {
    var str = text.toLowerCase();
    
    // Loại bỏ toàn bộ dấu tiếng Việt
    final regexes = [
      RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'),
      RegExp(r'[èéẹẻẽêềếệểễ]'),
      RegExp(r'[ìíịỉĩ]'),
      RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'),
      RegExp(r'[ùúụủũưừứựửữ]'),
      RegExp(r'[ỳýỵỷỹ]'),
      RegExp(r'[đ]')
    ];
    
    final replacements = ['a', 'e', 'i', 'o', 'u', 'y', 'd'];
    
    for (var i = 0; i < regexes.length; i++) {
      str = str.replaceAll(regexes[i], replacements[i]);
    }
    
    return str;
  }
}
