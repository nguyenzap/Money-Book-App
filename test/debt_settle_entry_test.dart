import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/core/providers.dart';
import 'package:moneybook/features/debts/debt_person_screen.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late int wallet;
  late int nam;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    wallet = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        initialBalance: const Value(5000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    nam = await repo.insertPerson(
      PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
    );
  });

  tearDown(() async => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpDebtPerson(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(home: DebtPersonScreen(personId: nam)),
      ),
    );
    await settle(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('chạm khoản nợ hiện cả Tất toán khoản này và Sửa', (
    tester,
  ) async {
    await repo.addTransaction(
      kind: TxKind.lend,
      amount: 200000,
      occurredAt: DateTime(2026, 9, 10),
      walletFromId: wallet,
      personId: nam,
      note: 'Tiền ăn lẩu',
    );

    await pumpDebtPerson(tester);
    expect(find.text('Tiền ăn lẩu'), findsOneWidget);

    await tester.tap(find.text('Tiền ăn lẩu'));
    await settle(tester);

    expect(find.text('Tất toán khoản này'), findsOneWidget);
    expect(find.text('Sửa'), findsOneWidget);

    // Chọn "Tất toán khoản này" mở bảng tất toán điền sẵn khoản đó.
    await tester.tap(find.text('Tất toán khoản này'));
    await settle(tester);

    expect(find.text('Tất toán: Tiền ăn lẩu'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);

    // Xác nhận tất toán: khoản gốc thành "Đã xong", xuất hiện dòng tất toán.
    await tester.tap(find.text('Xác nhận'));
    await settle(tester);

    expect(find.text('Đã xong'), findsOneWidget);
    expect(find.textContaining('Trả cho khoản'), findsOneWidget);

    // Chạm lại vào khoản đã xong -> ẩn "Tất toán khoản này", chỉ còn "Sửa".
    await tester.tap(find.text('Tiền ăn lẩu'));
    await settle(tester);

    expect(find.text('Tất toán khoản này'), findsNothing);
    expect(find.text('Sửa'), findsOneWidget);

    await close(tester);
  });
}
