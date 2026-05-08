import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/core/app_logger.dart';

void main() {
  // AppLogger writes to dart:developer — no output to assert, but we verify
  // none of these calls throw in either debug or release mode.
  test('AppLogger methods complete without throwing', () {
    expect(() => AppLogger.debug('TAG', 'debug message'), returnsNormally);
    expect(() => AppLogger.info('TAG', 'info message'), returnsNormally);
    expect(() => AppLogger.warn('TAG', 'warn message'), returnsNormally);
    expect(
      () => AppLogger.error('TAG', 'error message',
          error: Exception('test'), stack: StackTrace.current),
      returnsNormally,
    );
  });

  test('AppLogger.error accepts null error and stack', () {
    expect(() => AppLogger.error('TAG', 'bare error'), returnsNormally);
  });
}
