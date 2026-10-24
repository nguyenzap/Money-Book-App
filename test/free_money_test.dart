import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/free_money.dart';
import 'package:moneybook/core/domain/tx_kind.dart';

BudgetProgress budget({
  int id = 1,
  String name = 'Ăn uống',
  required int limit,
  required int spent,
  int? spentToday,
}) {
  return BudgetProgress(
    budgetId: id,
    categoryId: id,
    categoryName: name,
    limitAmount: limit,
    spent: spent,
    isRecurring: true,
    monthKey: 202609,
    daysInMonth: 30,
    daysElapsed: 10,
    spentToday: spentToday,
  );
}

FreeMoney money({
  required int spendable,
  List<BudgetProgress> budgets = const [],
  List<DebtSummary> debts = const [],
  int daysRemaining = 19,
  int spentToday = 0,
}) {
  return FreeMoney.from(
    spendable: spendable,
    budgets: budgets,
    debts: debts,
    daysRemaining: daysRemaining,
    spentToday: spentToday,
  );
}

DebtSummary debt(int net) => DebtSummary(
  Person(
    id: 1,
    name: 'Đức',
    isArchived: false,
    sortOrder: 0,
    createdAt: 0,
    updatedAt: 0,
  ),
  net,
);

void main() {
  group('tiền tự do', () {
    test('tiền ngân sách những ngày trước tiêu không hết thành tiền tự do', () {
      // Hạn mức 3tr = 100k/ngày, hôm nay ngày 10. 9 ngày trước chỉ tiêu 600k
      // thay vì 900k: dư 300k.
      final b = budget(limit: 3000000, spent: 600000, spentToday: 0);
      final m = money(spendable: 4000000, budgets: [b]);
      expect(m.reserved, 2100000);
      expect(m.free, 1900000, reason: '300k dư cộng vào tiền tự do');
    });

    test('chi vượt phần còn giữ thì lấy từ tiền tự do', () {
      final b = budget(limit: 3000000, spent: 600000, spentToday: 0);
      final m = money(spendable: 4000000, budgets: [b]);
      final i = m.preview(amount: 2200000, budget: b);
      expect(i.fromBudget, 2100000);
      expect(i.fromFree, 100000);
      expect(i.budgetLeftAfter, -100000);
    });

    test('đúng ví dụ: có 4tr, tiền ăn còn 2tr thì tự do 2tr', () {
      final m = money(
        spendable: 4000000,
        budgets: [budget(limit: 2000000, spent: 0)],
      );
      expect(m.reserved, 2000000);
      expect(m.free, 2000000);
      expect(m.isExhausted, isFalse);
    });

    test('chỉ giữ phần hạn mức CÒN LẠI, không giữ cả hạn mức', () {
      final m = money(
        spendable: 4000000,
        budgets: [budget(limit: 2000000, spent: 500000)],
      );
      expect(m.free, 2500000);
    });

    test('hạn mức đã vượt không giữ thêm gì', () {
      final m = money(
        spendable: 1000000,
        budgets: [budget(limit: 2000000, spent: 2300000)],
      );
      expect(m.reserved, 0);
      expect(m.free, 1000000);
    });

    test('số liệu của người dùng ngày 27/9: đang thiếu tiền ăn', () {
      final m = money(
        spendable: 188911,
        budgets: [budget(limit: 2000000, spent: 1700320)],
        daysRemaining: 3,
      );
      expect(m.free, -110769);
      expect(m.isExhausted, isTrue);
      expect(m.budgetForToday, 0);
      expect(m.perDayAfterToday, 0);
    });

    test('nợ phải trả bị trừ, người khác nợ mình thì không cộng', () {
      final m = money(spendable: 1000000, debts: [debt(-200000), debt(300000)]);
      expect(m.owed, 200000);
      expect(m.free, 800000);
    });

    test('đi vay không làm tiền tự do phồng lên', () {
      final before = money(spendable: 1000000);
      // Mượn 500k: ví tăng 500k, nợ phải trả cũng tăng 500k.
      final after = money(spendable: 1500000, debts: [debt(-500000)]);
      expect(after.free, before.free);
    });
  });

  group('nên tiêu bao nhiêu hôm nay', () {
    test('chia đều tiền tự do cho số ngày còn lại kể cả hôm nay', () {
      final m = money(spendable: 2000000, daysRemaining: 19);
      expect(m.budgetForToday, 100000);
      expect(m.leftForToday, 100000);
    });

    test('tiêu thêm trong ngày thì mốc đứng yên, phần còn lại giảm', () {
      // Sáng còn 2tr; tiêu tự do 30k -> ví còn 1.970.000.
      final m = money(spendable: 1970000, daysRemaining: 19, spentToday: 30000);
      expect(m.budgetForToday, 100000);
      expect(m.leftForToday, 70000);
    });

    test('tiêu lố hôm nay thì những ngày sau bị rút xuống', () {
      final m = money(
        spendable: 1750000,
        daysRemaining: 19,
        spentToday: 250000,
      );
      expect(m.leftForToday, -150000);
      expect(m.perDayAfterToday, 1750000 ~/ 19);
      expect(m.perDayAfterToday < 100000, isTrue);
    });
  });

  group('xem trước một khoản chi', () {
    final food = budget(limit: 2000000, spent: 1500000);

    test('nằm gọn trong hạn mức thì tiền tự do không đổi', () {
      final m = money(spendable: 2500000, budgets: [food]);
      final i = m.preview(amount: 50000, budget: food);
      expect(i.fromBudget, 50000);
      expect(i.fromFree, 0);
      expect(i.fromReserve, 0);
      expect(i.freeAfter, m.free);
      expect(i.budgetLeftAfter, 450000);
    });

    test('chi vào mục không có hạn mức thì lấy từ tiền tự do', () {
      final m = money(spendable: 2500000, budgets: [food]);
      final i = m.preview(amount: 300000);
      expect(i.fromFree, 300000);
      expect(i.fromReserve, 0);
      expect(i.freeAfter, 1700000);
    });

    test('hết tiền tự do thì báo lấn vào tiền ăn', () {
      // Ví 600k, tiền ăn còn 500k -> tự do 100k. Mua món 250k.
      final m = money(spendable: 600000, budgets: [food]);
      final i = m.preview(amount: 250000);
      expect(i.fromFree, 100000);
      expect(i.fromReserve, 150000);
      expect(i.freeAfter, -150000);
    });

    test('vượt hạn mức ăn uống thì phần vượt lấy từ tiền tự do', () {
      final m = money(spendable: 2500000, budgets: [food]);
      final i = m.preview(amount: 600000, budget: food);
      expect(i.fromBudget, 500000);
      expect(i.fromFree, 100000);
      expect(i.budgetLeftAfter, -100000);
    });

    test('trả dùm: phần của mình vào hạn mức, phần của bạn lấy từ tự do', () {
      final m = money(spendable: 2500000, budgets: [food]);
      final i = m.preview(amount: 50000, budget: food, outside: 150000);
      expect(i.fromBudget, 50000);
      expect(i.fromFree, 150000);
    });

    test('vượt mốc hôm nay thì được đánh dấu', () {
      final m = money(spendable: 2000000, daysRemaining: 19);
      expect(m.preview(amount: 90000).overToday, isFalse);
      expect(m.preview(amount: 120000).overToday, isTrue);
    });
  });

  group('chi ngoài ngân sách trong ngày', () {
    late AppDatabase db;
    late Repository repo;
    late int wallet;
    late int food;
    late int shopping;
    late int nam;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = Repository(db);
      await db.customStatement('PRAGMA foreign_keys = ON');
      wallet = await repo.insertWallet(
        WalletsCompanion.insert(
          name: 'Tiền mặt',
          initialBalance: const Value(5000000),
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      Future<int> category(String name) => repo.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          flow: 'expense',
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      food = await category('Ăn uống');
      shopping = await category('Mua sắm');
      nam = await repo.insertPerson(
        PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
      );
      await repo.setBudget(categoryId: food, limitAmount: 2000000);
    });

    tearDown(() async => db.close());

    Future<void> tx(TxKind kind, int amount, {int? category, int? person}) =>
        repo.addTransaction(
          kind: kind,
          amount: amount,
          occurredAt: DateTime(2026, 9, 10, 12),
          walletFromId: wallet,
          categoryId: category,
          personId: person,
        );

    test('chỉ đếm mục không có hạn mức, chưa phân loại và cho mượn', () async {
      await tx(TxKind.expense, 50000, category: food); // trong ngân sách
      await tx(TxKind.expense, 120000, category: shopping);
      await tx(TxKind.expense, 10000); // chưa phân loại
      await tx(TxKind.lend, 70000, person: nam);

      final total = await repo
          .watchSpentOutsideBudgetsOnDay(20260910, 202609)
          .first;
      expect(total, 200000);
    });

    test('ngày khác không lẫn vào', () async {
      await tx(TxKind.expense, 120000, category: shopping);
      final total = await repo
          .watchSpentOutsideBudgetsOnDay(20260911, 202609)
          .first;
      expect(total, 0);
    });
  });
}
