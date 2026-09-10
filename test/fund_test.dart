import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';

/// Quỹ tái tạo hành vi thật: tiền dành cho khoản đã biết trước được chuyển sang
/// một ngân hàng ít dùng, nên nó vẫn là tiền trong ví thật, chỉ là không được
/// tính vào phần tiêu hằng ngày.
void main() {
  late AppDatabase db;
  late Repository repo;
  late int momo;
  late int techcom;
  late int catNhaCua;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    await db.customStatement('PRAGMA foreign_keys = ON');
    await db.delete(db.wallets).go();
    await db.delete(db.categories).go();

    momo = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'MoMo',
        initialBalance: const Value(5000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    techcom = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'Techcombank',
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    catNhaCua = await repo.insertCategory(
      CategoriesCompanion.insert(
        name: 'Nhà cửa',
        flow: 'expense',
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  });

  tearDown(() async => db.close());

  Future<int> newFund(String name, {int? target, int? walletId}) =>
      repo.insertFund(
        FundsCompanion.insert(
          name: name,
          walletId: walletId ?? techcom,
          targetAmount: Value(target),
          createdAt: 0,
          updatedAt: 0,
        ),
      );

  Future<int> deposit(int fund, int amount) => repo.depositToFund(
        fundId: fund,
        walletFromId: momo,
        walletToId: techcom,
        amount: amount,
        occurredAt: DateTime(2026, 9, 10),
      );

  group('nạp tiền vào quỹ', () {
    test('chuyển 2tr từ MoMo sang Techcombank cho quỹ KTX', () async {
      final fund = await newFund('Tiền KTX', target: 2000000);
      await deposit(fund, 2000000);

      expect(await repo.balanceOf(momo), 3000000,
          reason: 'MoMo giảm đúng số đã chuyển');
      expect(await repo.balanceOf(techcom), 2000000,
          reason: 'Techcombank khớp với app ngân hàng thật');
      expect(await repo.savedInFund(fund), 2000000);
    });

    test('tổng tài sản KHÔNG đổi khi nạp quỹ', () async {
      final before = await repo.watchTotalAssets().first;
      final fund = await newFund('Tiền KTX');
      await deposit(fund, 2000000);

      expect(await repo.watchTotalAssets().first, before,
          reason: 'tiền chỉ đổi chỗ, vẫn là của mình');
    });

    test('tiền tiêu được giảm đúng bằng số đã dành', () async {
      final fund = await newFund('Tiền KTX');
      await deposit(fund, 2000000);

      expect(await repo.watchTotalAssets().first, 5000000);
      expect(await repo.watchTotalInFunds().first, 2000000);
      expect(await repo.watchSpendableAssets().first, 3000000,
          reason: 'đúng bằng số còn trong MoMo');
    });

    test('nạp nhiều lần thì cộng dồn', () async {
      final fund = await newFund('Tiền KTX', target: 3000000);
      await deposit(fund, 1000000);
      await deposit(fund, 500000);
      await deposit(fund, 500000);
      expect(await repo.savedInFund(fund), 2000000);
    });

    test('nạp quỹ KHÔNG bị tính là chi tiêu', () async {
      final fund = await newFund('Tiền KTX');
      await deposit(fund, 2000000);

      final totals = await repo.watchMonthTotals(202609).first;
      expect(totals.expense, 0,
          reason: 'để dành tiền không phải là tiêu tiền');
    });
  });

  group('nhiều quỹ trong cùng một ví', () {
    test('ba quỹ chung một ngân hàng vẫn tách bạch', () async {
      final ktx = await newFund('Tiền KTX');
      final dien = await newFund('Tiền điện');
      final spay = await newFund('Trả SPayLater');

      await deposit(ktx, 2000000);
      await deposit(dien, 300000);
      await deposit(spay, 700000);

      expect(await repo.savedInFund(ktx), 2000000);
      expect(await repo.savedInFund(dien), 300000);
      expect(await repo.savedInFund(spay), 700000);

      expect(await repo.balanceOf(techcom), 3000000,
          reason: 'ví giữ đúng tổng ba quỹ');
      expect(await repo.watchTotalInFunds().first, 3000000);
      expect(await repo.watchSpendableAssets().first, 2000000);
    });
  });

  group('tiêu tiền từ quỹ', () {
    test('trả tiền nhà từ quỹ: ví giảm, quỹ giảm, vào thống kê chi', () async {
      final fund = await newFund('Tiền KTX', target: 2000000);
      await deposit(fund, 2000000);

      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 2000000,
        occurredAt: DateTime(2026, 9, 25),
        walletFromId: techcom,
        categoryId: catNhaCua,
        fundId: fund,
        note: 'Tiền KTX tháng 10',
      );

      expect(await repo.balanceOf(techcom), 0);
      expect(await repo.savedInFund(fund), 0, reason: 'quỹ đã dùng xong');
      expect(await repo.watchSpendableAssets().first, 3000000,
          reason: 'phần tiêu được không đổi, vì tiền quỹ vốn đã bị loại ra');

      final totals = await repo.watchMonthTotals(202609).first;
      expect(totals.expense, 2000000,
          reason: 'lúc này mới thực sự là chi tiêu');
    });

    test('tiêu một phần thì quỹ còn phần còn lại', () async {
      final fund = await newFund('Tiền điện', target: 500000);
      await deposit(fund, 500000);

      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 320000,
        occurredAt: DateTime(2026, 9, 20),
        walletFromId: techcom,
        categoryId: catNhaCua,
        fundId: fund,
      );

      expect(await repo.savedInFund(fund), 180000);
      expect(await repo.balanceOf(techcom), 180000);
    });

    test('rút tiền khỏi quỹ mà chưa tiêu thì trả về ví chi tiêu', () async {
      final fund = await newFund('Tiền KTX');
      await deposit(fund, 2000000);

      await repo.withdrawFromFund(
        fundId: fund,
        walletFromId: techcom,
        walletToId: momo,
        amount: 500000,
        occurredAt: DateTime(2026, 9, 15),
      );

      expect(await repo.savedInFund(fund), 1500000);
      expect(await repo.balanceOf(momo), 3500000);
      expect(await repo.watchSpendableAssets().first, 3500000,
          reason: 'rút ra thì tiền quay lại phần tiêu được');
    });
  });

  group('tiến độ quỹ', () {
    test('biết còn thiếu bao nhiêu mới đủ mục tiêu', () async {
      final fund = await newFund('Tiền KTX', target: 2000000);
      await deposit(fund, 1200000);

      final list = await repo.watchFunds().first;
      expect(list, hasLength(1));
      expect(list.first.saved, 1200000);
      expect(list.first.target, 2000000);
      expect(list.first.missing, 800000);
      expect(list.first.ratio, 0.6);
      expect(list.first.isComplete, isFalse);
      expect(list.first.walletName, 'Techcombank',
          reason: 'phải biết tiền đang nằm ở đâu');
    });

    test('đủ mục tiêu thì báo hoàn thành', () async {
      final fund = await newFund('Tiền điện', target: 500000);
      await deposit(fund, 500000);

      final f = (await repo.watchFunds().first).first;
      expect(f.isComplete, isTrue);
      expect(f.missing, 0);
      expect(f.ratio, 1.0);
    });

    test('quỹ không đặt mục tiêu thì không có phần thiếu', () async {
      final fund = await newFund('Để dành linh tinh');
      await deposit(fund, 100000);

      final f = (await repo.watchFunds().first).first;
      expect(f.hasTarget, isFalse);
      expect(f.missing, isNull);
      expect(f.saved, 100000);
    });
  });

  group('quản lý quỹ', () {
    test('quỹ lưu trữ không tính vào tổng quỹ nữa', () async {
      final fund = await newFund('Tiền KTX');
      await deposit(fund, 2000000);
      expect(await repo.watchTotalInFunds().first, 2000000);

      await repo.archiveFund(fund, archived: true);

      expect(await repo.watchTotalInFunds().first, 0);
      expect(await repo.watchSpendableAssets().first, 5000000,
          reason: 'tiền quay lại phần tiêu được');
      expect(await repo.watchFunds().first, isEmpty);
      expect(await repo.watchFunds(includeArchived: true).first, hasLength(1));
    });

    test('xoá quỹ thì giao dịch còn nguyên, chỉ mất nhãn quỹ', () async {
      final fund = await newFund('Tiền KTX');
      await deposit(fund, 2000000);

      await repo.deleteFund(fund);

      expect(await repo.watchFunds().first, isEmpty);
      expect(await repo.balanceOf(momo), 3000000,
          reason: 'tiền chưa bao giờ rời ví nên số dư không đổi');
      expect(await repo.balanceOf(techcom), 2000000);
      expect(await repo.watchTransactions().first, hasLength(1),
          reason: 'giao dịch chuyển ví vẫn còn');
      expect(await repo.watchTotalInFunds().first, 0);
    });

    test('không xoá được ví đang giữ quỹ', () async {
      await newFund('Tiền KTX');
      await expectLater(repo.deleteWallet(techcom), throwsA(anything));
    });

    test('xoá mềm giao dịch nạp quỹ thì quỹ giảm theo', () async {
      final fund = await newFund('Tiền KTX');
      final txId = await deposit(fund, 2000000);

      await repo.softDeleteTransaction(txId);
      expect(await repo.savedInFund(fund), 0);
      expect(await repo.watchSpendableAssets().first, 5000000);

      await repo.restoreTransaction(txId);
      expect(await repo.savedInFund(fund), 2000000);
    });
  });

  group('không có quỹ thì mọi thứ như cũ', () {
    test('chưa lập quỹ nào thì tiêu được bằng đúng tổng tài sản', () async {
      expect(await repo.watchTotalInFunds().first, 0);
      expect(
        await repo.watchSpendableAssets().first,
        await repo.watchTotalAssets().first,
      );
    });

    test('chuyển ví thường không dính dáng gì tới quỹ', () async {
      await repo.addTransaction(
        kind: TxKind.transfer,
        amount: 1000000,
        occurredAt: DateTime(2026, 9, 10),
        walletFromId: momo,
        walletToId: techcom,
      );
      expect(await repo.watchTotalInFunds().first, 0);
      expect(await repo.watchSpendableAssets().first, 5000000);
    });
  });
}
