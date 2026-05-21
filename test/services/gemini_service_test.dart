import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:remind_spend/services/gemini_service.dart';

void main() {
  const MethodChannel secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> mockSecureStorage = {};

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Mock FlutterSecureStorage Platform Channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (MethodCall methodCall) async {
      final String method = methodCall.method;
      if (method == 'read') {
        final key = methodCall.arguments['key'] as String;
        return mockSecureStorage[key];
      } else if (method == 'write') {
        final key = methodCall.arguments['key'] as String;
        final value = methodCall.arguments['value'] as String;
        mockSecureStorage[key] = value;
        return null;
      } else if (method == 'delete') {
        final key = methodCall.arguments['key'] as String;
        mockSecureStorage.remove(key);
        return null;
      } else if (method == 'clear') {
        mockSecureStorage.clear();
        return null;
      } else if (method == 'readAll') {
        return mockSecureStorage;
      }
      return null;
    });
  });

  setUp(() {
    mockSecureStorage.clear();
    SharedPreferences.setMockInitialValues({});
  });

  group('GeminiService Tests', () {
    test('1. Bật/Tắt AI Auto-Categorization qua SharedPreferences', () async {
      // Mặc định phải là true khi chưa cấu hình gì
      expect(await GeminiService.isAiEnabled(), isTrue);

      // Set thành false và kiểm tra
      await GeminiService.setAiEnabled(false);
      expect(await GeminiService.isAiEnabled(), isFalse);

      // Set lại thành true và kiểm tra
      await GeminiService.setAiEnabled(true);
      expect(await GeminiService.isAiEnabled(), isTrue);
    });

    test('2. Đọc, ghi và xóa Gemini API Key bảo mật', () async {
      // Lúc đầu chưa có gì, getApiKey trả về null (hoặc env fallback nếu có chạy ở local)
      final initialKey = await GeminiService.getApiKey();
      expect(initialKey == null || initialKey.isEmpty, isTrue);
      
      // Ghi API Key mới
      const testKey = 'AIzaSyTestApiKey123456';
      await GeminiService.saveApiKey(testKey);

      // Đọc lại để kiểm tra xem khớp không
      final savedKey = await GeminiService.getApiKey();
      expect(savedKey, equals(testKey));

      // Xóa API Key
      await GeminiService.deleteApiKey();

      // Kiểm tra xem đã bị xóa chưa
      final deletedKey = await GeminiService.getApiKey();
      expect(deletedKey, isNot(equals(testKey)));
    });

    test('3. classifyWithAi lập tức trả về others khi AI bị tắt', () async {
      // Lưu API Key trước
      await GeminiService.saveApiKey('AIzaSyDummyKey');
      // Tắt AI
      await GeminiService.setAiEnabled(false);

      final category = await GeminiService.classifyWithAi('Thanh toan Grab 50k', 'debit');
      expect(category, equals('others'));
    });

    test('4. classifyWithAi lập tức trả về others khi API Key trống', () async {
      // Xóa API Key (nếu có)
      await GeminiService.deleteApiKey();
      // Bật AI
      await GeminiService.setAiEnabled(true);

      // Ta mock môi trường trống bằng cách clear mock storage
      mockSecureStorage.clear();

      final category = await GeminiService.classifyWithAi('Thanh toan Grab 50k', 'debit');
      expect(category, equals('others'));
    });

    test('5. classifyWithAi xử lý ngoại lệ an toàn khi API Key không hợp lệ hoặc lỗi kết nối', () async {
      // Lưu API Key giả nhưng không kết nối được
      await GeminiService.saveApiKey('invalid_key_for_test');
      await GeminiService.setAiEnabled(true);

      // Sẽ ném ra Exception khi GenerativeModel cố gắng connect, 
      // nhưng hàm classifyWithAi phải bắt được lỗi và trả về 'others' thay vì crash app.
      final category = await GeminiService.classifyWithAi('GD -50,000 VND tai Grab', 'debit');
      expect(category, equals('others'));
    });

    test('6. testConnection trả về false với API key trống hoặc sai định dạng', () async {
      final successEmpty = await GeminiService.testConnection('');
      expect(successEmpty, isFalse);

      final successInvalid = await GeminiService.testConnection('invalid_key_test');
      expect(successInvalid, isFalse);
    });
  });
}
