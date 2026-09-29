import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/core/format/dates.dart';
import 'package:moneybook/features/backup/backup_service.dart';

/// Mẫu chi tiêu: lưu một lần, bấm một chạm là ghi xong, thời điểm là lúc bấm.
void main() {
  late AppDatabase db;
  late Repository repo;
  late int momo;
  late int catCafe;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    await db.customStatement('PRAGMA foreign_keys = ON');
    await db.delete(db.wallets).go();
    await db.delete(db.categories).go();

    momo = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'MoMo',
        initialBalance: const Value(1000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    catCafe = await repo.insertCategory(
      CategoriesCompanion.insert(
        name: 'Cà phê',
        flow: 'expense',
        createdAt: 0,
        updatedAt: 0,
      ),
    );
  });

  tearDown(() async => db.close());

  Future<TemplateView> only() async =>
      (await repo.watchTemplates().first).single;

  group('ghi một chạm', () {
    test('ghi đúng một khoản chi, trừ đúng ví, thời điểm là lúc bấm', () async {
      final id = await repo.insertTemplate(
        note: 'Cà phê sáng',
        amount: 25000,
        walletId: momo,
        categoryId: catCafe,
      );

      // 23h50 ngày cuối tháng: khoá tháng phải theo giờ địa phương.
      final at = DateTime(2026, 9, 30, 23, 50);
      final txId = await repo.recordFromTemplate(id, occurredAt: at);
      expect(txId, isNotNull);

      final tx = (await repo.getTransaction(txId!))!.tx;
      expect(tx.kind, TxKind.expense);
      expect(tx.amount, 25000);
      expect(tx.walletFromId, momo);
      expect(tx.walletToId, isNull);
      expect(tx.categoryId, catCafe);
      expect(tx.note, 'Cà phê sáng');
      expect(tx.occurredAt, at.millisecondsSinceEpoch);
      expect(tx.dayKey, dayKeyOf(at));
      expect(tx.monthKey, 202609);

      expect(await repo.balanceOf(momo), 1000000 - 25000);
      expect((await repo.watchMonthTotals(202609).first).expense, 25000);
    });

    test('bấm hai lần là hai khoản riêng', () async {
      final id = await repo.insertTemplate(
        amount: 5000,
        walletId: momo,
        categoryId: catCafe,
      );
      await repo.recordFromTemplate(id, occurredAt: DateTime(2026, 9, 10, 8));
      await repo.recordFromTemplate(id, occurredAt: DateTime(2026, 9, 10, 18));

      expect(await repo.watchTransactions().first, hasLength(2));
      expect(await repo.balanceOf(momo), 1000000 - 10000);
    });

    test(
      'không có ghi chú thì khoản chi không có ghi chú, mẫu mang tên danh mục',
      () async {
        final id = await repo.insertTemplate(
          note: '   ',
          amount: 5000,
          walletId: momo,
          categoryId: catCafe,
        );
        expect((await only()).label, 'Cà phê');

        final txId = await repo.recordFromTemplate(
          id,
          occurredAt: DateTime(2026, 9, 10),
        );
        expect((await repo.getTransaction(txId!))!.tx.note, isNull);
      },
    );
  });

  group('mẫu thiếu trường thì không ghi bừa', () {
    test('thiếu số tiền', () async {
      final id = await repo.insertTemplate(
        note: 'Đổ xăng',
        walletId: momo,
        categoryId: catCafe,
      );
      expect((await only()).isOneTap, isFalse);
      expect(
        await repo.recordFromTemplate(id, occurredAt: DateTime(2026, 9, 10)),
        isNull,
      );
      expect(await repo.watchTransactions().first, isEmpty);
    });

    test('thiếu ví hoặc danh mục', () async {
      final a = await repo.insertTemplate(amount: 5000, categoryId: catCafe);
      final b = await repo.insertTemplate(
        note: 'Gửi xe',
        amount: 5000,
        walletId: momo,
      );
      expect(
        await repo.recordFromTemplate(a, occurredAt: DateTime(2026, 9, 10)),
        isNull,
      );
      expect(
        await repo.recordFromTemplate(b, occurredAt: DateTime(2026, 9, 10)),
        isNull,
      );
      expect(await repo.watchTransactions().first, isEmpty);
    });

    test('ví đã lưu trữ thì không ghi thẳng vào nữa', () async {
      final id = await repo.insertTemplate(
        amount: 5000,
        walletId: momo,
        categoryId: catCafe,
      );
      await repo.archiveWallet(momo, archived: true);

      final t = await only();
      expect(t.hasWallet, isFalse);
      expect(t.isOneTap, isFalse);
      expect(
        await repo.recordFromTemplate(id, occurredAt: DateTime(2026, 9, 10)),
        isNull,
      );
    });

    test('mẫu đã xoá', () async {
      final id = await repo.insertTemplate(
        amount: 5000,
        walletId: momo,
        categoryId: catCafe,
      );
      await repo.deleteTemplate(id);
      expect(
        await repo.recordFromTemplate(id, occurredAt: DateTime(2026, 9, 10)),
        isNull,
      );
    });
  });

  group('xoá thứ mà mẫu trỏ tới', () {
    test('xoá danh mục: mẫu còn, chỉ mất danh mục', () async {
      await repo.insertTemplate(
        note: 'Cà phê',
        amount: 5000,
        walletId: momo,
        categoryId: catCafe,
      );
      await repo.deleteCategory(catCafe);

      final t = await only();
      expect(t.template.categoryId, isNull);
      expect(t.template.walletId, momo);
      expect(t.isOneTap, isFalse);
    });

    test('xoá ví chưa dùng: không vướng khoá ngoại, mẫu chỉ mất ví', () async {
      final spare = await repo.insertWallet(
        WalletsCompanion.insert(name: 'Ví phụ', createdAt: 0, updatedAt: 0),
      );
      await repo.insertTemplate(
        amount: 5000,
        walletId: spare,
        categoryId: catCafe,
      );
      await repo.deleteWallet(spare);

      final t = await only();
      expect(t.template.walletId, isNull);
      expect(t.template.categoryId, catCafe);
    });
  });

  test('sửa mẫu và đổi thứ tự', () async {
    final a = await repo.insertTemplate(note: 'A', amount: 1000);
    final b = await repo.insertTemplate(note: 'B', amount: 2000);
    expect((await repo.watchTemplates().first).map((t) => t.label), ['A', 'B']);

    await repo.reorderTemplates([b, a]);
    expect((await repo.watchTemplates().first).map((t) => t.label), ['B', 'A']);

    await repo.updateTemplate(id: a, note: 'A2', amount: null, walletId: momo);
    final updated = await repo.getTemplate(a);
    expect(updated!.label, 'A2');
    expect(updated.amount, isNull);
    expect(updated.template.walletId, momo);
  });

  test('sao lưu mang theo mẫu, ánh xạ đúng ví và danh mục mới', () async {
    await repo.insertTemplate(
      note: 'Cà phê sáng',
      amount: 25000,
      walletId: momo,
      categoryId: catCafe,
    );
    final json = await BackupService(db).buildJson();

    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(target.close);
    await target.customStatement('PRAGMA foreign_keys = ON');
    // Gộp vào database có sẵn dữ liệu gieo để id chắc chắn lệch với file.
    await BackupService(target).import(json, mode: ImportMode.merge);
    final targetRepo = Repository(target);

    final t = (await targetRepo.watchTemplates().first).single;
    expect(t.label, 'Cà phê sáng');
    expect(t.walletName, 'MoMo');
    expect(t.categoryName, 'Cà phê');
    expect(t.isOneTap, isTrue);
  });
}
