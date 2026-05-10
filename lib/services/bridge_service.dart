import 'package:flutter/services.dart';
import '../models/bank_rule.dart';
import '../models/pending_transaction.dart';

enum PermissionStatus { granted, denied, revoked, restricted }

enum ManufacturerType { stock, miui, oneui, coloros, ios }

class ManufacturerInfo {
  final String manufacturer;
  final String model;
  final ManufacturerType type;

  const ManufacturerInfo({
    required this.manufacturer,
    required this.model,
    required this.type,
  });
}

class BridgeError implements Exception {
  final String code;
  final String message;

  const BridgeError(this.code, this.message);

  @override
  String toString() => 'BridgeError[$code]: $message';
}

class BridgeService {
  static const _channel =
      MethodChannel('com.example.remind_spend/transaction_bridge');

  static const _permissionEventChannel =
      EventChannel('com.example.remind_spend/permission_status');

  static Future<List<PendingTransaction>> getAndClearQueue() async {
    try {
      final raw = await _channel.invokeMethod<List>('getAndClearQueue');
      if (raw == null) return [];
      return raw
          .cast<Map>()
          .map((m) => PendingTransaction.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } on MissingPluginException {
      return [];
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  static Future<PermissionStatus> checkPermissionStatus() async {
    try {
      final raw = await _channel.invokeMethod<String>('checkPermissionStatus');
      return _parsePermissionStatus(raw);
    } on MissingPluginException {
      return PermissionStatus.denied;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  // Opens the system Notification Listener Settings screen.
  // Returns true if the settings screen was successfully opened.
  static Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  // Emits the current status immediately, then on every change.
  static Stream<PermissionStatus> get permissionStatusStream =>
      _permissionEventChannel.receiveBroadcastStream().map(
            (raw) => _parsePermissionStatus(raw as String?),
          );

  static Future<ManufacturerInfo> getManufacturerInfo() async {
    try {
      final raw = await _channel.invokeMethod<Map>('getManufacturerInfo');
      final map = Map<String, dynamic>.from(raw ?? {});
      final type = switch (map['type'] as String? ?? 'stock') {
        'miui'    => ManufacturerType.miui,
        'oneui'   => ManufacturerType.oneui,
        'coloros' => ManufacturerType.coloros,
        'ios'     => ManufacturerType.ios,
        _         => ManufacturerType.stock,
      };
      return ManufacturerInfo(
        manufacturer: map['manufacturer'] as String? ?? '',
        model: map['model'] as String? ?? '',
        type: type,
      );
    } on MissingPluginException {
      return const ManufacturerInfo(
        manufacturer: 'Unknown',
        model: 'Unknown',
        type: ManufacturerType.stock,
      );
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  // Returns true if the app is already whitelisted from battery optimization.
  // On non-Android platforms, always returns true.
  static Future<bool> checkBatteryOptimization() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('checkBatteryOptimization');
      return result ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  // Opens the system battery optimization whitelist dialog.
  // No-op on non-Android platforms.
  static Future<void> requestBatteryOptimizationWhitelist() async {
    try {
      await _channel.invokeMethod<void>('requestBatteryOptimizationWhitelist');
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  static Future<void> updateRegexConfig(List<BankRule> rules) async {
    try {
      final payload = rules.map((r) => r.toJson()).toList();
      await _channel.invokeMethod<void>('updateRegexConfig', payload);
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  static Future<void> clearIdempotencyCache() async {
    try {
      await _channel.invokeMethod<void>('clearIdempotencyCache');
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  static Future<void> mockTransaction() async {
    try {
      await _channel.invokeMethod<void>('mockTransaction');
    } on MissingPluginException {
      return;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  // Android 13+: requests POST_NOTIFICATIONS runtime permission.
  // Returns true if granted (or not required), false if denied.
  static Future<bool> requestPostNotificationsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPostNotificationsPermission');
      return result ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  // iOS only: requests UNUserNotificationCenter authorization.
  // Returns true if granted, false if denied.
  static Future<bool> requestLocalNotificationPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestLocalNotificationPermission');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  // iOS only: chạy smsText qua BankRegexParser → idempotency key → KeychainQueue.
  // Mirrors LogTransactionIntent.perform() — dùng để test thay cho ADB broadcast.
  // Returns false nếu SMS không match pattern nào.
  static Future<bool> simulateBankNotification(String smsText) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'simulateBankNotification',
        smsText,
      );
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      throw BridgeError(e.code, e.message ?? 'Unknown error');
    }
  }

  static PermissionStatus _parsePermissionStatus(String? raw) =>
      switch (raw) {
        'granted'        => PermissionStatus.granted,
        'revoked'        => PermissionStatus.revoked,
        'restricted'     => PermissionStatus.restricted,
        'not_applicable' => PermissionStatus.restricted, // iOS: App Intents always available
        _                => PermissionStatus.denied,
      };
}
