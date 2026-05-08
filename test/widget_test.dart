import 'package:flutter_test/flutter_test.dart';
import 'package:remind_spend/main.dart';
import 'package:remind_spend/services/pull_service.dart';
import 'package:remind_spend/repositories/transaction_repository.dart';
import 'package:drift/native.dart';
import 'package:remind_spend/db/app_db.dart';

void main() {
  testWidgets('App renders placeholder home without crashing',
      (WidgetTester tester) async {
    final db = AppDb.forTesting(NativeDatabase.memory());
    final repo = TransactionRepository(db);
    final svc = PullService(repo);

    await tester.pumpWidget(MyApp(pullService: svc));

    expect(find.text('Remind Spend'), findsOneWidget);

    await db.close();
  });
}
