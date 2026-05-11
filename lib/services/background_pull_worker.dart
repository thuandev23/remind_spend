import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../db/app_db.dart';
import '../repositories/transaction_repository.dart';
import 'pull_service.dart';
import 'remote_config_service.dart';

const _kBgPullTaskName    = 'bgPull';
const _kBgRefreshTaskName = 'bgRefresh';
const kBgPullTaskUnique    = 'com.example.remind_spend.bgPull';
const kBgRefreshTaskUnique = 'com.example.remind_spend.bgRefresh';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName == _kBgPullTaskName || taskName == _kBgRefreshTaskName) {
      final db = AppDb();
      try {
        await RemoteConfigService(db).resolve();
        await PullService(TransactionRepository(db)).pull();
      } finally {
        await db.close();
      }
    }
    return true;
  });
}

Future<void> scheduleBackgroundPull() async {
  // BGProcessingTask (Android + iOS): heavier work, requires charging + network.
  // Runs ~hourly on Android; iOS decides when to run (typically overnight).
  await Workmanager().registerPeriodicTask(
    kBgPullTaskUnique,
    _kBgPullTaskName,
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
  // BGAppRefreshTask (iOS only): lightweight, runs more frequently (~15 min min).
  // Ignored on Android — workmanager silently skips unknown task types.
  await Workmanager().registerOneOffTask(
    kBgRefreshTaskUnique,
    _kBgRefreshTaskName,
    initialDelay: const Duration(minutes: 15),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}
