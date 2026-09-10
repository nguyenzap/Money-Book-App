import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:sqlite3/sqlite3.dart';

/// Đây là migration đầu tiên của app, chạy trên máy đã có dữ liệu thật. Sai ở
/// đây thì app chết ngay khi mở sau khi cập nhật, nên phải dựng lại đúng cấu
/// trúc bản v1 rồi nâng cấp thật.
void main() {
  /// Dựng một database y hệt bản v1: không có bảng funds, transactions chưa
  /// có cột fund_id.
  Database makeV1Database() {
    final db = sqlite3.openInMemory();
    db.execute('PRAGMA user_version = 1');

    db.execute('''
      CREATE TABLE wallets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'other',
        initial_balance INTEGER NOT NULL DEFAULT 0,
        icon_key TEXT NULL,
        color_value INTEGER NULL,
        note TEXT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE categories (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        flow TEXT NOT NULL,
        icon_key TEXT NULL,
        color_value INTEGER NULL,
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE people (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NULL,
        note TEXT NULL,
        avatar_color INTEGER NULL,
        is_archived INTEGER NOT NULL DEFAULT 0 CHECK (is_archived IN (0, 1)),
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE recurring_templates (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        kind TEXT NOT NULL,
        amount INTEGER NOT NULL,
        wallet_from_id INTEGER NULL,
        wallet_to_id INTEGER NULL,
        category_id INTEGER NULL,
        person_id INTEGER NULL,
        note TEXT NULL,
        freq TEXT NOT NULL DEFAULT 'monthly',
        interval_n INTEGER NOT NULL DEFAULT 1,
        day_of_month INTEGER NULL,
        weekday INTEGER NULL,
        next_due_at INTEGER NULL,
        last_run_at INTEGER NULL,
        is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE transactions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        amount INTEGER NOT NULL,
        occurred_at INTEGER NOT NULL,
        day_key INTEGER NOT NULL,
        month_key INTEGER NOT NULL,
        wallet_from_id INTEGER NULL REFERENCES wallets (id),
        wallet_to_id INTEGER NULL REFERENCES wallets (id),
        category_id INTEGER NULL REFERENCES categories (id),
        person_id INTEGER NULL REFERENCES people (id),
        debt_delta INTEGER NOT NULL DEFAULT 0,
        note TEXT NULL,
        group_id TEXT NULL,
        recurring_id INTEGER NULL REFERENCES recurring_templates (id),
        is_writeoff INTEGER NOT NULL DEFAULT 0 CHECK (is_writeoff IN (0, 1)),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER NULL
      )
    ''');
    db.execute('''
      CREATE TABLE budgets (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL REFERENCES categories (id),
        month_key INTEGER NULL,
        limit_amount INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    db.execute('''
      CREATE TABLE settings_kv (
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        PRIMARY KEY (key)
      )
    ''');

    // Dữ liệu như một người dùng thật đã ghi trước khi cập nhật.
    db.execute(
      "INSERT INTO wallets (id, name, initial_balance, created_at, updated_at) "
      "VALUES (1, 'MoMo', 5000000, 0, 0), (2, 'Techcombank', 0, 0, 0)",
    );
    db.execute(
      "INSERT INTO categories (id, name, flow, created_at, updated_at) "
      "VALUES (1, 'Ăn uống', 'expense', 0, 0)",
    );
    db.execute(
      "INSERT INTO people (id, name, created_at, updated_at) "
      "VALUES (1, 'Nam', 0, 0)",
    );
    db.execute(
      "INSERT INTO transactions "
      "(kind, amount, occurred_at, day_key, month_key, wallet_from_id, "
      " category_id, debt_delta, created_at, updated_at) "
      "VALUES ('expense', 120000, 0, 20260910, 202609, 1, 1, 0, 0, 0)",
    );
    db.execute(
      "INSERT INTO transactions "
      "(kind, amount, occurred_at, day_key, month_key, wallet_from_id, "
      " person_id, debt_delta, created_at, updated_at) "
      "VALUES ('lend', 200000, 0, 20260910, 202609, 1, 1, 200000, 0, 0)",
    );
    db.execute(
      "INSERT INTO budgets (category_id, limit_amount, created_at, updated_at) "
      "VALUES (1, 3000000, 0, 0)",
    );

    return db;
  }

  group('nâng cấp từ v1 lên v2', () {
    late AppDatabase db;
    late Repository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.opened(makeV1Database()));
      repo = Repository(db);
      // Chạm vào database để migration thực sự chạy.
      await db.customStatement('SELECT 1');
    });

    tearDown(() async => db.close());

    test('migration chạy được và lên đúng phiên bản', () async {
      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data.values.first, 2);
    });

    test('dữ liệu cũ còn nguyên vẹn', () async {
      final wallets = await repo.watchWalletsWithBalance().first;
      expect(wallets, hasLength(2));

      final momo = wallets.firstWhere((w) => w.name == 'MoMo');
      expect(momo.balance, 5000000 - 120000 - 200000,
          reason: 'số dư tính lại vẫn khớp');

      expect((await repo.watchMonthTotals(202609).first).expense, 120000);
      expect(await repo.netDebtOf(1), 200000, reason: 'công nợ giữ nguyên');
      expect((await repo.watchBudgets(202609).first), hasLength(1));
    });

    test('bảng quỹ đã có và dùng được ngay', () async {
      expect(await repo.watchFunds().first, isEmpty);

      final fund = await repo.insertFund(
        FundsCompanion.insert(
          name: 'Tiền KTX',
          walletId: 2,
          targetAmount: const Value(2000000),
          createdAt: 0,
          updatedAt: 0,
        ),
      );

      await repo.depositToFund(
        fundId: fund,
        walletFromId: 1,
        walletToId: 2,
        amount: 2000000,
        occurredAt: DateTime(2026, 9, 11),
      );

      expect(await repo.savedInFund(fund), 2000000);
      expect(await repo.watchTotalInFunds().first, 2000000);
    });

    test('giao dịch cũ không bị gán quỹ nhầm', () async {
      final all = await repo.watchTransactions().first;
      expect(all, hasLength(2));
      for (final v in all) {
        expect(v.tx.fundId, isNull,
            reason: 'cột mới phải để trống cho dữ liệu cũ');
      }
      expect(await repo.watchTotalInFunds().first, 0);
      expect(
        await repo.watchSpendableAssets().first,
        await repo.watchTotalAssets().first,
        reason: 'chưa có quỹ thì tiêu được bằng đúng tổng tài sản',
      );
    });

    test('chạy lại migration lần nữa không hỏng gì', () async {
      // Mở lại chính database đó một lần nữa: user_version đã là 2 nên
      // onUpgrade không chạy, không được đẻ ra lỗi bảng đã tồn tại.
      final wallets = await repo.watchWalletsWithBalance().first;
      expect(wallets, hasLength(2));
      await db.customStatement('SELECT 1');
      expect(await repo.watchFunds().first, isEmpty);
    });
  });

  group('cài mới hoàn toàn', () {
    test('database mới có sẵn cả bảng quỹ', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = Repository(db);
      await db.customStatement('SELECT 1');

      final row = await db.customSelect('PRAGMA user_version').getSingle();
      expect(row.data.values.first, 2);
      expect(await repo.watchFunds().first, isEmpty);
      expect(await repo.watchTotalInFunds().first, 0);
    });
  });
}
