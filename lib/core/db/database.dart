import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../domain/tx_kind.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    People,
    Transactions,
    RecurringTemplates,
    Budgets,
    SettingsKv,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Dùng cho unit test: database nằm hoàn toàn trong bộ nhớ.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
          await _seed();
        },
        // Từ phiên bản 2 trở đi, mỗi lần đổi cấu trúc bảng phải thêm một nhánh
        // vào đây. Bỏ qua bước này thì app sẽ chết ngay khi mở trên máy đang có
        // dữ liệu cũ.
        onUpgrade: (m, from, to) async {},
        beforeOpen: (details) async {
          // SQLite mặc định TẮT ràng buộc khoá ngoại. Không bật thì mọi
          // `references(...)` ở trên đều vô tác dụng.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    // Index có điều kiện `WHERE deleted_at IS NULL`: bỏ qua các dòng đã xoá mềm
    // nên index nhỏ và nhanh hơn.
    const statements = [
      'CREATE INDEX IF NOT EXISTS ix_tx_month ON transactions(month_key, kind) '
          'WHERE deleted_at IS NULL',
      'CREATE INDEX IF NOT EXISTS ix_tx_day ON transactions(day_key) '
          'WHERE deleted_at IS NULL',
      'CREATE INDEX IF NOT EXISTS ix_tx_occurred ON transactions(occurred_at DESC) '
          'WHERE deleted_at IS NULL',
      'CREATE INDEX IF NOT EXISTS ix_tx_wfrom ON transactions(wallet_from_id) '
          'WHERE deleted_at IS NULL',
      'CREATE INDEX IF NOT EXISTS ix_tx_wto ON transactions(wallet_to_id) '
          'WHERE deleted_at IS NULL',
      'CREATE INDEX IF NOT EXISTS ix_tx_person ON transactions(person_id) '
          'WHERE deleted_at IS NULL',
      'CREATE INDEX IF NOT EXISTS ix_tx_category ON transactions(category_id, month_key) '
          'WHERE deleted_at IS NULL',
      'CREATE INDEX IF NOT EXISTS ix_tx_group ON transactions(group_id)',
      'CREATE INDEX IF NOT EXISTS ix_recurring_due ON recurring_templates(is_active, next_due_at)',
      'CREATE UNIQUE INDEX IF NOT EXISTS ux_budget ON budgets(category_id, month_key)',
    ];
    for (final sql in statements) {
      await customStatement(sql);
    }
  }

  /// Gieo sẵn một ít dữ liệu để màn hình đầu tiên không trống trơn.
  /// Tất cả đều sửa và xoá được.
  Future<void> _seed() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await into(wallets).insert(
      WalletsCompanion.insert(
        name: 'Tiền mặt',
        type: const Value('cash'),
        iconKey: const Value('cash'),
        colorValue: Value(0xFF4CAF50),
        sortOrder: const Value(0),
        createdAt: now,
        updatedAt: now,
      ),
    );

    const expenseSeeds = <(String, String)>[
      ('Ăn uống', 'food'),
      ('Đi lại', 'transport'),
      ('Nhà cửa', 'home'),
      ('Hoá đơn', 'bill'),
      ('Mua sắm', 'shopping'),
      ('Giải trí', 'fun'),
      ('Sức khoẻ', 'health'),
      ('Học tập', 'study'),
      ('Khác', 'other'),
    ];
    const incomeSeeds = <(String, String)>[
      ('Lương', 'salary'),
      ('Thưởng', 'bonus'),
      ('Được cho', 'gift'),
      ('Khác', 'other'),
    ];

    var order = 0;
    for (final (name, icon) in expenseSeeds) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: name,
          flow: 'expense',
          iconKey: Value(icon),
          sortOrder: Value(order++),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    order = 0;
    for (final (name, icon) in incomeSeeds) {
      await into(categories).insert(
        CategoriesCompanion.insert(
          name: name,
          flow: 'income',
          iconKey: Value(icon),
          sortOrder: Value(order++),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'moneybook.sqlite'));

    // Cần cho một số máy Android cũ, nếu không sqlite3 có thể không mở được
    // file tạm.
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

    return NativeDatabase.createInBackground(file);
  });
}
