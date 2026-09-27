import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/features/stats/category_detail_screen.dart';

BudgetProgress makeProgress({
  int categoryId = 1,
  required int limit,
  required int spent,
  required int daysElapsed,
  int daysInMonth = 30,
}) {
  return BudgetProgress(
    budgetId: categoryId,
    categoryId: categoryId,
    categoryName: 'Ăn uống',
    limitAmount: limit,
    spent: spent,
    isRecurring: true,
    monthKey: 202609,
    daysInMonth: daysInMonth,
    daysElapsed: daysElapsed,
  );
}

void main() {
  group('hạn mức bị chặn bởi tiền thật', () {
    test('đúng số liệu của người dùng ngày 27/9', () {
      // Hạn mức ăn uống 2tr, đã tiêu 1.700.320 (119k trong hôm nay), nhưng
      // "tiền tiêu được" chỉ còn 188.911 vì đã chi sang những mục khác.
      final raw = makeProgress(limit: 2000000, spent: 1700320, daysElapsed: 27);
      expect(raw.remaining, 299680);
      expect(raw.remainingDailyAllowance, 99893, reason: 'số app đang hiện');

      final b = capBudgetsByCash([raw], 188911).single;
      expect(b.isLimitedByCash, isTrue);
      expect(b.spendable, 188911);
      expect(b.remaining, 299680, reason: 'hạn mức vẫn giữ nguyên số của nó');
      expect(b.remainingDailyAllowance, 62970, reason: '188.911 / 3 ngày');
      expect(b.budgetForToday(119000), (188911 + 119000) ~/ 4);
      expect(b.needsAttention, isTrue);
    });

    test('đủ tiền thì không đụng tới hạn mức', () {
      final raw = makeProgress(limit: 3000000, spent: 1000000, daysElapsed: 10);
      final b = capBudgetsByCash([raw], 5000000).single;
      expect(b.isLimitedByCash, isFalse);
      expect(b.spendable, 2000000);
      expect(b.remainingDailyAllowance, raw.remainingDailyAllowance);
    });

    test('nhiều hạn mức thì chia tiền theo tỉ lệ phần còn lại', () {
      final food = makeProgress(
        limit: 3000000,
        spent: 2400000,
        daysElapsed: 20,
      );
      final move = makeProgress(
        categoryId: 2,
        limit: 1000000,
        spent: 800000,
        daysElapsed: 20,
      );
      // Còn 600k + 200k = 800k nhưng ví chỉ có 400k.
      final capped = capBudgetsByCash([food, move], 400000);
      expect(capped[0].spendable, 300000);
      expect(capped[1].spendable, 100000);
      expect(
        capped.fold<int>(0, (s, b) => s + b.spendable) <= 400000,
        isTrue,
        reason: 'tổng các phần không được vượt số tiền đang có',
      );
    });

    test('hạn mức đã vượt không lấy phần tiền nào', () {
      final over = makeProgress(
        limit: 1000000,
        spent: 1200000,
        daysElapsed: 20,
      );
      final ok = makeProgress(
        categoryId: 2,
        limit: 1000000,
        spent: 500000,
        daysElapsed: 20,
      );
      final capped = capBudgetsByCash([over, ok], 300000);
      expect(capped[0].cashCap, 0);
      expect(capped[0].spendable, -200000, reason: 'vượt thì vẫn là số âm');
      expect(capped[1].spendable, 300000);
    });

    test('ví âm thì không còn gì để tiêu', () {
      final raw = makeProgress(limit: 3000000, spent: 0, daysElapsed: 10);
      final b = capBudgetsByCash([raw], -50000).single;
      expect(b.spendable, 0);
      expect(b.remainingDailyAllowance, 0);
      expect(b.leftForToday(0), 0);
    });
  });

  group('ghi bù khoản chi của hôm qua', () {
    // Hạn mức 3tr/30 ngày = 100k/ngày. Ngày 10 ăn 400k.

    test('ghi bù sáng hôm sau cho ra đúng mốc như ghi ngay trong ngày', () {
      // Cách 1: ghi ngay ngày 10 -> sang ngày 11 xem mốc.
      // Cách 2: quên, sáng ngày 11 mới ghi với ngày 10 -> cùng một trạng thái
      // dữ liệu: spent = 900k + 400k, hôm nay (ngày 11) chưa tiêu gì.
      final day11 = makeProgress(
        limit: 3000000,
        spent: 900000 + 400000,
        daysElapsed: 11,
      );
      // Trước đó 9 ngày đều đặn 100k.
      expect(day11.budgetForToday(0), 1700000 ~/ 20);
      expect(day11.budgetForToday(0) < day11.dailyAllowance, isTrue);
    });

    test('phần tiêu lố của những ngày trước lộ ra, dù ghi lúc nào', () {
      final day11 = makeProgress(
        limit: 3000000,
        spent: 1300000,
        daysElapsed: 11,
      );
      // Đáng lẽ hết ngày 10 mới tiêu 1tr, thực tế 1,3tr.
      expect(day11.overspentBeforeToday(0), 300000);
    });

    test('tiêu hôm nay không bị tính là lố của ngày trước', () {
      final b = makeProgress(
        limit: 3000000,
        spent: 1000000 + 250000,
        daysElapsed: 11,
      );
      expect(b.overspentBeforeToday(250000), 0);
    });
  });

  group('trên cơ sở dữ liệu', () {
    late AppDatabase db;
    late Repository repo;
    late int wallet;
    late int food;

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
      food = await repo.insertCategory(
        CategoriesCompanion.insert(
          name: 'Ăn uống',
          flow: 'expense',
          createdAt: 0,
          updatedAt: 0,
        ),
      );
    });

    tearDown(() async => db.close());

    test('khoản ghi bù cho hôm qua hạ mốc của hôm nay', () async {
      await repo.setBudget(categoryId: food, limitAmount: 3000000);
      final today = DateTime(2026, 9, 11);

      final before = (await repo.watchBudgets(202609, now: today).first).single;

      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 400000,
        occurredAt: DateTime(2026, 9, 10, 20),
        walletFromId: wallet,
        categoryId: food,
      );
      final after = (await repo.watchBudgets(202609, now: today).first).single;

      expect(after.daysElapsed, 11);
      expect(after.budgetForToday(0) < before.budgetForToday(0), isTrue);
      expect(after.budgetForToday(0), 2600000 ~/ 20);
    });

    test('mốc hôm nay đi theo ngày truyền vào chứ không đứng yên', () async {
      await repo.setBudget(categoryId: food, limitAmount: 3000000);
      final d10 =
          (await repo.watchBudgets(202609, now: DateTime(2026, 9, 10)).first)
              .single;
      final d11 =
          (await repo.watchBudgets(202609, now: DateTime(2026, 9, 11)).first)
              .single;
      expect(d10.daysElapsed, 10);
      expect(d11.daysElapsed, 11);
    });

    test('lọc được giao dịch chưa phân loại', () async {
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime(2026, 9, 3),
        walletFromId: wallet,
      );
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 70000,
        occurredAt: DateTime(2026, 9, 3),
        walletFromId: wallet,
        categoryId: food,
      );
      final list = await repo
          .watchTransactions(uncategorized: true, monthKey: 202609)
          .first;
      expect(list.map((v) => v.tx.amount), [50000]);
    });

    test('tổng theo ngày đủ mọi ngày, kể cả ngày không tiêu', () async {
      Future<void> spend(int amount, DateTime at) => repo.addTransaction(
        kind: TxKind.expense,
        amount: amount,
        occurredAt: at,
        walletFromId: wallet,
        categoryId: food,
      );
      await spend(20000, DateTime(2026, 9, 1, 8));
      await spend(35000, DateTime(2026, 9, 1, 12));
      await spend(45000, DateTime(2026, 9, 3, 23, 30));
      await spend(99000, DateTime(2026, 8, 31, 23, 59));

      final list = await repo
          .watchTransactions(
            categoryId: food,
            monthKey: 202609,
            kind: TxKind.expense,
          )
          .first;
      expect(dailyTotals(list, 202609, 4), [55000, 0, 45000, 0]);
    });
  });
}
