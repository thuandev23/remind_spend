import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'db/app_db.dart';
import 'repositories/transaction_repository.dart';
import 'screens/onboarding_screen.dart';
import 'screens/transaction_list_screen.dart';
import 'services/background_pull_worker.dart';
import 'services/bridge_service.dart';
import 'services/pull_service.dart';
import 'services/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDb();
  final repo = TransactionRepository(db);
  final pullService = PullService(repo)..start();

  // Fire-and-forget: resolve regex config và push xuống native
  RemoteConfigService(db).resolve();

  await Workmanager().initialize(callbackDispatcher);
  await scheduleBackgroundPull();

  runApp(MyApp(repo: repo, pullService: pullService));
}

class MyApp extends StatelessWidget {
  final TransactionRepository repo;
  final PullService pullService;

  const MyApp({super.key, required this.repo, required this.pullService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remind Spend',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display', // iOS-style, fallback sang system font
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A1A),
          brightness: Brightness.light,
        ),
      ),
      // Màn hình khởi động check permission trước khi quyết định route
      home: _StartupRouter(repo: repo, pullService: pullService),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StartupRouter
//
// Check permission một lần duy nhất khi app cold start.
// → Granted: TransactionListScreen
// → Not granted: OnboardingScreen
//
// Không block main() — check async sau khi UI đã render.
// ─────────────────────────────────────────────────────────────────────────────
class _StartupRouter extends StatefulWidget {
  final TransactionRepository repo;
  final PullService pullService;

  const _StartupRouter({required this.repo, required this.pullService});

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  // null = đang check, true = granted, false = cần onboarding
  bool? _permissionGranted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await BridgeService.checkPermissionStatus();
    final mfr = await BridgeService.getManufacturerInfo();
    
    if (!mounted) return;

    if (mfr.type == ManufacturerType.ios) {
      // iOS: check if user completed the shortcut setup onboarding.
      // SharedPreferences (NSUserDefaults) is cleared on uninstall — Keychain is not.
      final prefs = await SharedPreferences.getInstance();
      final setupDone = prefs.getBool('ios_setup_complete') ?? false;
      setState(() {
        _permissionGranted = setupDone;
      });
    } else {
      // Android: check system notification listener permission
      setState(() {
        _permissionGranted = status == PermissionStatus.granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash đơn giản trong khi check
    if (_permissionGranted == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F7F5),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remind Spend',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_permissionGranted!) {
      return TransactionListScreen(
        repo: widget.repo,
        pullService: widget.pullService,
      );
    }

    return OnboardingScreen(
      pullService: widget.pullService,
      onComplete: () => TransactionListScreen(
        repo: widget.repo,
        pullService: widget.pullService,
      ),
    );
  }
}