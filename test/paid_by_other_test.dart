import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/core/format/dates.dart';
import 'package:moneybook/features/backup/backup_service.dart';

/// Người khác trả dùm: bạn trả tiền thay mình, mình tiêu mà ví không suy
/// suyển, chỉ nợ lại người đó. Ghi bằng đúng một khoản chi không có ví, có
/// người đi kèm.
void main() {
  late AppDatabase db;
  late Repository repo;
  late int wallet;
  late int category;
  late int nam;
  final when = DateTime(2026, 11, 8, 12);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    await db.customStatement('PRAGMA foreign_keys = ON');
    await db.delete(db.wallets).go();
    wallet = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        initialBalance: const Value(1000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    category = await repo.insertCategory(
      CategoriesCompanion.insert(
        name: 'Ăn uống',
        flow: 'expense',
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    nam = await repo.insertPerson(
      PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
    );
  });

  tearDown(() async => db.close());

  Future<int> paidByNam(int amount) => repo.addTransaction(
    kind: TxKind.expense,
    amount: amount,
    occurredAt: when,
    categoryId: category,
    personId: nam,
  );

  group('TxKind', () {
    test('chi tiêu có người đi kèm thì mình nợ người đó', () {
      expect(TxKind.expense.debtDelta(50000, hasPerson: true), -50000);
      expect(TxKind.expense.debtDelta(50000), 0);
    });

    test('chỉ chi tiêu mới có kiểu người khác trả dùm', () {
      expect(TxKind.expense.canBePaidByOther, isTrue);
      for (final k in TxKind.values.where((k) => k != TxKind.expense)) {
        expect(k.canBePaidByOther, isFalse, reason: k.name);
      }
    });

    test('các loại khác không đổi khi truyền hasPerson', () {
      for (final k in TxKind.values.where((k) => k != TxKind.expense)) {
        expect(
          k.debtDelta(100, hasPerson: true),
          k.debtDelta(100),
          reason: k.name,
        );
      }
    });
  });

  test('ví không suy suyển, mình nợ người đó', () async {
    await paidByNam(50000);
    expect(await repo.balanceOf(wallet), 1000000);
    expect(await repo.netDebtOf(nam), -50000);
    expect(await repo.watchTotalOwed().first, 50000);
  });

  test('vẫn tính vào chi tiêu của tháng và của danh mục', () async {
    await paidByNam(50000);
    final totals = await repo.watchMonthTotals(monthKeyOf(when)).first;
    expect(totals.expense, 50000);
    final byCat = await repo.watchCategoryTotals(monthKeyOf(when)).first;
    expect(byCat.single.total, 50000);
  });

  test('tiền tiêu được giảm ngay, tổng tài sản thì không', () async {
    final before = await repo.watchSpendableAssets().first;
    await paidByNam(50000);
    expect(await repo.watchSpendableAssets().first, before - 50000);
    expect(await repo.watchTotalAssets().first, 1000000);
  });

  test('trả nợ bằng giao dịch trả nợ thường thì về 0', () async {
    await paidByNam(50000);
    await repo.addTransaction(
      kind: TxKind.repay,
      amount: 50000,
      occurredAt: when,
      walletFromId: wallet,
      personId: nam,
    );
    expect(await repo.netDebtOf(nam), 0);
    expect(await repo.balanceOf(wallet), 950000);
  });

  test('không được vừa có người trả dùm vừa trừ ví hay quỹ', () async {
    expect(
      () => repo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: when,
        walletFromId: wallet,
        personId: nam,
      ),
      throwsArgumentError,
    );
  });

  test('sửa số tiền thì nợ đi theo; bỏ người thì hết nợ', () async {
    final id = await paidByNam(50000);
    await repo.updateTransaction(
      id: id,
      kind: TxKind.expense,
      amount: 80000,
      occurredAt: when,
      categoryId: category,
      personId: nam,
    );
    expect(await repo.netDebtOf(nam), -80000);

    // Hoá ra mình tự trả: thành khoản chi thường từ ví.
    await repo.updateTransaction(
      id: id,
      kind: TxKind.expense,
      amount: 80000,
      occurredAt: when,
      walletFromId: wallet,
      categoryId: category,
    );
    expect(await repo.netDebtOf(nam), 0);
    expect(await repo.balanceOf(wallet), 920000);
  });

  test('xoá mềm thì hết nợ, hoàn tác thì nợ lại', () async {
    final id = await paidByNam(50000);
    await repo.softDeleteTransaction(id);
    expect(await repo.netDebtOf(nam), 0);
    await repo.restoreTransaction(id);
    expect(await repo.netDebtOf(nam), -50000);
  });

  test('TxView: hiện là khoản chi, có dấu âm', () async {
    final id = await paidByNam(50000);
    final view = (await repo.getTransaction(id))!;
    expect(view.isPaidByOther, isTrue);
    expect(view.signedAmount, -50000);
  });

  test('sao lưu rồi khôi phục giữ nguyên nợ', () async {
    await paidByNam(50000);
    final json = await BackupService(db).buildJson();

    final fresh = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(fresh.close);
    await fresh.customStatement('PRAGMA foreign_keys = ON');
    await BackupService(fresh).import(json, mode: ImportMode.replace);
    final freshRepo = Repository(fresh);

    final people = await freshRepo.watchPeople().first;
    final restoredNam = people.firstWhere((p) => p.name == 'Nam');
    expect(await freshRepo.netDebtOf(restoredNam.id), -50000);
  });
}
