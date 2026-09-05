import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late int wallet;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    await db.customStatement('PRAGMA foreign_keys = ON');
    wallet = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        initialBalance: const Value(10000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  });

  tearDown(() async => db.close());

  Future<int> newPerson(String name) => repo.insertPerson(
        PeopleCompanion.insert(name: name, createdAt: 0, updatedAt: 0),
      );

  Future<void> lend(int person, int amount) => repo.addTransaction(
        kind: TxKind.lend,
        amount: amount,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        personId: person,
      );

  Future<void> collect(int person, int amount) => repo.addTransaction(
        kind: TxKind.collect,
        amount: amount,
        occurredAt: DateTime.now(),
        walletToId: wallet,
        personId: person,
      );

  Future<void> borrow(int person, int amount) => repo.addTransaction(
        kind: TxKind.borrow,
        amount: amount,
        occurredAt: DateTime.now(),
        walletToId: wallet,
        personId: person,
      );

  Future<void> repay(int person, int amount) => repo.addTransaction(
        kind: TxKind.repay,
        amount: amount,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        personId: person,
      );

  group('công nợ một người', () {
    test('cho mượn thì họ nợ mình', () async {
      final nam = await newPerson('Nam');
      await lend(nam, 200000);
      expect(await repo.netDebtOf(nam), 200000);

      final debts = await repo.watchDebts().first;
      expect(debts, hasLength(1));
      expect(debts.first.theyOweMe, isTrue);
      expect(debts.first.absAmount, 200000);
    });

    test('vay thì mình nợ họ', () async {
      final hung = await newPerson('Hùng');
      await borrow(hung, 1000000);
      expect(await repo.netDebtOf(hung), -1000000);

      final debts = await repo.watchDebts().first;
      expect(debts.first.iOweThem, isTrue);
      expect(debts.first.absAmount, 1000000);
    });

    test('vay 1tr rồi trả 400k thì còn nợ 600k', () async {
      final hung = await newPerson('Hùng');
      await borrow(hung, 1000000);
      await repay(hung, 400000);
      expect(await repo.netDebtOf(hung), -600000);
    });

    test('cho mượn rồi thu đủ thì sạch nợ', () async {
      final nam = await newPerson('Nam');
      await lend(nam, 200000);
      await collect(nam, 200000);
      expect(await repo.netDebtOf(nam), 0);

      // Mặc định người đã sạch nợ không hiện trong sổ nợ nữa.
      expect(await repo.watchDebts().first, isEmpty);
      expect(await repo.watchDebts(includeSettled: true).first, hasLength(1));
    });

    test('vừa vay vừa cho mượn cùng một người thì bù trừ', () async {
      final nam = await newPerson('Nam');
      await borrow(nam, 1000000);
      await lend(nam, 200000);
      expect(await repo.netDebtOf(nam), -800000,
          reason: 'còn nợ Nam 800k');
    });

    test('cho mượn nhiều lần thì cộng dồn', () async {
      final nam = await newPerson('Nam');
      await lend(nam, 100000);
      await lend(nam, 250000);
      await lend(nam, 50000);
      expect(await repo.netDebtOf(nam), 400000);
    });
  });

  group('công nợ nhiều người', () {
    test('mỗi người một sổ riêng, không lẫn vào nhau', () async {
      final nam = await newPerson('Nam');
      final hung = await newPerson('Hùng');
      final lan = await newPerson('Lan');

      await lend(nam, 200000);
      await borrow(hung, 1000000);
      await lend(lan, 50000);
      await collect(lan, 50000);

      expect(await repo.netDebtOf(nam), 200000);
      expect(await repo.netDebtOf(hung), -1000000);
      expect(await repo.netDebtOf(lan), 0);

      final debts = await repo.watchDebts().first;
      expect(debts, hasLength(2), reason: 'Lan đã sạch nợ nên không hiện');
      // Sắp xếp theo độ lớn giảm dần.
      expect(debts.first.person.name, 'Hùng');
      expect(debts.last.person.name, 'Nam');
    });
  });

  group('ảnh hưởng lên ví', () {
    test('dòng tiền của các giao dịch nợ khớp với công nợ', () async {
      final nam = await newPerson('Nam');
      final before = await repo.balanceOf(wallet);

      await lend(nam, 200000);
      expect(await repo.balanceOf(wallet), before - 200000,
          reason: 'cho mượn là tiền ra khỏi ví');

      await collect(nam, 200000);
      expect(await repo.balanceOf(wallet), before,
          reason: 'thu nợ xong ví trở lại như cũ');
      expect(await repo.netDebtOf(nam), 0);
    });

    test('vay tiền làm ví tăng, trả nợ làm ví giảm', () async {
      final hung = await newPerson('Hùng');
      final before = await repo.balanceOf(wallet);

      await borrow(hung, 1000000);
      expect(await repo.balanceOf(wallet), before + 1000000);

      await repay(hung, 1000000);
      expect(await repo.balanceOf(wallet), before);
      expect(await repo.netDebtOf(hung), 0);
    });
  });

  group('tất toán', () {
    test('tất toán khoản họ nợ mình bằng cách thu tiền về', () async {
      final nam = await newPerson('Nam');
      await lend(nam, 350000);

      final net = await repo.netDebtOf(nam);
      expect(net, 350000);

      // Tất toán = ghi một giao dịch ngược chiều đúng bằng số dư nợ.
      await collect(nam, net.abs());
      expect(await repo.netDebtOf(nam), 0);
    });

    test('xoá nợ không dòng tiền: công nợ về 0 mà ví không đổi', () async {
      final nam = await newPerson('Nam');
      await lend(nam, 350000);
      final balanceAfterLend = await repo.balanceOf(wallet);

      await repo.addTransaction(
        kind: TxKind.collect,
        amount: 350000,
        occurredAt: DateTime.now(),
        personId: nam,
        isWriteoff: true,
        note: 'Cho luôn',
      );

      expect(await repo.netDebtOf(nam), 0);
      expect(await repo.balanceOf(wallet), balanceAfterLend,
          reason: 'xoá nợ thì không có tiền nào chạy đi đâu cả');
    });
  });

  group('trả dùm', () {
    test('sinh một khoản chi cho phần mình và một khoản cho mượn', () async {
      final nam = await newPerson('Nam');
      final catId = await repo.insertCategory(
        CategoriesCompanion.insert(
          name: 'Ăn uống',
          flow: 'expense',
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      final before = await repo.balanceOf(wallet);
      const groupId = 'group-1';

      // Bill 300k, phần mình 100k, phần Nam 200k.
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 100000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        categoryId: catId,
        groupId: groupId,
        note: 'Ăn lẩu',
      );
      await repo.addTransaction(
        kind: TxKind.lend,
        amount: 200000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        personId: nam,
        groupId: groupId,
        note: 'Ăn lẩu - trả dùm',
      );

      expect(await repo.balanceOf(wallet), before - 300000,
          reason: 'ví giảm đúng số tiền thật đã trả');
      expect(await repo.netDebtOf(nam), 200000,
          reason: 'Nam chỉ nợ phần của Nam');

      final now = DateTime.now();
      final totals =
          await repo.watchMonthTotals(now.year * 100 + now.month).first;
      expect(totals.expense, 100000,
          reason: 'chi tiêu chỉ tính phần mình ăn, không tính tiền của bạn');
    });

    test('xoá nhóm thì cả hai giao dịch cùng biến mất và hoàn tác được',
        () async {
      final nam = await newPerson('Nam');
      const groupId = 'group-1';
      final before = await repo.balanceOf(wallet);

      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 100000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        groupId: groupId,
      );
      await repo.addTransaction(
        kind: TxKind.lend,
        amount: 200000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        personId: nam,
        groupId: groupId,
      );
      expect(await repo.countInGroup(groupId), 2);

      final removed = await repo.softDeleteGroup(groupId);
      expect(removed, hasLength(2));
      expect(await repo.balanceOf(wallet), before);
      expect(await repo.netDebtOf(nam), 0);

      await repo.restoreMany(removed);
      expect(await repo.balanceOf(wallet), before - 300000);
      expect(await repo.netDebtOf(nam), 200000);
    });
  });

  group('nhất quán giữa debt_delta và kind', () {
    test('debt_delta ghi trong DB luôn khớp với công thức của kind', () async {
      final nam = await newPerson('Nam');
      await lend(nam, 100000);
      await collect(nam, 30000);
      await borrow(nam, 500000);
      await repay(nam, 200000);

      final txs = await repo.watchTransactions(personId: nam).first;
      expect(txs, hasLength(4));
      for (final view in txs) {
        expect(
          view.tx.debtDelta,
          view.kind.debtDelta(view.tx.amount),
          reason: 'lệch ở giao dịch ${view.kind.name}',
        );
      }

      // Tổng phải khớp với phép cộng tay.
      expect(await repo.netDebtOf(nam), 100000 - 30000 - 500000 + 200000);
    });

    test('giao dịch không liên quan tới nợ có debt_delta bằng 0', () async {
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
      );
      final txs = await repo.watchTransactions().first;
      expect(txs.first.tx.debtDelta, 0);
    });

    test('xoá mềm giao dịch nợ thì công nợ giảm theo', () async {
      final nam = await newPerson('Nam');
      await lend(nam, 200000);
      final txs = await repo.watchTransactions(personId: nam).first;

      await repo.softDeleteTransaction(txs.first.tx.id);
      expect(await repo.netDebtOf(nam), 0);

      await repo.restoreTransaction(txs.first.tx.id);
      expect(await repo.netDebtOf(nam), 200000);
    });
  });
}
