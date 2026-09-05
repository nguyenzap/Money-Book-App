import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';

void main() {
  late AppDatabase db;
  late Repository repo;
  late int wallet;
  late int catAnUong;
  late int catDiLai;
  late int nam;

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
    Future<int> category(String name) => repo.insertCategory(
          CategoriesCompanion.insert(
            name: name,
            flow: 'expense',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
    catAnUong = await category('Ăn uống');
    catDiLai = await category('Đi lại');
    nam = await repo.insertPerson(
      PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
    );
  });

  tearDown(() async => db.close());

  Future<void> spend(int amount, int categoryId, {DateTime? at}) =>
      repo.addTransaction(
        kind: TxKind.expense,
        amount: amount,
        occurredAt: at ?? DateTime(2026, 9, 10),
        walletFromId: wallet,
        categoryId: categoryId,
      );

  group('tiến độ ngân sách', () {
    test('chưa tiêu gì thì tiến độ bằng 0', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      final list = await repo.watchBudgets(202609).first;

      expect(list, hasLength(1));
      expect(list.first.categoryName, 'Ăn uống');
      expect(list.first.limitAmount, 3000000);
      expect(list.first.spent, 0);
      expect(list.first.remaining, 3000000);
      expect(list.first.isOver, isFalse);
    });

    test('cộng dồn các khoản chi cùng danh mục', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      await spend(500000, catAnUong);
      await spend(300000, catAnUong);

      final b = (await repo.watchBudgets(202609).first).first;
      expect(b.spent, 800000);
      expect(b.remaining, 2200000);
    });

    test('danh mục khác không lẫn vào', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      await spend(500000, catAnUong);
      await spend(900000, catDiLai);

      final b = (await repo.watchBudgets(202609).first).first;
      expect(b.spent, 500000, reason: 'chỉ tính tiền ăn uống');
    });

    test('cảnh báo khi sắp chạm hạn mức', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      await spend(2800000, catAnUong);

      final b = (await repo.watchBudgets(202609).first).first;
      expect(b.isNearLimit, isTrue);
      expect(b.isOver, isFalse);
      expect(b.remaining, 200000);
    });

    test('báo vượt khi tiêu quá hạn mức', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      await spend(3500000, catAnUong);

      final b = (await repo.watchBudgets(202609).first).first;
      expect(b.isOver, isTrue);
      expect(b.isNearLimit, isFalse, reason: 'đã vượt thì không còn là sắp');
      expect(b.remaining, -500000);
    });

    test('chi tháng khác không tính vào tháng này', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      await spend(500000, catAnUong, at: DateTime(2026, 8, 20));
      await spend(200000, catAnUong, at: DateTime(2026, 9, 10));

      expect((await repo.watchBudgets(202609).first).first.spent, 200000);
      expect((await repo.watchBudgets(202608).first).first.spent, 500000);
    });
  });

  group('ngân sách với trả dùm - điểm mấu chốt', () {
    test('bữa 200k chia 4 chỉ trừ 50k ngân sách, không phải 200k', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 1000000);

      final hung = await repo.insertPerson(
        PeopleCompanion.insert(name: 'Hùng', createdAt: 0, updatedAt: 0),
      );
      final lan = await repo.insertPerson(
        PeopleCompanion.insert(name: 'Lan', createdAt: 0, updatedAt: 0),
      );

      await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 50000,
        sharesByPerson: {nam: 50000, hung: 50000, lan: 50000},
        occurredAt: DateTime(2026, 9, 10),
        categoryId: catAnUong,
      );

      final b = (await repo.watchBudgets(202609).first).first;
      expect(b.spent, 50000,
          reason: '150k của bạn bè không được tính vào ngân sách của mình');
      expect(b.remaining, 950000);
      expect(await repo.balanceOf(wallet), 10000000 - 200000,
          reason: 'ví vẫn trừ đủ 200k tiền thật đã trả');
    });

    test('trả dùm không làm vượt ngân sách oan', () async {
      // Hạn mức 500k, đã tiêu 450k. Giờ trả dùm bữa 400k nhưng mình chỉ ăn 40k.
      await repo.setBudget(categoryId: catAnUong, limitAmount: 500000);
      await spend(450000, catAnUong);

      await repo.addSplitBill(
        walletFromId: wallet,
        myShare: 40000,
        sharesByPerson: {nam: 360000},
        occurredAt: DateTime(2026, 9, 10),
        categoryId: catAnUong,
      );

      final b = (await repo.watchBudgets(202609).first).first;
      expect(b.spent, 490000);
      expect(b.isOver, isFalse,
          reason: 'nếu tính cả 400k thì đã báo vượt oan');
      expect(b.isNearLimit, isTrue);
    });

    test('các loại giao dịch khác không đụng vào ngân sách', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 1000000);
      final wallet2 = await repo.insertWallet(
        WalletsCompanion.insert(name: 'MoMo', createdAt: 0, updatedAt: 0),
      );

      await repo.addTransaction(
        kind: TxKind.transfer,
        amount: 2000000,
        occurredAt: DateTime(2026, 9, 10),
        walletFromId: wallet,
        walletToId: wallet2,
      );
      await repo.addTransaction(
        kind: TxKind.lend,
        amount: 300000,
        occurredAt: DateTime(2026, 9, 10),
        walletFromId: wallet,
        personId: nam,
      );
      await repo.adjustWalletBalance(walletId: wallet, newBalance: 1);

      final b = (await repo.watchBudgets(202609).first).first;
      expect(b.spent, 0,
          reason: 'chuyển ví, cho mượn, điều chỉnh số dư đều không phải tiêu');
    });
  });

  group('quản lý hạn mức', () {
    test('đặt lại hạn mức thì ghi đè chứ không tạo thêm', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      await repo.setBudget(categoryId: catAnUong, limitAmount: 4000000);

      final list = await repo.watchBudgets(202609).first;
      expect(list, hasLength(1));
      expect(list.first.limitAmount, 4000000);
    });

    test('hạn mức mọi tháng áp dụng cho mọi tháng', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);

      expect(await repo.watchBudgets(202608).first, hasLength(1));
      expect(await repo.watchBudgets(202609).first, hasLength(1));
      expect(await repo.watchBudgets(202701).first, hasLength(1));
      expect(
        (await repo.watchBudgets(202609).first).first.isRecurring,
        isTrue,
      );
    });

    test('hạn mức riêng một tháng chỉ hiện ở tháng đó', () async {
      await repo.setBudget(
        categoryId: catAnUong,
        limitAmount: 5000000,
        monthKey: 202609,
      );

      expect(await repo.watchBudgets(202609).first, hasLength(1));
      expect(await repo.watchBudgets(202608).first, isEmpty);
      expect(
        (await repo.watchBudgets(202609).first).first.isRecurring,
        isFalse,
      );
    });

    test('xoá hạn mức', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      final b = (await repo.watchBudgets(202609).first).first;

      await repo.deleteBudget(b.budgetId);
      expect(await repo.watchBudgets(202609).first, isEmpty);
    });

    test('xoá danh mục thì hạn mức của nó cũng đi theo', () async {
      await repo.setBudget(categoryId: catAnUong, limitAmount: 3000000);
      await repo.deleteCategory(catAnUong);
      expect(await repo.watchBudgets(202609).first, isEmpty);
    });
  });
}
