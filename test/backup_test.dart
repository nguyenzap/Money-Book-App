import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/features/backup/backup_service.dart';

/// Sao lưu là cách duy nhất cứu dữ liệu khi mất máy, nên phép thử quan trọng
/// nhất là: xuất ra, xoá sạch, nhập lại — mọi con số phải y hệt.
void main() {
  late AppDatabase source;
  late Repository sourceRepo;
  late BackupService sourceBackup;

  late int wallet;
  late int wallet2;
  late int catAnUong;
  late int nam;

  setUp(() async {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    sourceRepo = Repository(source);
    sourceBackup = BackupService(source);
    await source.customStatement('PRAGMA foreign_keys = ON');
    // Dọn dữ liệu gieo sẵn để các phép đếm dưới đây nói về đúng dữ liệu
    // của bài kiểm tra.
    await source.delete(source.wallets).go();
    await source.delete(source.categories).go();

    wallet = await sourceRepo.insertWallet(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        initialBalance: const Value(1000000),
        iconKey: const Value('cash'),
        colorValue: const Value(0xFF4CAF50),
        createdAt: 100,
        updatedAt: 100,
      ),
    );
    wallet2 = await sourceRepo.insertWallet(
      WalletsCompanion.insert(
        name: 'MoMo',
        initialBalance: const Value(2000000),
        createdAt: 100,
        updatedAt: 100,
      ),
    );
    catAnUong = await sourceRepo.insertCategory(
      CategoriesCompanion.insert(
        name: 'Ăn uống',
        flow: 'expense',
        createdAt: 100,
        updatedAt: 100,
      ),
    );
    nam = await sourceRepo.insertPerson(
      PeopleCompanion.insert(name: 'Nam', createdAt: 100, updatedAt: 100),
    );
  });

  tearDown(() async => source.close());

  /// Nạp chuỗi JSON vào một database trắng, như khi cài lại app.
  Future<Repository> restoreToFreshDb(
    String json, {
    ImportMode mode = ImportMode.replace,
  }) async {
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(target.close);
    await target.customStatement('PRAGMA foreign_keys = ON');
    // Database mới luôn có sẵn dữ liệu gieo ban đầu, giống hệt lúc cài lại
    // app; chế độ ghi đè phải dọn sạch chúng trước khi nạp file.
    await BackupService(target).import(json, mode: mode);
    return Repository(target);
  }

  group('xuất rồi nhập lại', () {
    test('số dư ví giữ nguyên', () async {
      await sourceRepo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime(2026, 9, 6, 12, 0),
        walletFromId: wallet,
        categoryId: catAnUong,
        note: 'Ăn trưa',
      );

      final before = await sourceRepo.balanceOf(wallet);
      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);

      final wallets = await restored.watchWalletsWithBalance().first;
      final cash = wallets.firstWhere((w) => w.name == 'Tiền mặt');
      expect(cash.balance, before);
      expect(before, 950000);
    });

    test('tổng tài sản giữ nguyên', () async {
      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);
      expect(await restored.watchTotalAssets().first, 3000000);
    });

    test('công nợ giữ nguyên', () async {
      await sourceRepo.addTransaction(
        kind: TxKind.lend,
        amount: 200000,
        occurredAt: DateTime(2026, 9, 6),
        walletFromId: wallet,
        personId: nam,
      );

      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);

      final debts = await restored.watchDebts().first;
      expect(debts, hasLength(1));
      expect(debts.first.person.name, 'Nam');
      expect(debts.first.net, 200000);
    });

    test('thống kê tháng giữ nguyên', () async {
      await sourceRepo.addTransaction(
        kind: TxKind.expense,
        amount: 120000,
        occurredAt: DateTime(2026, 9, 10),
        walletFromId: wallet,
        categoryId: catAnUong,
      );
      await sourceRepo.addTransaction(
        kind: TxKind.income,
        amount: 5000000,
        occurredAt: DateTime(2026, 9, 1),
        walletToId: wallet,
        categoryId: catAnUong,
      );

      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);

      final totals = await restored.watchMonthTotals(202609).first;
      expect(totals.expense, 120000);
      expect(totals.income, 5000000);
    });

    test('ngân sách và tiến độ giữ nguyên', () async {
      await sourceRepo.setBudget(
        categoryId: catAnUong,
        limitAmount: 1000000,
      );
      await sourceRepo.addTransaction(
        kind: TxKind.expense,
        amount: 300000,
        occurredAt: DateTime(2026, 9, 10),
        walletFromId: wallet,
        categoryId: catAnUong,
      );

      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);

      final budgets = await restored.watchBudgets(202609).first;
      expect(budgets, hasLength(1));
      expect(budgets.first.limitAmount, 1000000);
      expect(budgets.first.spent, 300000);
    });

    test('cả nhóm trả dùm được giữ nguyên vẹn', () async {
      final hung = await sourceRepo.insertPerson(
        PeopleCompanion.insert(name: 'Hùng', createdAt: 0, updatedAt: 0),
      );
      await sourceRepo.addSplitBill(
        walletFromId: wallet,
        myShare: 50000,
        sharesByPerson: {nam: 50000, hung: 50000},
        occurredAt: DateTime(2026, 9, 6),
        categoryId: catAnUong,
        note: 'Ăn lẩu',
      );

      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);

      final all = await restored.watchTransactions().first;
      expect(all, hasLength(3));

      final groups = all.map((v) => v.tx.groupId).toSet();
      expect(groups, hasLength(1), reason: 'vẫn là một nhóm');
      expect(await restored.countInGroup(groups.first!), 3);

      // Và quan trọng nhất: vẫn chỉ tính phần của mình.
      expect((await restored.watchMonthTotals(202609).first).expense, 50000);
    });

    test('giao dịch đã xoá mềm vẫn giữ trạng thái đã xoá', () async {
      final id = await sourceRepo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime(2026, 9, 6),
        walletFromId: wallet,
        categoryId: catAnUong,
      );
      await sourceRepo.softDeleteTransaction(id);

      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);

      expect(await restored.watchTransactions().first, isEmpty);
      expect(await restored.balanceOf(
        (await restored.watchWalletsWithBalance().first)
            .firstWhere((w) => w.name == 'Tiền mặt')
            .id,
      ), 1000000);
    });

    test('ví lưu trữ vẫn ở trạng thái lưu trữ', () async {
      await sourceRepo.archiveWallet(wallet2, archived: true);

      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);

      final visible = await restored.watchWalletsWithBalance().first;
      final all =
          await restored.watchWalletsWithBalance(includeArchived: true).first;
      expect(visible, hasLength(1));
      expect(all, hasLength(2));
    });

    test('màu và biểu tượng giữ nguyên', () async {
      final json = await sourceBackup.buildJson();
      final restored = await restoreToFreshDb(json);

      final cash = (await restored.watchWalletsWithBalance().first)
          .firstWhere((w) => w.name == 'Tiền mặt');
      expect(cash.wallet.iconKey, 'cash');
      expect(cash.wallet.colorValue, 0xFF4CAF50);
    });
  });

  group('chế độ nhập', () {
    test('ghi đè thì xoá sạch dữ liệu cũ', () async {
      final json = await sourceBackup.buildJson();

      // Máy đích đã có sẵn một ví khác.
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(target.close);
      await target.customStatement('PRAGMA foreign_keys = ON');
      await target.delete(target.wallets).go();
      await target.delete(target.categories).go();
      final targetRepo = Repository(target);
      await targetRepo.insertWallet(
        WalletsCompanion.insert(
          name: 'Ví cũ',
          initialBalance: const Value(999),
          createdAt: 0,
          updatedAt: 0,
        ),
      );

      await BackupService(target).import(json, mode: ImportMode.replace);

      final wallets = await targetRepo.watchWalletsWithBalance().first;
      expect(wallets.map((w) => w.name), isNot(contains('Ví cũ')));
      expect(wallets, hasLength(2));
      expect(await targetRepo.watchTotalAssets().first, 3000000);
    });

    test('gộp thì giữ cả dữ liệu cũ lẫn mới', () async {
      final json = await sourceBackup.buildJson();

      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(target.close);
      await target.customStatement('PRAGMA foreign_keys = ON');
      await target.delete(target.wallets).go();
      await target.delete(target.categories).go();
      final targetRepo = Repository(target);
      await targetRepo.insertWallet(
        WalletsCompanion.insert(
          name: 'Ví cũ',
          initialBalance: const Value(500000),
          createdAt: 0,
          updatedAt: 0,
        ),
      );

      await BackupService(target).import(json, mode: ImportMode.merge);

      final wallets = await targetRepo.watchWalletsWithBalance().first;
      expect(wallets.map((w) => w.name), contains('Ví cũ'));
      expect(wallets, hasLength(3));
      expect(await targetRepo.watchTotalAssets().first, 3500000);
    });

    test('gộp không làm hỏng liên kết giao dịch với ví', () async {
      await sourceRepo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime(2026, 9, 6),
        walletFromId: wallet,
        categoryId: catAnUong,
      );
      final json = await sourceBackup.buildJson();

      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(target.close);
      await target.customStatement('PRAGMA foreign_keys = ON');
      await target.delete(target.wallets).go();
      await target.delete(target.categories).go();
      final targetRepo = Repository(target);
      // Chiếm sẵn id 1, 2, 3 để id trong file chắc chắn đụng độ.
      for (var i = 0; i < 3; i++) {
        await targetRepo.insertWallet(
          WalletsCompanion.insert(
            name: 'Ví $i',
            createdAt: 0,
            updatedAt: 0,
          ),
        );
      }

      await BackupService(target).import(json, mode: ImportMode.merge);

      final cash = (await targetRepo.watchWalletsWithBalance().first)
          .firstWhere((w) => w.name == 'Tiền mặt');
      expect(cash.balance, 950000,
          reason: 'giao dịch phải trỏ đúng ví mới, không phải ví trùng id');
    });
  });

  group('từ chối file hỏng', () {
    test('chuỗi không phải JSON', () async {
      expect(
        () => sourceBackup.import('không phải json', mode: ImportMode.replace),
        throwsA(isA<BackupException>()),
      );
    });

    test('JSON của app khác', () async {
      expect(
        () => sourceBackup.import(
          '{"app":"SomethingElse","formatVersion":1}',
          mode: ImportMode.replace,
        ),
        throwsA(isA<BackupException>()),
      );
    });

    test('file từ phiên bản app mới hơn', () async {
      expect(
        () => sourceBackup.import(
          '{"app":"MoneyBook","formatVersion":999,"wallets":[],'
          '"categories":[],"people":[],"transactions":[]}',
          mode: ImportMode.replace,
        ),
        throwsA(isA<BackupException>()),
      );
    });

    test('thiếu bảng dữ liệu', () async {
      expect(
        () => sourceBackup.import(
          '{"app":"MoneyBook","formatVersion":1,"wallets":[]}',
          mode: ImportMode.replace,
        ),
        throwsA(isA<BackupException>()),
      );
    });

    test('file hỏng không làm mất dữ liệu đang có', () async {
      final before = await sourceRepo.watchTotalAssets().first;
      try {
        await sourceBackup.import('rác', mode: ImportMode.replace);
      } catch (_) {
        // mong đợi
      }
      expect(await sourceRepo.watchTotalAssets().first, before);
    });
  });

  group('xem trước', () {
    test('đếm đúng số bản ghi trước khi nhập', () async {
      await sourceRepo.addTransaction(
        kind: TxKind.expense,
        amount: 50000,
        occurredAt: DateTime(2026, 9, 6),
        walletFromId: wallet,
        categoryId: catAnUong,
      );
      await sourceRepo.setBudget(categoryId: catAnUong, limitAmount: 500000);

      final stats = await sourceBackup.peek(await sourceBackup.buildJson());
      expect(stats.wallets, 2);
      expect(stats.categories, 1);
      expect(stats.people, 1);
      expect(stats.transactions, 1);
      expect(stats.budgets, 1);
    });
  });

  group('định dạng file', () {
    test('có đủ thông tin nhận dạng và phiên bản', () async {
      final json = await sourceBackup.buildJson();
      expect(json, contains('"app": "MoneyBook"'));
      expect(json, contains('"formatVersion": $kBackupFormatVersion'));
      expect(json, contains('"exportedAt"'));
    });

    test('loại giao dịch lưu bằng tên chữ, không phải số thứ tự', () async {
      await sourceRepo.addTransaction(
        kind: TxKind.lend,
        amount: 1000,
        occurredAt: DateTime(2026, 9, 6),
        walletFromId: wallet,
        personId: nam,
      );
      final json = await sourceBackup.buildJson();
      expect(json, contains('"kind": "lend"'),
          reason: 'đổi thứ tự enum sau này không được làm hỏng file cũ');
    });
  });
}
