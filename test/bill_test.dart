import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/bill.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/features/backup/backup_service.dart';

void main() {
  group('tính tổng hoá đơn', () {
    test('thành tiền = đơn giá × số lượng, giảm giá trừ đi', () {
      const lines = [
        BillLine(name: 'Sữa', quantity: 2, unitPrice: 30000),
        BillLine(name: 'Bánh mì', quantity: 1, unitPrice: 50000),
        BillLine(
          name: 'Giảm giá',
          quantity: 1,
          unitPrice: 10000,
          isDiscount: true,
        ),
      ];
      expect(lines[0].total, 60000);
      expect(lines[2].total, -10000);
      expect(billTotal(lines), 100000);
      expect(validateBill(lines), isNull);
    });

    test('thiếu tên, thiếu giá hay tổng không dương thì không ghi được', () {
      expect(
        validateBill(const [BillLine(name: ' ', quantity: 1, unitPrice: 1)]),
        isNotNull,
      );
      expect(
        validateBill(const [BillLine(name: 'Sữa', quantity: 1, unitPrice: 0)]),
        isNotNull,
      );
      expect(
        validateBill(const [BillLine(name: 'Sữa', quantity: 0, unitPrice: 5)]),
        isNotNull,
      );
      expect(
        validateBill(const [
          BillLine(name: 'Sữa', quantity: 1, unitPrice: 5000),
          BillLine(
            name: 'Giảm',
            quantity: 1,
            unitPrice: 5000,
            isDiscount: true,
          ),
        ]),
        isNotNull,
      );
    });
  });

  group('lưu hoá đơn', () {
    late AppDatabase db;
    late Repository repo;
    late int wallet;

    const bill = [
      BillLine(name: 'Sữa', quantity: 2, unitPrice: 30000),
      BillLine(name: 'Bánh mì', quantity: 1, unitPrice: 50000),
      BillLine(
        name: 'Giảm giá',
        quantity: 1,
        unitPrice: 10000,
        isDiscount: true,
      ),
    ];

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
    });

    tearDown(() async => db.close());

    Future<int> addWithBill() => repo.addTransaction(
      kind: TxKind.expense,
      amount: billTotal(bill),
      occurredAt: DateTime(2026, 10, 29, 10),
      walletFromId: wallet,
      bill: bill,
    );

    test(
      'ghi kèm hoá đơn: giữ đúng thứ tự các món, ví trừ đúng tổng',
      () async {
        final id = await addWithBill();
        final items = await repo.watchBill(id).first;
        expect(items.map((i) => i.name), ['Sữa', 'Bánh mì', 'Giảm giá']);
        expect(items[0].quantity, 2);
        expect(items[2].isDiscount, isTrue);
        expect(await repo.balanceOf(wallet), 900000);

        final view = (await repo.watchTransactions().first).single;
        expect(view.billCount, 3);
      },
    );

    test('số tiền không khớp tổng hoá đơn thì từ chối', () async {
      expect(
        () => repo.addTransaction(
          kind: TxKind.expense,
          amount: 90000,
          occurredAt: DateTime(2026, 10, 29),
          walletFromId: wallet,
          bill: bill,
        ),
        throwsArgumentError,
      );
      expect(await repo.watchTransactions().first, isEmpty);
    });

    test(
      'sửa giao dịch thì thay cả hoá đơn, danh sách rỗng là bỏ hoá đơn',
      () async {
        final id = await addWithBill();
        Future<void> update(List<BillLine> lines, int amount) =>
            repo.updateTransaction(
              id: id,
              kind: TxKind.expense,
              amount: amount,
              occurredAt: DateTime(2026, 10, 29, 10),
              walletFromId: wallet,
              bill: lines,
            );

        await update(const [
          BillLine(name: 'Trứng', quantity: 10, unitPrice: 4000),
        ], 40000);
        final items = await repo.watchBill(id).first;
        expect(items.map((i) => i.name), ['Trứng']);
        expect(await repo.balanceOf(wallet), 960000);

        await update(const [], 40000);
        expect(await repo.watchBill(id).first, isEmpty);
      },
    );

    test('xoá mềm rồi hoàn tác thì hoá đơn vẫn còn', () async {
      final id = await addWithBill();
      await repo.softDeleteTransaction(id);
      await repo.restoreTransaction(id);
      expect(await repo.watchBill(id).first, hasLength(3));
    });

    test('xoá hẳn giao dịch thì hoá đơn đi theo, không chặn xoá ví', () async {
      final id = await addWithBill();
      await repo.softDeleteTransaction(id);
      await repo.deleteWallet(wallet);
      final left = await db.select(db.billItems).get();
      expect(left, isEmpty);
    });

    test('sao lưu và nhập lại giữ nguyên hoá đơn', () async {
      final id = await addWithBill();
      final service = BackupService(db);
      final json = await service.buildJson();

      await service.import(json, mode: ImportMode.replace);
      final view = (await repo.watchTransactions().first).single;
      expect(view.tx.id, isNot(id), reason: 'id được cấp mới khi nhập');
      final items = await repo.watchBill(view.tx.id).first;
      expect(items.map((i) => i.name), ['Sữa', 'Bánh mì', 'Giảm giá']);
      expect(items.map((i) => i.unitPrice), [30000, 50000, 10000]);
      expect(items[2].isDiscount, isTrue);
    });
  });
}
