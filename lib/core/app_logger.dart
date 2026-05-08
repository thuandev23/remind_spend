import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Thin structured logger.
///
/// Levels follow dart:developer conventions:
///   INFO  (800) — transaction events: pulled, persisted
///   WARN  (900) — no regex match, retry
///   ERROR (1000) — DB write fail, bridge error, unexpected state
///
/// DEBUG logs are gated on kDebugMode and never appear in release builds.
/// IMPORTANT: never log amountVnd or raw SMS content — both are PII.
abstract final class AppLogger {
  static void debug(String tag, String message) {
    if (kDebugMode) {
      dev.log(message, name: tag, level: 500);
    }
  }

  static void info(String tag, String message) {
    dev.log(message, name: tag, level: 800);
  }

  static void warn(String tag, String message) {
    dev.log(message, name: tag, level: 900);
  }

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stack,
  }) {
    dev.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stack,
    );
  }
}
