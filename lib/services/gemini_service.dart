import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_logger.dart';
import 'bridge_service.dart';

const _tag = 'GeminiService';
const _apiKeyStorageKey = 'gemini_api_key';
const _aiEnabledPrefsKey = 'ai_enabled';

class GeminiService {
  static const _storage = FlutterSecureStorage();

  // Danh mục được hỗ trợ trong hệ thống
  static const List<String> supportedCategories = [
    'food',
    'transport',
    'shopping',
    'bills',
    'entertainment',
    'income',
    'others'
  ];

  /// Lấy API Key đã lưu trong Secure Storage hoặc từ biến môi trường làm fallback
  static Future<String?> getApiKey() async {
    try {
      // 1. Thử đọc từ Secure Storage (ưu tiên cao nhất - do người dùng tự nhập)
      final savedKey = await _storage.read(key: _apiKeyStorageKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        return savedKey.trim();
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'Lỗi đọc API Key từ secure storage', error: e, stack: st);
    }

    // 2. Thử đọc từ biến môi trường (phục vụ test/debug/development)
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) {
      return envKey;
    }

    // 3. Fallback sang biến môi trường của OS (chạy test local offline/online)
    try {
      final osEnvKey = Platform.environment['GEMINI_API_KEY'];
      if (osEnvKey != null && osEnvKey.trim().isNotEmpty) {
        return osEnvKey.trim();
      }
    } catch (_) {}

    return null;
  }

  /// Lưu API Key vào Secure Storage một cách an toàn
  static Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyStorageKey, value: apiKey.trim());
    AppLogger.info(_tag, 'Đã lưu Gemini API Key an toàn');
  }

  /// Xóa API Key khỏi Secure Storage
  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyStorageKey);
    AppLogger.info(_tag, 'Đã xóa Gemini API Key');
  }

  /// Kiểm tra xem tính năng AI Auto-Categorization có được bật không
  static Future<bool> isAiEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Mặc định là bật nếu người dùng đã lưu API Key
    final enabled = prefs.getBool(_aiEnabledPrefsKey) ?? true;
    return enabled;
  }

  /// Cấu hình bật/tắt tính năng AI
  static Future<void> setAiEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledPrefsKey, enabled);
    AppLogger.info(_tag, 'Cấu hình AI Auto-Categorization: $enabled');
  }

  /// Kiểm tra tính hợp lệ của API Key bằng cách gọi thử một request đơn giản
  static Future<bool> testConnection(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey.trim(),
      );
      final response = await model.generateContent([
        Content.text('Trả về từ khóa "OK" nếu bạn nhận được tin nhắn này.')
      ]);
      final text = response.text?.trim() ?? '';
      AppLogger.info(_tag, 'Test connection thành công: $text');
      return text.toUpperCase().contains('OK');
    } catch (e, st) {
      await _handleLeakedKey(e);
      AppLogger.error(_tag, 'Test connection thất bại', error: e, stack: st);
      return false;
    }
  }

  /// Tự động vô hiệu hoá và cảnh báo người dùng khi API Key bị Google/Gemini Server báo rò rỉ (leaked)
  static Future<void> _handleLeakedKey(dynamic error) async {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('leaked')) {
      AppLogger.error(_tag, '⚠️ PHÁT HIỆN GEMINI API KEY BỊ RÒ RỈ! Tự động vô hiệu hoá để bảo mật.');
      
      // 1. Tắt cờ bật AI để tránh gửi request vô ích
      await setAiEnabled(false);
      
      // 2. Xoá API Key bị lộ khỏi secure storage bảo mật dòng tiền
      await deleteApiKey();
      
      // 3. Gửi thông báo đẩy cục bộ khẩn cấp cho người dùng
      await BridgeService.sendLocalNotification(
        '🔒 Cảnh báo bảo mật API Key!',
        'Gemini API Key của bạn đã bị lộ (leaked). Hệ thống đã tự động vô hiệu hoá tính năng AI để bảo mật. Vui lòng cấu hình API Key mới.',
      );
    }
  }

  /// Gọi Gemini API để phân tích ngữ nghĩa tin nhắn và tự động gán danh mục
  static Future<String> classifyWithAi(String content, String sign) async {
    final enabled = await isAiEnabled();
    if (!enabled) {
      AppLogger.debug(_tag, 'AI Auto-Categorization bị tắt trong cài đặt');
      return 'others';
    }

    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      AppLogger.debug(_tag, 'Không có Gemini API Key, bỏ qua phân loại bằng AI');
      return 'others';
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1, // Nhiệt độ thấp để AI trả về kết quả nhất quán
        ),
      );

      final prompt = 'Phân loại tin nhắn giao dịch ngân hàng sau đây vào một trong các danh mục được hỗ trợ:\n'
          '1. food: Ăn uống, cà phê, nhà hàng, siêu thị mua thực phẩm, shopeefood, grabfood, trà sữa...\n'
          '2. transport: Di chuyển, taxi, grab/be/gojek (không phải giao thức ăn), xăng dầu, vé máy bay, vé tàu xe...\n'
          '3. shopping: Mua sắm quần áo, đồ điện tử, đồ gia dụng, mua hàng shopee, lazada, tiki...\n'
          '4. bills: Hóa đơn điện, nước, internet, cước điện thoại di động, đóng học phí, phí dịch vụ chung cư, bảo hiểm...\n'
          '5. entertainment: Giải trí, vé xem phim CGV, dịch vụ trả phí netflix, spotify, nạp game, concert, karaoke, quán bar...\n'
          '6. income: Nhận tiền, chuyển khoản đến, lương, thưởng, thu nhập...\n'
          '7. others: Các giao dịch khác không thể phân loại rõ ràng vào các mục trên.\n\n'
          'Tin nhắn giao dịch: "$content"\n'
          'Dấu giao dịch (sign): "${sign == 'credit' ? 'Cộng tiền vào tài khoản (income)' : 'Trừ tiền khỏi tài khoản (expense)'}"\n\n'
          'YÊU CẦU NGHIÊM NGẶT:\n'
          '- Chỉ trả về DUY NHẤT một trong các mã danh mục sau ở dạng chữ thường viết liền: food, transport, shopping, bills, entertainment, income, others.\n'
          '- Tuyệt đối không thêm bất kỳ văn bản giải thích nào khác, không có dấu chấm, không xuống dòng.';

      AppLogger.debug(_tag, 'Đang gửi tin nhắn phân tích tới Gemini: "$content"');
      
      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text?.trim().toLowerCase() ?? 'others';

      AppLogger.info(_tag, 'Kết quả phân tích từ AI cho "$content" là: "$result"');

      if (supportedCategories.contains(result)) {
        return result;
      } else {
        AppLogger.warn(_tag, 'AI trả về danh mục lạ: "$result". Tự động fallback sang "others".');
        return 'others';
      }
    } catch (e, st) {
      // Xử lý nếu API Key bị rò rỉ
      await _handleLeakedKey(e);
      // Bọc an toàn để không crash app khi mất mạng hoặc API Key hết hạn
      AppLogger.error(_tag, 'Lỗi phân loại bằng Gemini API', error: e, stack: st);
      return 'others';
    }
  }
}
