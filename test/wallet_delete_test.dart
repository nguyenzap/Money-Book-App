import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';

/// Ví chưa có giao dịch nào phải xoá được. Trước đây lệnh xoá thất bại trong
/// im lặng vì vướng khoá ngoại từ những dòng người dùng không nhìn thấy.
void main() {
  late AppDatabase db;
  late Repository repo;
  late int wallet;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    await db.customStatement('PRAGMA foreign_keys = ON');
    wallet = await repo.insertWallet(
      WalletsCompanion.insert(name: 'Ví mới', createdAt: 0, updatedAt: 0),
    );
  });

  tearDown(() async => db.close());

  Future<bool> exists() async =>
      (await (db.select(db.wallets)..where((w) => w.id.equals(wallet))).get())
          .isNotEmpty;

  test('ví mới tạo', () async {
    await repo.deleteWallet(wallet);
    expect(await exists(), isFalse);
  });

  test('ví chỉ có giao dịch đã xoá mềm', () async {
    final tx = await repo.addTransaction(
      kind: TxKind.income,
      amount: 1000,
      occurredAt: DateTime(2026, 9, 1),
      walletToId: wallet,
    );
    await repo.softDeleteTransaction(tx);
    expect(await repo.countTransactionsOfWallet(wallet), 0);
    await repo.deleteWallet(wallet);
    expect(await exists(), isFalse);
  });

  test('xoá hẳn giao dịch đã xoá mềm không làm lệch ví kia', () async {
    final other = await repo.insertWallet(
      WalletsCompanion.insert(name: 'Ví khác', createdAt: 0, updatedAt: 0),
    );
    final kept = await repo.addTransaction(
      kind: TxKind.income,
      amount: 5000,
      occurredAt: DateTime(2026, 9, 1),
      walletToId: other,
    );
    final tx = await repo.addTransaction(
      kind: TxKind.transfer,
      amount: 1000,
      occurredAt: DateTime(2026, 9, 1),
      walletFromId: other,
      walletToId: wallet,
    );
    await repo.softDeleteTransaction(tx);

    await repo.deleteWallet(wallet);
    expect(await exists(), isFalse);
    expect(await repo.balanceOf(other), 5000);
    expect(await repo.getTransaction(kept), isNotNull);
  });

  test('ví đang giữ quỹ thì bị chặn, màn hình biết trước để báo', () async {
    await repo.insertFund(
      FundsCompanion.insert(
        name: 'Quỹ',
        walletId: wallet,
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    expect(await repo.countTransactionsOfWallet(wallet), 0);
    expect(await repo.countFundsOfWallet(wallet), 1);
    await expectLater(repo.deleteWallet(wallet), throwsA(anything));
    expect(await exists(), isTrue);
  });
}
