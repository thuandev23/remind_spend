import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../db/app_db.dart';
import '../repositories/transaction_repository.dart';
import 'pull_service.dart';
import 'remote_config_service.dart';

const _kBgPullTaskName = 'bgPull';
const kBgPullTaskUnique = 'com.example.remind_spend.bgPull';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (taskName == _kBgPullTaskName) {
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

Future<void> scheduleBackgroundPull() => Workmanager().registerPeriodicTask(
      kBgPullTaskUnique,
      _kBgPullTaskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
