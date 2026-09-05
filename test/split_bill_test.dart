import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';

/// Kịch bản trọng tâm: đi ăn 200k chia đều 4 người, mình trả hết.
///
/// Ví phải giảm đủ 200k, nhưng thống kê và ngân sách chỉ được tính 50k — phần
/// mình thực sự ăn. 150k còn lại là tiền của bạn bè, không phải mình tiêu.
void main() {
  late AppDatabase db;
  late Repository repo;
  late int wallet;
  late int catAnUong;
  late int nam;
  late int hung;
  late int lan;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    await db.customStatement('PRAGMA foreign_keys = ON');

    wallet = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        initialBalance: const Value(1000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    catAnUong = await repo.insertCategory(
      CategoriesCompanion.insert(
        name: 'Ăn uống',
        flow: 'expense',
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    Future<int> person(String name) => repo.insertPerson(
          PeopleCompanion.insert(name: name, createdAt: 0, updatedAt: 0),
        );
    nam = await person('Nam');
    hung = await person('Hùng');
    lan = await person('Lan');
  });

  tearDown(() async => db.close());

  group('đi ăn 200k chia đều 4 người', () {
    late List<int> ids;

    setUp(() async {
      ids = await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 50000,
        sharesByPerson: {nam: 50000, hung: 50000, lan: 50000},
        occurredAt: DateTime(2026, 9, 6, 19, 0),
        categoryId: catAnUong,
        note: 'Ăn lẩu',
      );
    });

    test('ví giảm đúng 200k - số tiền thật đã trả', () async {
      expect(await repo.balanceOf(wallet), 800000);
    });

    test('thống kê chi tiêu CHỈ tính 50k phần mình ăn', () async {
      final totals = await repo.watchMonthTotals(202609).first;
      expect(totals.expense, 50000,
          reason: '150k kia là tiền của bạn bè, không phải mình tiêu');
      expect(totals.income, 0);
    });

    test('ngân sách ăn uống cũng chỉ bị trừ 50k', () async {
      final byCategory = await repo.watchCategoryTotals(202609).first;
      expect(byCategory, hasLength(1));
      expect(byCategory.first.name, 'Ăn uống');
      expect(byCategory.first.total, 50000,
          reason: 'trả dùm không được làm vượt ngân sách oan');
    });

    test('mỗi người bạn nợ đúng 50k', () async {
      expect(await repo.netDebtOf(nam), 50000);
      expect(await repo.netDebtOf(hung), 50000);
      expect(await repo.netDebtOf(lan), 50000);
    });

    test('sổ nợ hiện đủ ba người, tổng 150k', () async {
      final debts = await repo.watchDebts().first;
      expect(debts, hasLength(3));
      expect(debts.every((d) => d.theyOweMe), isTrue);
      expect(
        debts.fold<int>(0, (sum, d) => sum + d.absAmount),
        150000,
      );
    });

    test('sinh ra 4 giao dịch: 1 khoản chi + 3 khoản cho mượn', () async {
      expect(ids, hasLength(4));
      final all = await repo.watchTransactions().first;
      expect(all, hasLength(4));
      expect(
        all.where((v) => v.kind == TxKind.expense).length,
        1,
      );
      expect(
        all.where((v) => v.kind == TxKind.lend).length,
        3,
      );
    });

    test('cả nhóm dùng chung một groupId', () async {
      final all = await repo.watchTransactions().first;
      final groups = all.map((v) => v.tx.groupId).toSet();
      expect(groups, hasLength(1));
      expect(groups.first, isNotNull);
      expect(await repo.countInGroup(groups.first!), 4);
    });

    test('tiền của cả nhóm cộng lại bằng đúng hoá đơn', () async {
      final all = await repo.watchTransactions().first;
      final sum = all.fold<int>(0, (s, v) => s + v.tx.amount);
      expect(sum, 200000);
    });

    test('xoá cả nhóm thì ví và sổ nợ về nguyên trạng', () async {
      final all = await repo.watchTransactions().first;
      final groupId = all.first.tx.groupId!;

      final removed = await repo.softDeleteGroup(groupId);
      expect(removed, hasLength(4));
      expect(await repo.balanceOf(wallet), 1000000);
      expect(await repo.netDebtOf(nam), 0);
      expect((await repo.watchMonthTotals(202609).first).expense, 0);

      await repo.restoreMany(removed);
      expect(await repo.balanceOf(wallet), 800000);
      expect(await repo.netDebtOf(nam), 50000);
    });
  });

  group('các cách chia khác', () {
    test('chia không đều: mình ăn nhiều hơn', () async {
      await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 120000,
        sharesByPerson: {nam: 50000, hung: 30000},
        occurredAt: DateTime(2026, 9, 6),
        categoryId: catAnUong,
      );
      expect(await repo.balanceOf(wallet), 800000);
      expect((await repo.watchMonthTotals(202609).first).expense, 120000);
      expect(await repo.netDebtOf(nam), 50000);
      expect(await repo.netDebtOf(hung), 30000);
    });

    test('trả hộ hoàn toàn: mình không ăn nên không sinh khoản chi', () async {
      final ids = await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 0,
        sharesByPerson: {nam: 200000},
        occurredAt: DateTime(2026, 9, 6),
        categoryId: catAnUong,
      );

      expect(ids, hasLength(1), reason: 'chỉ có khoản cho mượn');
      expect(await repo.balanceOf(wallet), 800000);
      expect((await repo.watchMonthTotals(202609).first).expense, 0,
          reason: 'mình không ăn thì không phải chi tiêu của mình');
      expect(await repo.netDebtOf(nam), 200000);
    });

    test('chỉ có mình: coi như khoản chi bình thường', () async {
      final ids = await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 200000,
        sharesByPerson: const {},
        occurredAt: DateTime(2026, 9, 6),
        categoryId: catAnUong,
      );

      expect(ids, hasLength(1));
      expect((await repo.watchMonthTotals(202609).first).expense, 200000);
      expect(await repo.watchDebts().first, isEmpty);
    });

    test('lẻ tiền: phần dư dồn vào mình, tổng vẫn khớp hoá đơn', () async {
      // Hoá đơn 100.000 chia 3 người: 33.333 mỗi người, mình chịu 33.334.
      await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 33334,
        sharesByPerson: {nam: 33333, hung: 33333},
        occurredAt: DateTime(2026, 9, 6),
        categoryId: catAnUong,
      );
      expect(await repo.balanceOf(wallet), 1000000 - 100000);
    });
  });

  group('nhiều bữa khác nhau không lẫn vào nhau', () {
    test('hai bữa riêng biệt có hai nhóm riêng', () async {
      await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 50000,
        sharesByPerson: {nam: 50000},
        occurredAt: DateTime(2026, 9, 6),
        categoryId: catAnUong,
        note: 'Bữa trưa',
      );
      await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 30000,
        sharesByPerson: {nam: 30000},
        occurredAt: DateTime(2026, 9, 7),
        categoryId: catAnUong,
        note: 'Bữa tối',
      );

      final all = await repo.watchTransactions().first;
      final groups = all.map((v) => v.tx.groupId).toSet();
      expect(groups, hasLength(2), reason: 'mỗi bữa một nhóm');

      expect(await repo.netDebtOf(nam), 80000, reason: 'nợ cộng dồn');
      expect((await repo.watchMonthTotals(202609).first).expense, 80000);
      expect(await repo.balanceOf(wallet), 1000000 - 160000);
    });

    test('xoá một bữa không đụng bữa còn lại', () async {
      await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 50000,
        sharesByPerson: {nam: 50000},
        occurredAt: DateTime(2026, 9, 6),
        categoryId: catAnUong,
      );
      await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 30000,
        sharesByPerson: {nam: 30000},
        occurredAt: DateTime(2026, 9, 7),
        categoryId: catAnUong,
      );

      final all = await repo.watchTransactions().first;
      // Danh sách sắp theo thời gian giảm dần nên bữa tối đứng trước.
      final laterGroup = all.first.tx.groupId!;
      await repo.softDeleteGroup(laterGroup);

      expect(await repo.netDebtOf(nam), 50000);
      expect((await repo.watchMonthTotals(202609).first).expense, 50000);
      expect(await repo.balanceOf(wallet), 1000000 - 100000);
    });
  });
}
