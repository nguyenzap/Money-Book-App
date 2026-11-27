import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/running_balance.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/core/providers.dart';
import 'package:moneybook/features/transactions/tx_list_screen.dart';

Transaction _tx({
  required int id,
  required int amount,
  required int occurredAt,
  TxKind kind = TxKind.expense,
  int? walletFromId,
  int? walletToId,
  int? personId,
  bool isWriteoff = false,
  int? deletedAt,
}) {
  return Transaction(
    id: id,
    kind: kind,
    amount: amount,
    occurredAt: occurredAt,
    dayKey: 20260915,
    monthKey: 202609,
    walletFromId: walletFromId,
    walletToId: walletToId,
    personId: personId,
    debtDelta: 0,
    fundDelta: 0,
    isWriteoff: isWriteoff,
    needsReview: false,
    createdAt: occurredAt,
    updatedAt: occurredAt,
    deletedAt: deletedAt,
  );
}

void main() {
  group('runningBalances (thuần Dart)', () {
    test('chuyển ví cập nhật cả hai ví theo đúng thứ tự ví đi -> ví đến', () {
      const cash = 1;
      const bidv = 2;
      final txs = [
        _tx(
          id: 1,
          kind: TxKind.transfer,
          amount: 200000,
          occurredAt: 1000,
          walletFromId: cash,
          walletToId: bidv,
        ),
      ];

      final res = runningBalances(txs, {cash: 500000, bidv: 1050000});

      expect(res[1], {cash: 300000, bidv: 1250000});
      expect(res[1]!.keys.toList(), [cash, bidv]);
    });

    test('cùng thời điểm thì sắp theo id tăng dần bất kể thứ tự đầu vào', () {
      const w = 1;
      // Đầu vào cố tình đảo ngược giống thứ tự watchTransactions (DESC).
      final txs = [
        _tx(
          id: 30,
          kind: TxKind.expense,
          amount: 100000,
          occurredAt: 5000,
          walletFromId: w,
        ),
        _tx(
          id: 10,
          kind: TxKind.income,
          amount: 500000,
          occurredAt: 5000,
          walletToId: w,
        ),
        _tx(
          id: 20,
          kind: TxKind.expense,
          amount: 50000,
          occurredAt: 5000,
          walletFromId: w,
        ),
      ];

      final res = runningBalances(txs, {w: 1000000});

      // id 10: 1.000.000 + 500.000 = 1.500.000
      // id 20: 1.500.000 -  50.000 = 1.450.000
      // id 30: 1.450.000 - 100.000 = 1.350.000
      expect(res[10], {w: 1500000});
      expect(res[20], {w: 1450000});
      expect(res[30], {w: 1350000});
    });

    test('bỏ qua giao dịch đã xoá mềm', () {
      const w = 1;
      final txs = [
        _tx(id: 1, amount: 100000, occurredAt: 1000, walletFromId: w),
        _tx(
          id: 2,
          amount: 999000,
          occurredAt: 2000,
          walletFromId: w,
          deletedAt: 2500,
        ),
        _tx(id: 3, amount: 50000, occurredAt: 3000, walletFromId: w),
      ];

      final res = runningBalances(txs, {w: 500000});

      expect(res.containsKey(2), isFalse);
      expect(res[1], {w: 400000});
      expect(res[3], {w: 350000});
    });

    test('khoản chi không có chân ví và xoá nợ không làm đổi số dư ví nào', () {
      const w = 1;
      final txs = [
        _tx(id: 1, amount: 100000, occurredAt: 1000, walletFromId: w),
        // Người khác trả dùm: không có walletFromId lẫn walletToId.
        _tx(
          id: 2,
          kind: TxKind.expense,
          amount: 250000,
          occurredAt: 2000,
          personId: 9,
        ),
        // Xoá nợ: không có chân ví.
        _tx(
          id: 3,
          kind: TxKind.repay,
          amount: 250000,
          occurredAt: 3000,
          personId: 9,
          isWriteoff: true,
        ),
        _tx(id: 4, amount: 50000, occurredAt: 4000, walletFromId: w),
      ];

      final res = runningBalances(txs, {w: 500000});

      expect(res[1], {w: 400000});
      expect(res[2], isEmpty);
      expect(res[3], isEmpty);
      expect(res[4], {w: 350000});
    });

    test('chuyển trong cùng một ví (nạp/rút quỹ) giữ nguyên số dư và ghi 1 lần', () {
      const w = 1;
      final txs = [
        _tx(
          id: 1,
          kind: TxKind.transfer,
          amount: 300000,
          occurredAt: 1000,
          walletFromId: w,
          walletToId: w,
        ),
      ];

      final res = runningBalances(txs, {w: 1000000});

      expect(res[1], {w: 1000000});
      expect(res[1]!.length, 1);
    });
  });

  group('khớp với Repository.balanceOf trên DB thật', () {
    late AppDatabase db;
    late Repository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = Repository(db);
      await db.customStatement('PRAGMA foreign_keys = ON');
    });

    tearDown(() async => db.close());

    Future<int> newWallet(String name, int initial) {
      return repo.insertWallet(
        WalletsCompanion.insert(
          name: name,
          initialBalance: Value(initial),
          createdAt: 0,
          updatedAt: 0,
        ),
      );
    }

    Future<int> newCategory(String name, CategoryFlow flow) {
      return repo.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          flow: flow,
          createdAt: 0,
          updatedAt: 0,
        ),
      );
    }

    test('số dư chạy cuối cùng của mọi ví (kể cả đã lưu trữ) bằng balanceOf', () async {
      final cash = await newWallet('Tiền mặt', 500000);
      final bidv = await newWallet('BIDV', 1000000);
      final archived = await newWallet('Ví cũ', 300000);
      final catExp = await newCategory('Ăn uống', CategoryFlow.expense);
      final catInc = await newCategory('Lương', CategoryFlow.income);
      final nam = await repo.insertPerson(
        PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
      );

      final t1 = DateTime(2026, 9, 10, 9, 0);
      final t2 = DateTime(2026, 9, 10, 12, 0);
      final t3 = DateTime(2026, 9, 11, 18, 30);

      // Thu nhập vào BIDV
      await repo.addTransaction(
        kind: TxKind.income,
        amount: 2000000,
        occurredAt: t1,
        walletToId: bidv,
        categoryId: catInc,
      );
      // Hai giao dịch cùng timestamp t2
      final sameA = await repo.addTransaction(
        kind: TxKind.transfer,
        amount: 400000,
        occurredAt: t2,
        walletFromId: bidv,
        walletToId: cash,
      );
      final sameB = await repo.addTransaction(
        kind: TxKind.expense,
        amount: 150000,
        occurredAt: t2,
        walletFromId: cash,
        categoryId: catExp,
      );
      // Giao dịch bị xoá mềm
      final deletedId = await repo.addTransaction(
        kind: TxKind.expense,
        amount: 777000,
        occurredAt: t2,
        walletFromId: bidv,
        categoryId: catExp,
      );
      await repo.softDeleteTransaction(deletedId);
      // Khoản chi người khác trả dùm (không có ví)
      final paidByOtherId = await repo.addTransaction(
        kind: TxKind.expense,
        amount: 80000,
        occurredAt: t3,
        personId: nam,
        categoryId: catExp,
      );
      // Giao dịch trên ví sau đó lưu trữ
      final archivedTxId = await repo.addTransaction(
        kind: TxKind.expense,
        amount: 120000,
        occurredAt: t3,
        walletFromId: archived,
        categoryId: catExp,
      );
      await repo.archiveWallet(archived, archived: true);

      // Lấy cả dòng đã xoá trực tiếp từ DB để kiểm tra runningBalances tự lọc.
      final allRows = await db.select(db.transactions).get();
      final wallets =
          await repo.watchWalletsWithBalance(includeArchived: true).first;
      final initial = {for (final w in wallets) w.id: w.wallet.initialBalance};

      final running = runningBalances(allRows, initial);

      expect(running.containsKey(deletedId), isFalse);
      expect(running[paidByOtherId], isEmpty);
      expect(running[sameA], {bidv: 2600000, cash: 900000});
      expect(running[sameB], {cash: 750000});
      expect(running[archivedTxId], {archived: 180000});

      // Số dư cuối cùng của mỗi ví trong runningBalances phải khớp balanceOf.
      expect(running[sameA]![bidv], await repo.balanceOf(bidv));
      expect(running[sameB]![cash], await repo.balanceOf(cash));
      expect(running[archivedTxId]![archived], await repo.balanceOf(archived));
    });

    testWidgets('TxListScreen hiện số dư chạy, còn GroupedTxList mặc định không hiện', (
      tester,
    ) async {
      final cash = await newWallet('Tiền mặt', 500000);
      final bidv = await newWallet('BIDV', 1050000);
      final catExp = await newCategory('Ăn uống', CategoryFlow.expense);
      final nam = await repo.insertPerson(
        PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
      );

      final t1 = DateTime(2026, 9, 10, 9, 0);
      final t2 = DateTime(2026, 9, 10, 12, 0);
      final t3 = DateTime(2026, 9, 10, 18, 0);

      await repo.addTransaction(
        kind: TxKind.transfer,
        amount: 200000,
        occurredAt: t1,
        walletFromId: cash,
        walletToId: bidv,
        note: 'Nạp BIDV',
      );
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: t2,
        walletFromId: bidv,
        categoryId: catExp,
        note: 'Cà phê',
      );
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 70000,
        occurredAt: t3,
        personId: nam,
        categoryId: catExp,
        note: 'Nam trả dùm',
      );
      await repo.addTransaction(
        kind: TxKind.borrow,
        amount: 100000,
        occurredAt: t3,
        walletToId: cash,
        personId: nam,
        note: 'Vay Nam',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbProvider.overrideWithValue(db)],
          child: const MaterialApp(home: TxListScreen()),
        ),
      );
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      // Transfer: hiện cả hai ví theo thứ tự ví đi → ví đến, không tên ví.
      expect(find.text('Số dư 300.000 ₫ → 1.250.000 ₫'), findsOneWidget);
      // Chi tiêu từ BIDV: hiện số dư BIDV sau giao dịch.
      expect(find.text('Số dư 1.200.000 ₫'), findsOneWidget);
      // Giao dịch nợ 3 dòng ở trailing (số tiền + nhãn nợ + số dư) không tràn.
      expect(find.text(TxKind.borrow.label), findsOneWidget);
      expect(find.text('Số dư 400.000 ₫'), findsOneWidget);
      // Người khác trả dùm: không hiện thêm dòng số dư.
      expect(find.text('Nam trả dùm'), findsOneWidget);

      // GroupedTxList dùng ở màn khác (không truyền runningBalances) không hiện dòng số dư.
      final views = await tester.runAsync(() => repo.watchTransactions().first);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GroupedTxList(views: views!)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Số dư 300.000 ₫ → 1.250.000 ₫'), findsNothing);
      expect(find.text('Số dư 1.200.000 ₫'), findsNothing);
      expect(find.text('Số dư 400.000 ₫'), findsNothing);
    });
  });
}
