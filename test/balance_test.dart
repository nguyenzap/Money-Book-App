// `isNull` của drift trùng tên với matcher cùng tên của flutter_test.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';

void main() {
  late AppDatabase db;
  late Repository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    // Khoá ngoại mặc định bị tắt; bật lên cho giống hệt lúc chạy thật.
    await db.customStatement('PRAGMA foreign_keys = ON');
  });

  tearDown(() async => db.close());

  Future<int> newWallet(String name, int initial) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return repo.insertWallet(
      WalletsCompanion.insert(
        name: name,
        initialBalance: Value(initial),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<int> newCategory(String name, String flow) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return repo.insertCategory(
      CategoriesCompanion.insert(
        name: name,
        flow: flow,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('số dư ví', () {
    test('ví mới chỉ có số dư ban đầu', () async {
      final id = await newWallet('Tiền mặt', 500000);
      expect(await repo.balanceOf(id), 500000);
    });

    test('chi tiêu làm giảm số dư', () async {
      final wallet = await newWallet('Tiền mặt', 500000);
      final cat = await newCategory('Ăn uống', 'expense');
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        categoryId: cat,
      );
      expect(await repo.balanceOf(wallet), 450000);
    });

    test('thu nhập làm tăng số dư', () async {
      final wallet = await newWallet('MB', 1000000);
      final cat = await newCategory('Lương', 'income');
      await repo.addTransaction(
        kind: TxKind.income,
        amount: 5000000,
        occurredAt: DateTime.now(),
        walletToId: wallet,
        categoryId: cat,
      );
      expect(await repo.balanceOf(wallet), 6000000);
    });

    test('chuyển ví: hai ví đổi, tổng tài sản giữ nguyên', () async {
      final mb = await newWallet('MB', 5000000);
      final momo = await newWallet('MoMo', 1000000);
      final before = await repo.watchTotalAssets().first;

      await repo.addTransaction(
        kind: TxKind.transfer,
        amount: 1000000,
        occurredAt: DateTime.now(),
        walletFromId: mb,
        walletToId: momo,
      );

      expect(await repo.balanceOf(mb), 4000000);
      expect(await repo.balanceOf(momo), 2000000);
      expect(await repo.watchTotalAssets().first, before,
          reason: 'chuyển tiền giữa ví của mình không làm mình giàu/nghèo đi');
    });

    test('vay nợ làm tăng số dư ví (tiền thật đã vào túi)', () async {
      final wallet = await newWallet('Tiền mặt', 100000);
      final person = await repo.insertPerson(
        PeopleCompanion.insert(
          name: 'Hùng',
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      await repo.addTransaction(
        kind: TxKind.borrow,
        amount: 1000000,
        occurredAt: DateTime.now(),
        walletToId: wallet,
        personId: person,
      );
      expect(await repo.balanceOf(wallet), 1100000);
    });

    test('cho mượn làm giảm số dư ví', () async {
      final wallet = await newWallet('Tiền mặt', 1000000);
      final person = await repo.insertPerson(
        PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
      );
      await repo.addTransaction(
        kind: TxKind.lend,
        amount: 200000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        personId: person,
      );
      expect(await repo.balanceOf(wallet), 800000);
    });

    test('xoá mềm giao dịch thì số dư quay lại như cũ', () async {
      final wallet = await newWallet('Tiền mặt', 500000);
      final cat = await newCategory('Ăn uống', 'expense');
      final txId = await repo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        categoryId: cat,
      );
      expect(await repo.balanceOf(wallet), 450000);

      await repo.softDeleteTransaction(txId);
      expect(await repo.balanceOf(wallet), 500000);

      await repo.restoreTransaction(txId);
      expect(await repo.balanceOf(wallet), 450000,
          reason: 'hoàn tác phải trả lại đúng trạng thái trước khi xoá');
    });

    test('tổng tài sản là tổng số dư các ví', () async {
      await newWallet('Tiền mặt', 500000);
      await newWallet('MoMo', 1000000);
      await newWallet('MB', 5000000);
      await newWallet('Techcom', 2000000);
      expect(await repo.watchTotalAssets().first, 8500000);
    });

    test('ví lưu trữ không tính vào tổng tài sản', () async {
      final a = await newWallet('Tiền mặt', 500000);
      await newWallet('Ví cũ', 300000);
      await repo.archiveWallet(a, archived: true);
      expect(await repo.watchTotalAssets().first, 300000);
    });
  });

  group('điều chỉnh số dư', () {
    test('điều chỉnh giảm sinh giao dịch bù và số dư khớp số thật', () async {
      final wallet = await newWallet('Tiền mặt', 500000);
      await repo.adjustWalletBalance(walletId: wallet, newBalance: 400000);
      expect(await repo.balanceOf(wallet), 400000);

      final txs = await repo.watchTransactions(walletId: wallet).first;
      expect(txs, hasLength(1));
      expect(txs.first.kind, TxKind.adjust);
      expect(txs.first.tx.amount, 100000, reason: 'amount luôn dương');
      expect(txs.first.tx.walletFromId, wallet,
          reason: 'số dư giảm thì tiền đi ra');
      expect(txs.first.tx.walletToId, isNull);
    });

    test('điều chỉnh tăng thì tiền đi vào', () async {
      final wallet = await newWallet('Tiền mặt', 400000);
      await repo.adjustWalletBalance(walletId: wallet, newBalance: 500000);
      expect(await repo.balanceOf(wallet), 500000);

      final txs = await repo.watchTransactions(walletId: wallet).first;
      expect(txs.first.tx.walletToId, wallet);
      expect(txs.first.tx.walletFromId, isNull);
      expect(txs.first.tx.amount, 100000);
    });

    test('không chênh lệch thì không ghi gì cả', () async {
      final wallet = await newWallet('Tiền mặt', 500000);
      final result =
          await repo.adjustWalletBalance(walletId: wallet, newBalance: 500000);
      expect(result, isNull);
      expect(await repo.watchTransactions(walletId: wallet).first, isEmpty);
    });

    test('điều chỉnh sau khi đã có giao dịch vẫn ra đúng số', () async {
      final wallet = await newWallet('Tiền mặt', 500000);
      final cat = await newCategory('Ăn uống', 'expense');
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 120000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        categoryId: cat,
      );
      // Đếm ví thật thấy còn 350k chứ không phải 380k.
      await repo.adjustWalletBalance(walletId: wallet, newBalance: 350000);
      expect(await repo.balanceOf(wallet), 350000);
    });
  });

  group('thống kê tháng', () {
    test('chỉ tính thu nhập và chi tiêu', () async {
      final w1 = await newWallet('Tiền mặt', 10000000);
      final w2 = await newWallet('MoMo', 0);
      final catE = await newCategory('Ăn uống', 'expense');
      final catI = await newCategory('Lương', 'income');
      final person = await repo.insertPerson(
        PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
      );
      final now = DateTime.now();

      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 100000,
        occurredAt: now,
        walletFromId: w1,
        categoryId: catE,
      );
      await repo.addTransaction(
        kind: TxKind.income,
        amount: 5000000,
        occurredAt: now,
        walletToId: w1,
        categoryId: catI,
      );
      // Ba khoản dưới đây KHÔNG được tính vào thu/chi.
      await repo.addTransaction(
        kind: TxKind.transfer,
        amount: 2000000,
        occurredAt: now,
        walletFromId: w1,
        walletToId: w2,
      );
      await repo.addTransaction(
        kind: TxKind.lend,
        amount: 300000,
        occurredAt: now,
        walletFromId: w1,
        personId: person,
      );
      await repo.adjustWalletBalance(walletId: w2, newBalance: 999999);

      final totals = await repo
          .watchMonthTotals(now.year * 100 + now.month)
          .first;
      expect(totals.income, 5000000);
      expect(totals.expense, 100000);
      expect(totals.net, 4900000);
    });

    test('giao dịch tháng khác không lọt vào', () async {
      final w = await newWallet('Tiền mặt', 10000000);
      final cat = await newCategory('Ăn uống', 'expense');
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 100000,
        occurredAt: DateTime(2026, 8, 15),
        walletFromId: w,
        categoryId: cat,
      );
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 200000,
        occurredAt: DateTime(2026, 9, 15),
        walletFromId: w,
        categoryId: cat,
      );

      expect((await repo.watchMonthTotals(202608).first).expense, 100000);
      expect((await repo.watchMonthTotals(202609).first).expense, 200000);
    });

    test('giao dịch cuối tháng lúc nửa đêm không bị xếp nhầm tháng', () async {
      final w = await newWallet('Tiền mặt', 10000000);
      final cat = await newCategory('Ăn uống', 'expense');
      // 23:30 ngày cuối tháng 9 theo giờ Việt Nam vẫn phải nằm ở tháng 9,
      // dù quy về UTC thì đã sang tháng 10.
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 77000,
        occurredAt: DateTime(2026, 9, 30, 23, 30),
        walletFromId: w,
        categoryId: cat,
      );
      expect((await repo.watchMonthTotals(202609).first).expense, 77000);
      expect((await repo.watchMonthTotals(202610).first).expense, 0);
    });
  });

  group('ràng buộc dữ liệu', () {
    test('không xoá được ví đang có giao dịch', () async {
      final wallet = await newWallet('Tiền mặt', 500000);
      final cat = await newCategory('Ăn uống', 'expense');
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        categoryId: cat,
      );
      expect(await repo.countTransactionsOfWallet(wallet), 1);
      await expectLater(repo.deleteWallet(wallet), throwsA(anything));
    });

    test('xoá danh mục thì giao dịch còn nguyên, chỉ mất phân loại', () async {
      final wallet = await newWallet('Tiền mặt', 500000);
      final cat = await newCategory('Ăn uống', 'expense');
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime.now(),
        walletFromId: wallet,
        categoryId: cat,
      );

      await repo.deleteCategory(cat);

      final txs = await repo.watchTransactions().first;
      expect(txs, hasLength(1), reason: 'giao dịch không được biến mất');
      expect(txs.first.tx.categoryId, isNull);
      expect(await repo.balanceOf(wallet), 450000,
          reason: 'số dư không được đổi khi xoá danh mục');
    });
  });
}
