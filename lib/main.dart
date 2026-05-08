import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'db/app_db.dart';
import 'repositories/transaction_repository.dart';
import 'services/background_pull_worker.dart';
import 'services/pull_service.dart';
import 'services/remote_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDb();
  final repo = TransactionRepository(db);
  final pullService = PullService(repo)..start();

  // Fire-and-forget: resolve regex config and push to native
  RemoteConfigService(db).resolve();

  await Workmanager().initialize(callbackDispatcher);
  await scheduleBackgroundPull();

  runApp(MyApp(pullService: pullService));
}

class MyApp extends StatelessWidget {
  final PullService pullService;

  const MyApp({super.key, required this.pullService});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Remind Spend',
      home: _PlaceholderHome(),
    );
  }
}

// Placeholder UI — Sprint 5+ will replace this with the real transaction list.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Remind Spend')),
    );
  }
}
