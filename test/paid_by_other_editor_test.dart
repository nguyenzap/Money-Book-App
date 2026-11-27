import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/providers.dart';
import 'package:moneybook/features/transactions/tx_editor_screen.dart';

/// Chạy thật màn Ghi nợ (người khác trả dùm): tiêu đề "Ghi nợ", ẩn chọn loại
/// và ví, chọn danh mục và người, bấm Ghi. Khoản chi phải không có ví, có
/// người, và mình nợ người đó.
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

  Future<void> openEditor(
    WidgetTester tester, {
    TxView? editing,
    bool initialPaidByOther = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openTxEditor(
                  context,
                  editing: editing,
                  initialPaidByOther: initialPaidByOther,
                ),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở'));
    await settle(tester);
  }

  testWidgets('Ghi nợ: không trừ ví, ẩn chọn loại, mình nợ người đó', (
    tester,
  ) async {
    final nam = (await tester.runAsync(
      () => repo.insertPerson(
        PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
      ),
    ))!;

    await openEditor(tester, initialPaidByOther: true);

    expect(find.text('Ghi nợ'), findsOneWidget);
    expect(find.text('Thu nhập'), findsNothing, reason: 'ẩn thanh chọn loại');
    expect(
      find.text('Trừ vào ví'),
      findsNothing,
      reason: 'người khác trả thì không có ví nào bị trừ',
    );
    expect(
      find.text('Trả dùm'),
      findsNothing,
      reason: 'người khác trả thì không chia tiền',
    );

    await tester.enterText(find.widgetWithText(TextField, 'Số tiền'), '50000');
    await tester.pumpAndSettle();
    await tapText(tester, 'Ăn uống');
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

    // Mở sửa lại khoản Ghi nợ: vẫn giữ tiêu đề "Ghi nợ", ẩn chọn loại và ví.
    await openEditor(tester, editing: view);
    expect(find.text('Ghi nợ'), findsOneWidget);
    expect(find.text('Thu nhập'), findsNothing);
    expect(find.text('Trừ vào ví'), findsNothing);
    expect(find.text('Nam'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('màn ghi chi tiêu thường không có công tắc Người khác trả dùm', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: TxEditorScreen(presetWalletId: 1)),
      ),
    );
    await settle(tester);

    expect(find.text('Ghi giao dịch'), findsOneWidget);
    expect(find.text('Trừ vào ví'), findsOneWidget);
    expect(find.text('Người khác trả dùm'), findsNothing);
    await tester.scrollUntilVisible(
      find.widgetWithText(SwitchListTile, 'Trả dùm'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.widgetWithText(SwitchListTile, 'Hoá đơn'), findsOneWidget);
    expect(find.widgetWithText(SwitchListTile, 'Trả dùm'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
