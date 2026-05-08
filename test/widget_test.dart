import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/db/app_db.dart';
import 'package:remind_spend/main.dart';
import 'package:remind_spend/repositories/transaction_repository.dart';
import 'package:remind_spend/services/pull_service.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final repo = TransactionRepository(db);
    final svc = PullService(repo);

    await tester.pumpWidget(MyApp(repo: repo, pullService: svc));
    await tester.pump();

    // Splash hoặc loading indicator hiển thị trong khi check permission
    expect(find.byType(MyApp), findsOneWidget);

    await db.close();
  });
}
