import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/db/database.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/dates.dart';

/// Phiên bản định dạng file sao lưu.
///
/// Tăng lên mỗi khi cấu trúc file đổi, để bản app cũ biết mà từ chối file mới
/// thay vì đọc bừa rồi hỏng dữ liệu.
const kBackupFormatVersion = 3;

class BackupStats {
  const BackupStats({
    required this.wallets,
    required this.categories,
    required this.people,
    required this.transactions,
    required this.budgets,
    required this.funds,
    this.templates = 0,
  });

  final int wallets;
  final int categories;
  final int people;
  final int transactions;
  final int budgets;
  final int funds;
  final int templates;

  int get total =>
      wallets +
      categories +
      people +
      transactions +
      budgets +
      funds +
      templates;
}

/// Cách xử lý khi nhập một file sao lưu.
enum ImportMode {
  /// Xoá sạch dữ liệu hiện có rồi nạp file vào.
  replace,

  /// Giữ dữ liệu cũ, thêm dữ liệu trong file vào.
  merge,
}

class ImportResult {
  const ImportResult({required this.stats, required this.mode});
  final BackupStats stats;
  final ImportMode mode;
}

/// Xuất và nhập toàn bộ dữ liệu dưới dạng file.
///
/// Đây là cách sao lưu duy nhất của app: không có máy chủ nào giữ hộ, nên file
/// này là thứ cứu được dữ liệu khi mất máy hoặc gỡ nhầm app.
class BackupService {
  BackupService(this.db);

  final AppDatabase db;

  // ----- Xuất ----------------------------------------------------------

  /// Dựng nội dung file sao lưu dạng JSON.
  Future<String> buildJson() async {
    final wallets = await db.select(db.wallets).get();
    final categories = await db.select(db.categories).get();
    final people = await db.select(db.people).get();
    final transactions = await db.select(db.transactions).get();
    final budgets = await db.select(db.budgets).get();
    final funds = await db.select(db.funds).get();
    final templates = await db.select(db.expenseTemplates).get();

    final data = <String, dynamic>{
      'formatVersion': kBackupFormatVersion,
      'schemaVersion': db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'MoneyBook',
      'wallets': wallets.map(_walletToMap).toList(),
      'categories': categories.map(_categoryToMap).toList(),
      'people': people.map(_personToMap).toList(),
      'transactions': transactions.map(_transactionToMap).toList(),
      'budgets': budgets.map(_budgetToMap).toList(),
      'funds': funds.map(_fundToMap).toList(),
      'templates': templates.map(_templateToMap).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Ghi file JSON vào thư mục tạm và trả về đường dẫn để chia sẻ.
  Future<File> writeJsonFile() async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final name =
        'moneybook_${dayKeyOf(now)}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}.json';
    final file = File(p.join(dir.path, name));
    await file.writeAsString(await buildJson(), encoding: utf8);
    return file;
  }

  /// Xuất bảng giao dịch dạng CSV để mở bằng Excel.
  ///
  /// Ghi kèm BOM ở đầu file, nếu không Excel trên Windows sẽ đọc UTF-8 thành
  /// ký tự rác và toàn bộ tiếng Việt bị vỡ.
  Future<File> writeCsvFile() async {
    final wallets = {
      for (final w in await db.select(db.wallets).get()) w.id: w.name,
    };
    final categories = {
      for (final c in await db.select(db.categories).get()) c.id: c.name,
    };
    final people = {
      for (final p in await db.select(db.people).get()) p.id: p.name,
    };

    final query = db.select(db.transactions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
      ]);
    final transactions = await query.get();

    final rows = <List<dynamic>>[
      [
        'Ngày',
        'Giờ',
        'Loại',
        'Số tiền',
        'Ví chi',
        'Ví nhận',
        'Danh mục',
        'Người',
        'Ảnh hưởng công nợ',
        'Ghi chú',
      ],
      for (final t in transactions)
        [
          formatDate(DateTime.fromMillisecondsSinceEpoch(t.occurredAt)),
          formatTime(DateTime.fromMillisecondsSinceEpoch(t.occurredAt)),
          t.kind.label,
          t.amount,
          t.walletFromId == null ? '' : wallets[t.walletFromId] ?? '',
          t.walletToId == null ? '' : wallets[t.walletToId] ?? '',
          t.categoryId == null ? '' : categories[t.categoryId] ?? '',
          t.personId == null ? '' : people[t.personId] ?? '',
          t.debtDelta,
          t.note ?? '',
        ],
    ];

    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(dir.path, 'moneybook_${dayKeyOf(DateTime.now())}.csv'),
    );
    const bom = '﻿';
    await file.writeAsString(
      bom + const ListToCsvConverter().convert(rows),
      encoding: utf8,
    );
    return file;
  }

  // ----- Nhập ----------------------------------------------------------

  /// Đọc thử file để xem có bao nhiêu dữ liệu, trước khi thực sự nhập.
  Future<BackupStats> peek(String jsonString) async {
    final data = _decodeAndValidate(jsonString);
    return BackupStats(
      wallets: (data['wallets'] as List).length,
      categories: (data['categories'] as List).length,
      people: (data['people'] as List).length,
      transactions: (data['transactions'] as List).length,
      budgets: (data['budgets'] as List?)?.length ?? 0,
      funds: (data['funds'] as List?)?.length ?? 0,
      templates: (data['templates'] as List?)?.length ?? 0,
    );
  }

  /// Nạp dữ liệu từ file sao lưu.
  ///
  /// Chạy trọn trong một giao dịch cơ sở dữ liệu: lỗi giữa chừng thì mọi thứ
  /// quay lại như cũ, không để lại dữ liệu dở dang.
  ///
  /// Id trong file không được dùng lại mà ánh xạ sang id mới, vì ở chế độ gộp
  /// chúng gần như chắc chắn đụng với id đang có.
  Future<ImportResult> import(
    String jsonString, {
    required ImportMode mode,
  }) async {
    final data = _decodeAndValidate(jsonString);

    final walletRows = (data['wallets'] as List).cast<Map<String, dynamic>>();
    final categoryRows = (data['categories'] as List)
        .cast<Map<String, dynamic>>();
    final peopleRows = (data['people'] as List).cast<Map<String, dynamic>>();
    final txRows = (data['transactions'] as List).cast<Map<String, dynamic>>();
    final budgetRows = ((data['budgets'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final fundRows = ((data['funds'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final templateRows = ((data['templates'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();

    await db.transaction(() async {
      if (mode == ImportMode.replace) {
        // Xoá theo thứ tự ngược với phụ thuộc khoá ngoại.
        await db.delete(db.transactions).go();
        await db.delete(db.budgets).go();
        await db.delete(db.funds).go();
        await db.delete(db.expenseTemplates).go();
        await db.delete(db.wallets).go();
        await db.delete(db.categories).go();
        await db.delete(db.people).go();
      }

      final walletIds = <int, int>{};
      for (final row in walletRows) {
        walletIds[row['id'] as int] = await db
            .into(db.wallets)
            .insert(
              WalletsCompanion.insert(
                name: row['name'] as String,
                type: Value(row['type'] as String? ?? 'other'),
                initialBalance: Value(row['initialBalance'] as int? ?? 0),
                iconKey: Value(row['iconKey'] as String?),
                colorValue: Value(row['colorValue'] as int?),
                note: Value(row['note'] as String?),
                isArchived: Value(row['isArchived'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      final categoryIds = <int, int>{};
      for (final row in categoryRows) {
        categoryIds[row['id'] as int] = await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                name: row['name'] as String,
                flow: row['flow'] as String,
                iconKey: Value(row['iconKey'] as String?),
                colorValue: Value(row['colorValue'] as int?),
                isArchived: Value(row['isArchived'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      final personIds = <int, int>{};
      for (final row in peopleRows) {
        personIds[row['id'] as int] = await db
            .into(db.people)
            .insert(
              PeopleCompanion.insert(
                name: row['name'] as String,
                phone: Value(row['phone'] as String?),
                note: Value(row['note'] as String?),
                avatarColor: Value(row['avatarColor'] as int?),
                isArchived: Value(row['isArchived'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      final fundIds = <int, int>{};
      for (final row in fundRows) {
        final walletId = walletIds[row['walletId']];
        if (walletId == null) continue;
        fundIds[row['id'] as int] = await db
            .into(db.funds)
            .insert(
              FundsCompanion.insert(
                name: row['name'] as String,
                walletId: walletId,
                targetAmount: Value(row['targetAmount'] as int?),
                dueDayKey: Value(row['dueDayKey'] as int?),
                note: Value(row['note'] as String?),
                iconKey: Value(row['iconKey'] as String?),
                colorValue: Value(row['colorValue'] as int?),
                isArchived: Value(row['isArchived'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      for (final row in txRows) {
        final kind = TxKindX.fromId(row['kind'] as String);
        final amount = row['amount'] as int;
        final occurredAt = row['occurredAt'] as int;
        final local = DateTime.fromMillisecondsSinceEpoch(occurredAt);

        await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                kind: kind,
                amount: amount,
                occurredAt: occurredAt,
                // Tính lại từ thời điểm thay vì tin vào file: nếu máy nguồn ở
                // múi giờ khác thì khoá tháng cũ sẽ sai với máy này.
                dayKey: dayKeyOf(local),
                monthKey: monthKeyOf(local),
                walletFromId: Value(walletIds[row['walletFromId']]),
                walletToId: Value(walletIds[row['walletToId']]),
                categoryId: Value(categoryIds[row['categoryId']]),
                personId: Value(personIds[row['personId']]),
                fundId: Value(fundIds[row['fundId']]),
                // Tính lại từ kind, không tin số trong file.
                debtDelta: Value(kind.debtDelta(amount)),
                note: Value(row['note'] as String?),
                groupId: Value(row['groupId'] as String?),
                isWriteoff: Value(row['isWriteoff'] as bool? ?? false),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
                deletedAt: Value(row['deletedAt'] as int?),
              ),
            );
      }

      for (final row in budgetRows) {
        final categoryId = categoryIds[row['categoryId']];
        if (categoryId == null) continue;
        await db
            .into(db.budgets)
            .insert(
              BudgetsCompanion.insert(
                categoryId: categoryId,
                monthKey: Value(row['monthKey'] as int?),
                limitAmount: row['limitAmount'] as int,
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      for (final row in templateRows) {
        final amount = row['amount'] as int?;
        await db
            .into(db.expenseTemplates)
            .insert(
              ExpenseTemplatesCompanion.insert(
                note: Value(row['note'] as String?),
                // Không tin số âm hay bằng 0 trong file: mẫu chỉ có số dương
                // hoặc để trống.
                amount: Value(amount != null && amount > 0 ? amount : null),
                walletId: Value(walletIds[row['walletId']]),
                categoryId: Value(categoryIds[row['categoryId']]),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }
    });

    return ImportResult(
      mode: mode,
      stats: BackupStats(
        wallets: walletRows.length,
        categories: categoryRows.length,
        people: peopleRows.length,
        transactions: txRows.length,
        budgets: budgetRows.length,
        funds: fundRows.length,
        templates: templateRows.length,
      ),
    );
  }

  Map<String, dynamic> _decodeAndValidate(String jsonString) {
    late final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      throw const BackupException(
        'File không đọc được. Hãy chọn đúng file .json do app này xuất ra.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('File sao lưu không đúng định dạng.');
    }
    if (decoded['app'] != 'MoneyBook') {
      throw const BackupException(
        'File này không phải bản sao lưu của Quản Lý Chi Tiêu.',
      );
    }

    final version = decoded['formatVersion'];
    if (version is! int) {
      throw const BackupException('File sao lưu thiếu thông tin phiên bản.');
    }
    if (version > kBackupFormatVersion) {
      throw BackupException(
        'File này được tạo bởi phiên bản app mới hơn (v$version). '
        'Hãy cập nhật app rồi thử lại.',
      );
    }

    for (final key in ['wallets', 'categories', 'people', 'transactions']) {
      if (decoded[key] is! List) {
        throw BackupException('File sao lưu thiếu phần "$key".');
      }
    }

    return decoded;
  }

  Map<String, dynamic> _walletToMap(Wallet w) => {
    'id': w.id,
    'name': w.name,
    'type': w.type,
    'initialBalance': w.initialBalance,
    'iconKey': w.iconKey,
    'colorValue': w.colorValue,
    'note': w.note,
    'isArchived': w.isArchived,
    'sortOrder': w.sortOrder,
    'createdAt': w.createdAt,
    'updatedAt': w.updatedAt,
  };

  Map<String, dynamic> _categoryToMap(Category c) => {
    'id': c.id,
    'name': c.name,
    'flow': c.flow,
    'iconKey': c.iconKey,
    'colorValue': c.colorValue,
    'isArchived': c.isArchived,
    'sortOrder': c.sortOrder,
    'createdAt': c.createdAt,
    'updatedAt': c.updatedAt,
  };

  Map<String, dynamic> _personToMap(Person p) => {
    'id': p.id,
    'name': p.name,
    'phone': p.phone,
    'note': p.note,
    'avatarColor': p.avatarColor,
    'isArchived': p.isArchived,
    'sortOrder': p.sortOrder,
    'createdAt': p.createdAt,
    'updatedAt': p.updatedAt,
  };

  Map<String, dynamic> _transactionToMap(Transaction t) => {
    'id': t.id,
    'kind': t.kind.id,
    'amount': t.amount,
    'occurredAt': t.occurredAt,
    'dayKey': t.dayKey,
    'monthKey': t.monthKey,
    'walletFromId': t.walletFromId,
    'walletToId': t.walletToId,
    'categoryId': t.categoryId,
    'personId': t.personId,
    'fundId': t.fundId,
    'debtDelta': t.debtDelta,
    'note': t.note,
    'groupId': t.groupId,
    'isWriteoff': t.isWriteoff,
    'createdAt': t.createdAt,
    'updatedAt': t.updatedAt,
    'deletedAt': t.deletedAt,
  };

  Map<String, dynamic> _fundToMap(Fund f) => {
    'id': f.id,
    'name': f.name,
    'walletId': f.walletId,
    'targetAmount': f.targetAmount,
    'dueDayKey': f.dueDayKey,
    'note': f.note,
    'iconKey': f.iconKey,
    'colorValue': f.colorValue,
    'isArchived': f.isArchived,
    'sortOrder': f.sortOrder,
    'createdAt': f.createdAt,
    'updatedAt': f.updatedAt,
  };

  Map<String, dynamic> _templateToMap(ExpenseTemplate t) => {
    'id': t.id,
    'note': t.note,
    'amount': t.amount,
    'walletId': t.walletId,
    'categoryId': t.categoryId,
    'sortOrder': t.sortOrder,
    'createdAt': t.createdAt,
    'updatedAt': t.updatedAt,
  };

  Map<String, dynamic> _budgetToMap(Budget b) => {
    'id': b.id,
    'categoryId': b.categoryId,
    'monthKey': b.monthKey,
    'limitAmount': b.limitAmount,
    'createdAt': b.createdAt,
    'updatedAt': b.updatedAt,
  };
}

/// Lỗi có thông điệp đọc được, hiện thẳng cho người dùng.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}
