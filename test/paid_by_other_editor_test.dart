import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/providers.dart';
import 'package:moneybook/features/transactions/tx_editor_screen.dart';

/// Chạy thật màn ghi chi tiêu: bật "Người khác trả dùm", chọn người, bấm Ghi.
/// Khoản chi phải không có ví, có người, và mình nợ người đó.
void main() {
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
  });

  tearDown(() async => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('người khác trả dùm: không trừ ví, mình nợ người đó', (
    tester,
  ) async {
    final nam = (await tester.runAsync(
      () => repo.insertPerson(
        PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
      ),
    ))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TxEditorScreen(presetWalletId: 1)),
      ),
    );
    await settle(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Số tiền'), '50000');
    await tester.pumpAndSettle();
    expect(find.text('Trừ vào ví'), findsOneWidget);
    await tapText(tester, 'Ăn uống');

    await tapText(tester, 'Người khác trả dùm');
    await tester.scrollUntilVisible(
      find.text('Số tiền'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Trừ vào ví'),
      findsNothing,
      reason: 'người khác trả thì không có ví nào bị trừ',
    );
    await tester.scrollUntilVisible(
      find.text('Người khác trả dùm'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Trả dùm, chia tiền với người khác'),
      findsNothing,
      reason: 'người khác trả thì không chia tiền',
    );

    // Đẩy hẳn danh sách lên để chip người không nằm sát mép dưới.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tapText(tester, 'Nam');
    await tester.tap(find.text('Ghi lại'));
    await settle(tester);

    final view = (await tester.runAsync(
      () async => (await repo.watchTransactions().first).single,
    ))!;
    expect(view.isPaidByOther, isTrue);
    expect(view.tx.walletFromId, isNull);
    expect(view.tx.personId, nam);
    expect(view.tx.amount, 50000);
    expect(await tester.runAsync(() => repo.netDebtOf(nam)), -50000);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
