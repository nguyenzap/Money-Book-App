import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/providers.dart';
import 'package:moneybook/features/transactions/tx_editor_screen.dart';

/// Chạy thật màn ghi chi tiêu: bật hoá đơn, gõ từng món, bấm Ghi, rồi mở lại
/// khoản đó phải thấy đúng hoá đơn.
void main() {
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
  });

  tearDown(() async => db.close());

  Future<void> open(WidgetTester tester, {TxView? editing}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: TxEditorScreen(presetWalletId: 1, editing: editing),
        ),
      ),
    );
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
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

  Future<void> type(
    WidgetTester tester,
    String label,
    String text, {
    int index = 0,
  }) async {
    final finder = find.widgetWithText(TextField, label).at(index);
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  testWidgets('ghi chi tiêu kèm hoá đơn rồi mở lại thấy đúng hoá đơn', (
    tester,
  ) async {
    await open(tester);

    await tapText(tester, 'Ăn uống');
    await tapText(tester, 'Hoá đơn chi tiết');
    expect(
      find.text('Số tiền'),
      findsNothing,
      reason: 'có hoá đơn thì số tiền là tổng hoá đơn',
    );

    await type(tester, 'Tên món', 'Sữa');
    await type(tester, 'SL', '2');
    await type(tester, 'Đơn giá', '30000');
    await tapText(tester, 'Thêm món');
    await type(tester, 'Tên món', 'Bánh mì', index: 1);
    await type(tester, 'Đơn giá', '50000', index: 1);
    await tapText(tester, 'Giảm giá');
    await type(tester, 'Số tiền giảm', '10000');

    expect(find.text('100.000 ₫'), findsOneWidget);

    await tester.tap(find.text('Ghi lại'));
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    final view = await tester.runAsync(
      () async => (await repo.watchTransactions().first).single,
    );
    expect(view!.tx.amount, 100000);
    expect(view.billCount, 3);
    await close(tester);

    await open(tester, editing: view);
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sữa'), findsOneWidget);
    expect(find.text('Bánh mì'), findsOneWidget);
    expect(find.text('60.000 ₫'), findsOneWidget, reason: '2 × 30.000');
    expect(find.text('-10.000 ₫'), findsOneWidget);
    expect(find.text('100.000 ₫'), findsOneWidget);
    await close(tester);
  });
}
