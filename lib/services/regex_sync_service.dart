import 'dart:convert';
import '../core/app_logger.dart';
import '../db/app_db.dart';
import '../models/bank_rule.dart';
import 'bridge_service.dart';
import 'remote_config_service.dart';

class RegexSyncService {
  static const String _tag = 'RegexSyncService';

  /// Lấy toàn bộ rules hệ thống và rules cá nhân đang kích hoạt, gộp lại (ưu tiên rules cá nhân) và đẩy xuống Native.
  static Future<void> syncAllRules(AppDb db, RemoteConfigService remoteService) async {
    try {
      // 1. Lấy rules hệ thống (Remote Config / Cache / Hardcoded)
      final systemRules = await remoteService.resolve();

      // 2. Lấy rules cá nhân từ SQLite
      final customEntries = await db.getAllCustomRegexRules();
      final activeCustomRules = customEntries.where((e) => e.isActive).map((e) {
        final List<dynamic> pkgs = jsonDecode(e.packageNamesJson) as List<dynamic>;
        final List<dynamic> patts = jsonDecode(e.patternsJson) as List<dynamic>;
        
        return BankRule(
          bankId: e.bankId,
          packageNames: pkgs.cast<String>(),
          patterns: patts.cast<String>(),
          sign: e.sign,
          amountGroup: 1, // Mặc định group 1
        );
      }).toList();

      // 3. Gộp rules: Custom Rules cá nhân đứng trước để ưu tiên so khớp trước
      final unifiedRules = [...activeCustomRules, ...systemRules];

      // 4. Đồng bộ xuống native qua MethodChannel
      await BridgeService.updateRegexConfig(unifiedRules);
      AppLogger.info(_tag, 'Đã đồng bộ hợp nhất thành công ${unifiedRules.length} rules xuống native (Custom: ${activeCustomRules.length}, Hệ thống: ${systemRules.length})');
    } catch (e, st) {
      AppLogger.error(_tag, 'Lỗi khi đồng bộ hợp nhất Regex Rules xuống native', error: e, stack: st);
    }
  }
}
