import 'package:flutter/widgets.dart';

import '../core/app_exception.dart';
import '../core/app_logger.dart';
import '../repositories/transaction_repository.dart';

const _tag = 'PullService';

/// Triggers a native → Drift sync whenever the app returns to foreground.
///
/// Usage:
///   final svc = PullService(repo);
///   svc.start();                // call once in main / app init
///   await svc.pull();           // call on-demand if needed
///   svc.stop();                 // call on app dispose
class PullService with WidgetsBindingObserver {
  final TransactionRepository _repo;

  bool _pulling = false;
  int _lastPullCount = 0;
  DateTime? _lastPullAt;

  int get lastPullCount => _lastPullCount;
  DateTime? get lastPullAt => _lastPullAt;

  PullService(this._repo);

  void start() {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.debug(_tag, 'Started');
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    AppLogger.debug(_tag, 'Stopped');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Fire-and-forget — errors are logged inside pull().
      pull();
    }
  }

  /// Pulls from the native queue and persists to the local DB.
  ///
  /// Concurrent calls are coalesced — if a pull is already in progress the
  /// second caller waits for it to finish and gets 0 as the return value.
  /// This prevents duplicate pulls when the app resumes rapidly.
  Future<int> pull() async {
    if (_pulling) {
      AppLogger.debug(_tag, 'Pull already in progress, skipping');
      return 0;
    }
    _pulling = true;
    try {
      final count = await _repo.syncFromNative();
      if (count > 0) {
        AppLogger.info(_tag, 'Pull complete: $count new transaction(s)');
        _lastPullCount = count;
        _lastPullAt = DateTime.now();
      }
      return count;
    } on AppException catch (e, st) {
      AppLogger.error(_tag, 'Pull failed: $e', error: e, stack: st);
      return 0;
    } finally {
      _pulling = false;
    }
  }
}
