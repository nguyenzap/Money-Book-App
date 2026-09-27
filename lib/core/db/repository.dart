import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/tx_kind.dart';
import '../format/dates.dart';
import 'database.dart';

/// Ví kèm số dư đã tính sẵn.
class WalletWithBalance {
  const WalletWithBalance(this.wallet, this.balance);
  final Wallet wallet;
  final int balance;

  int get id => wallet.id;
  String get name => wallet.name;
}

/// Một dòng trong sổ nợ.
class DebtSummary {
  const DebtSummary(this.person, this.net);
  final Person person;

  /// > 0: người này nợ mình. < 0: mình nợ người này.
  final int net;

  bool get theyOweMe => net > 0;
  bool get iOweThem => net < 0;
  int get absAmount => net.abs();
}

/// Giao dịch kèm tên ví / danh mục / người, để hiển thị thẳng ra danh sách.
class TxView {
  const TxView({
    required this.tx,
    this.walletFrom,
    this.walletTo,
    this.category,
    this.person,
  });

  final Transaction tx;
  final Wallet? walletFrom;
  final Wallet? walletTo;
  final Category? category;
  final Person? person;

  TxKind get kind => tx.kind;

  /// Nhãn chính hiển thị trên dòng giao dịch.
  String get title {
    final note = tx.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    if (category != null) return category!.name;
    if (person != null) return '${kind.label} · ${person!.name}';
    if (kind == TxKind.transfer) {
      return '${walletFrom?.name ?? '?'} → ${walletTo?.name ?? '?'}';
    }
    return kind.label;
  }

  /// Dòng phụ: ví và người liên quan.
  String get subtitle {
    if (kind == TxKind.transfer) {
      return '${walletFrom?.name ?? '?'} → ${walletTo?.name ?? '?'}';
    }
    final wallet = walletFrom ?? walletTo;
    return <String>[
      if (wallet != null) wallet.name,
      if (person != null && category != null) person!.name,
    ].join(' · ');
  }

  /// Số tiền có dấu, theo góc nhìn "tổng tài sản của tôi tăng hay giảm".
  /// Chuyển ví trả về 0 vì tổng tài sản không đổi.
  int get signedAmount {
    if (kind == TxKind.transfer) return 0;
    if (tx.walletToId != null) return tx.amount;
    if (tx.walletFromId != null) return -tx.amount;
    return 0;
  }
}

/// Một quỹ kèm số đã để dành và ví đang giữ tiền.
class FundProgress {
  const FundProgress({
    required this.fund,
    required this.saved,
    required this.walletName,
    this.walletIconKey,
    this.walletColorValue,
  });

  final Fund fund;

  /// Số tiền đang có trong quỹ.
  final int saved;

  /// Ví thật đang giữ số tiền này.
  final String walletName;
  final String? walletIconKey;
  final int? walletColorValue;

  int get id => fund.id;
  String get name => fund.name;
  int? get target => fund.targetAmount;

  /// Còn thiếu bao nhiêu nữa mới đủ mục tiêu. Null nếu không đặt mục tiêu.
  int? get missing {
    final t = target;
    if (t == null) return null;
    final left = t - saved;
    return left > 0 ? left : 0;
  }

  bool get hasTarget => target != null && target! > 0;
  bool get isComplete => hasTarget && saved >= target!;

  double get ratio {
    final t = target;
    if (t == null || t <= 0) return 0;
    return (saved / t).clamp(0.0, 1.0);
  }
}

/// Tổng thu / chi của một tháng.
class MonthTotals {
  const MonthTotals({required this.income, required this.expense});
  final int income;
  final int expense;
  int get net => income - expense;

  static const zero = MonthTotals(income: 0, expense: 0);
}

/// Toàn bộ truy vấn của app nằm ở đây.
///
/// Gom một chỗ để điều kiện `deletedAt IS NULL` và công thức số dư không bị
/// viết lại rải rác mỗi nơi một kiểu.
class Repository {
  Repository(this.db);
  final AppDatabase db;

  // ----- Ví -------------------------------------------------------------

  /// Số dư mọi ví, tính bằng đúng một công thức cho mọi loại giao dịch:
  ///
  ///   số dư = số dư ban đầu + (tổng tiền vào ví) - (tổng tiền ra khỏi ví)
  ///
  /// Viết bằng SQL thô vì phải cộng gộp hai chân ví khác nhau của cùng một
  /// bảng; diễn đạt bằng API dựng truy vấn sẽ dài dòng hơn nhiều mà không rõ
  /// ràng hơn.
  Stream<List<WalletWithBalance>> watchWalletsWithBalance({
    bool includeArchived = false,
  }) {
    final sql = '''
      SELECT w.*, (
        w.initial_balance
        + COALESCE((SELECT SUM(t.amount) FROM transactions t
                    WHERE t.wallet_to_id = w.id AND t.deleted_at IS NULL), 0)
        - COALESCE((SELECT SUM(t.amount) FROM transactions t
                    WHERE t.wallet_from_id = w.id AND t.deleted_at IS NULL), 0)
      ) AS balance
      FROM wallets w
      ${includeArchived ? '' : 'WHERE w.is_archived = 0'}
      ORDER BY w.sort_order, w.id
    ''';

    return db
        .customSelect(sql, readsFrom: {db.wallets, db.transactions})
        .watch()
        .map((rows) => rows
            .map((row) => WalletWithBalance(
                  db.wallets.map(row.data),
                  row.read<int>('balance'),
                ))
            .toList());
  }

  Stream<int> watchTotalAssets() {
    const sql = '''
      SELECT COALESCE((SELECT SUM(initial_balance) FROM wallets WHERE is_archived = 0), 0)
           + COALESCE((SELECT SUM(t.amount) FROM transactions t
                       JOIN wallets w ON w.id = t.wallet_to_id
                       WHERE t.deleted_at IS NULL AND w.is_archived = 0), 0)
           - COALESCE((SELECT SUM(t.amount) FROM transactions t
                       JOIN wallets w ON w.id = t.wallet_from_id
                       WHERE t.deleted_at IS NULL AND w.is_archived = 0), 0)
           AS total
    ''';
    return db
        .customSelect(sql, readsFrom: {db.wallets, db.transactions})
        .watchSingle()
        .map((row) => row.read<int>('total'));
  }

  Future<int> balanceOf(int walletId) async {
    final row = await db.customSelect(
      '''
      SELECT (
        w.initial_balance
        + COALESCE((SELECT SUM(t.amount) FROM transactions t
                    WHERE t.wallet_to_id = w.id AND t.deleted_at IS NULL), 0)
        - COALESCE((SELECT SUM(t.amount) FROM transactions t
                    WHERE t.wallet_from_id = w.id AND t.deleted_at IS NULL), 0)
      ) AS balance
      FROM wallets w WHERE w.id = ?
      ''',
      variables: [Variable.withInt(walletId)],
      readsFrom: {db.wallets, db.transactions},
    ).getSingleOrNull();
    return row?.read<int>('balance') ?? 0;
  }

  Future<int> countTransactionsOfWallet(int walletId) async {
    final t = db.transactions;
    final countExp = t.id.count();
    final q = db.selectOnly(t)
      ..addColumns([countExp])
      ..where(t.deletedAt.isNull() &
          (t.walletFromId.equals(walletId) | t.walletToId.equals(walletId)));
    return (await q.getSingle()).read(countExp) ?? 0;
  }

  Future<int> insertWallet(WalletsCompanion w) => db.into(db.wallets).insert(w);

  Future<bool> updateWallet(Wallet w) => db.update(db.wallets).replace(w);

  Future<void> archiveWallet(int id, {required bool archived}) =>
      (db.update(db.wallets)..where((w) => w.id.equals(id))).write(
        WalletsCompanion(
          isArchived: Value(archived),
          updatedAt: Value(_now()),
        ),
      );

  /// Chỉ nên gọi khi ví không còn giao dịch nào — ví đã dùng thì lưu trữ,
  /// nếu không lịch sử sẽ thủng một lỗ.
  Future<void> deleteWallet(int id) =>
      (db.delete(db.wallets)..where((w) => w.id.equals(id))).go();

  Future<int> nextWalletSortOrder() async {
    final w = db.wallets;
    final maxExp = w.sortOrder.max();
    final q = db.selectOnly(w)..addColumns([maxExp]);
    return ((await q.getSingle()).read(maxExp) ?? -1) + 1;
  }

  // ----- Quỹ ------------------------------------------------------------

  /// Số tiền đang có trong quỹ `f`, dùng chung cho mọi truy vấn về quỹ.
  ///
  /// Chiều tiền xét theo VÍ ĐANG GIỮ QUỸ chứ không phải theo chân ví nào có giá
  /// trị: nạp quỹ là một lần chuyển ví nên có cả hai chân, nếu chỉ hỏi "chân
  /// nào khác null" thì hai vế triệt tiêu và quỹ luôn bằng 0.
  static const _fundSavedExpr = '''(
        COALESCE((SELECT SUM(t.amount) FROM transactions t
                  WHERE t.fund_id = f.id AND t.deleted_at IS NULL
                    AND t.wallet_to_id = f.wallet_id), 0)
        - COALESCE((SELECT SUM(t.amount) FROM transactions t
                    WHERE t.fund_id = f.id AND t.deleted_at IS NULL
                      AND t.wallet_from_id = f.wallet_id), 0)
      )''';


  /// Tổng tiền đang nằm trong các quỹ chưa lưu trữ.
  ///
  /// Số này bị trừ khỏi "tiền tiêu được" nhưng vẫn nằm trong tổng tài sản đầy
  /// đủ — tiền vẫn là của mình, chỉ là đã có chỗ đến.
  Stream<int> watchTotalInFunds() {
    const sql = '''
      SELECT COALESCE(SUM(saved), 0) AS total FROM (
        SELECT $_fundSavedExpr AS saved
        FROM funds f WHERE f.is_archived = 0
      )
    ''';
    return db
        .customSelect(sql, readsFrom: {db.funds, db.transactions})
        .watchSingle()
        .map((row) => row.read<int>('total'));
  }

  /// Tiền thực sự tiêu được: tổng ví trừ đi phần đã hứa cho các quỹ.
  Stream<int> watchSpendableAssets() {
    return watchTotalAssets().asyncMap((total) async {
      final funds = await watchTotalInFunds().first;
      return total - funds;
    });
  }

  /// Danh sách quỹ kèm số đã để dành và ví đang giữ tiền.
  Stream<List<FundProgress>> watchFunds({bool includeArchived = false}) {
    final sql = '''
      SELECT f.*,
             w.name        AS wallet_name,
             w.icon_key    AS wallet_icon,
             w.color_value AS wallet_color,
             $_fundSavedExpr AS saved
      FROM funds f
      JOIN wallets w ON w.id = f.wallet_id
      ${includeArchived ? '' : 'WHERE f.is_archived = 0'}
      ORDER BY f.sort_order, f.id
    ''';

    return db
        .customSelect(sql, readsFrom: {db.funds, db.wallets, db.transactions})
        .watch()
        .map((rows) => rows
            .map((row) => FundProgress(
                  fund: db.funds.map(row.data),
                  saved: row.read<int>('saved'),
                  walletName: row.read<String>('wallet_name'),
                  walletIconKey: row.read<String?>('wallet_icon'),
                  walletColorValue: row.read<int?>('wallet_color'),
                ))
            .toList());
  }

  Future<int> savedInFund(int fundId) async {
    final row = await db.customSelect(
      '''
      SELECT $_fundSavedExpr AS saved
      FROM funds f WHERE f.id = ?
      ''',
      variables: [Variable.withInt(fundId)],
      readsFrom: {db.funds, db.transactions},
    ).getSingleOrNull();
    return row?.read<int>('saved') ?? 0;
  }

  Future<int> insertFund(FundsCompanion f) => db.into(db.funds).insert(f);

  Future<bool> updateFund(Fund f) => db.update(db.funds).replace(f);

  Future<void> archiveFund(int id, {required bool archived}) =>
      (db.update(db.funds)..where((f) => f.id.equals(id))).write(
        FundsCompanion(
          isArchived: Value(archived),
          updatedAt: Value(_now()),
        ),
      );

  /// Xoá quỹ. Các giao dịch từng gắn quỹ vẫn còn nguyên, chỉ mất nhãn quỹ —
  /// tiền chưa bao giờ rời ví nên số dư không đổi.
  Future<void> deleteFund(int id) async {
    await db.transaction(() async {
      await (db.update(db.transactions)..where((t) => t.fundId.equals(id)))
          .write(const TransactionsCompanion(fundId: Value(null)));
      await (db.delete(db.funds)..where((f) => f.id.equals(id))).go();
    });
  }

  Future<int> countTransactionsOfFund(int fundId) async {
    final t = db.transactions;
    final countExp = t.id.count();
    final q = db.selectOnly(t)
      ..addColumns([countExp])
      ..where(t.deletedAt.isNull() & t.fundId.equals(fundId));
    return (await q.getSingle()).read(countExp) ?? 0;
  }

  Future<int> nextFundSortOrder() async {
    final f = db.funds;
    final maxExp = f.sortOrder.max();
    final q = db.selectOnly(f)..addColumns([maxExp]);
    return ((await q.getSingle()).read(maxExp) ?? -1) + 1;
  }

  /// Nạp tiền vào quỹ: chuyển từ ví chi tiêu sang ví đang giữ quỹ.
  ///
  /// Đây đúng là một lần chuyển ví thật, nên ghi bằng [TxKind.transfer] chứ
  /// không đẻ thêm loại giao dịch mới. Gắn thêm quỹ để biết khoản chuyển này
  /// dành cho việc gì.
  ///
  /// Nếu ví nguồn và ví giữ quỹ là một thì không có tiền nào di chuyển, nhưng
  /// vẫn cần ghi để đánh dấu phần tiền đã được hứa — lúc đó dùng chính ví đó
  /// làm cả hai chân.
  Future<int> depositToFund({
    required int fundId,
    required int walletFromId,
    required int walletToId,
    required int amount,
    required DateTime occurredAt,
    String? note,
  }) {
    assert(amount > 0);
    return addTransaction(
      kind: TxKind.transfer,
      amount: amount,
      occurredAt: occurredAt,
      walletFromId: walletFromId,
      walletToId: walletToId,
      fundId: fundId,
      note: note,
    );
  }

  /// Rút tiền khỏi quỹ mà chưa tiêu: trả lại về ví chi tiêu.
  Future<int> withdrawFromFund({
    required int fundId,
    required int walletFromId,
    required int walletToId,
    required int amount,
    required DateTime occurredAt,
    String? note,
  }) {
    assert(amount > 0);
    return addTransaction(
      kind: TxKind.transfer,
      amount: amount,
      occurredAt: occurredAt,
      walletFromId: walletFromId,
      walletToId: walletToId,
      fundId: fundId,
      note: note,
    );
  }

  // ----- Danh mục -------------------------------------------------------

  Stream<List<Category>> watchCategories({
    String? flow,
    bool includeArchived = false,
  }) {
    final q = db.select(db.categories);
    if (!includeArchived) q.where((c) => c.isArchived.equals(false));
    if (flow != null) q.where((c) => c.flow.equals(flow));
    q.orderBy([
      (c) => OrderingTerm(expression: c.sortOrder),
      (c) => OrderingTerm(expression: c.id),
    ]);
    return q.watch();
  }

  Future<int> insertCategory(CategoriesCompanion c) =>
      db.into(db.categories).insert(c);

  Future<bool> updateCategory(Category c) =>
      db.update(db.categories).replace(c);

  Future<int> countTransactionsOfCategory(int categoryId) async {
    final t = db.transactions;
    final countExp = t.id.count();
    final q = db.selectOnly(t)
      ..addColumns([countExp])
      ..where(t.deletedAt.isNull() & t.categoryId.equals(categoryId));
    return (await q.getSingle()).read(countExp) ?? 0;
  }

  /// Xoá danh mục. Giao dịch cũ không mất, chỉ thành "Chưa phân loại".
  ///
  /// Hạn mức ngân sách của danh mục thì mất theo, vì một hạn mức không còn
  /// danh mục thì không còn nghĩa gì.
  Future<void> deleteCategory(int id) async {
    await db.transaction(() async {
      await (db.update(db.transactions)..where((t) => t.categoryId.equals(id)))
          .write(const TransactionsCompanion(categoryId: Value(null)));
      await (db.delete(db.budgets)..where((b) => b.categoryId.equals(id))).go();
      await (db.delete(db.categories)..where((c) => c.id.equals(id))).go();
    });
  }

  Future<int> nextCategorySortOrder(String flow) async {
    final c = db.categories;
    final maxExp = c.sortOrder.max();
    final q = db.selectOnly(c)
      ..addColumns([maxExp])
      ..where(c.flow.equals(flow));
    return ((await q.getSingle()).read(maxExp) ?? -1) + 1;
  }

  // ----- Người ----------------------------------------------------------

  Stream<List<Person>> watchPeople({bool includeArchived = false}) {
    final q = db.select(db.people);
    if (!includeArchived) q.where((p) => p.isArchived.equals(false));
    q.orderBy([
      (p) => OrderingTerm(expression: p.sortOrder),
      (p) => OrderingTerm(expression: p.name),
    ]);
    return q.watch();
  }

  Future<int> insertPerson(PeopleCompanion p) => db.into(db.people).insert(p);

  Future<bool> updatePerson(Person p) => db.update(db.people).replace(p);

  Future<void> deletePerson(int id) =>
      (db.delete(db.people)..where((p) => p.id.equals(id))).go();

  Future<int> countTransactionsOfPerson(int personId) async {
    final t = db.transactions;
    final countExp = t.id.count();
    final q = db.selectOnly(t)
      ..addColumns([countExp])
      ..where(t.deletedAt.isNull() & t.personId.equals(personId));
    return (await q.getSingle()).read(countExp) ?? 0;
  }

  // ----- Sổ nợ ----------------------------------------------------------

  /// Công nợ theo từng người. Chỉ là một phép SUM nhờ cột debt_delta đã lưu
  /// sẵn dấu lúc ghi giao dịch.
  Stream<List<DebtSummary>> watchDebts({bool includeSettled = false}) {
    final sql = '''
      SELECT p.*, COALESCE((
        SELECT SUM(t.debt_delta) FROM transactions t
        WHERE t.person_id = p.id AND t.deleted_at IS NULL
      ), 0) AS net
      FROM people p
      ${includeSettled ? 'WHERE p.is_archived = 0' : ''}
      ORDER BY p.sort_order, p.name
    ''';
    return db
        .customSelect(sql, readsFrom: {db.people, db.transactions})
        .watch()
        .map((rows) {
      final list = rows
          .map((row) =>
              DebtSummary(db.people.map(row.data), row.read<int>('net')))
          .where((d) => includeSettled || d.net != 0)
          .toList();
      list.sort((a, b) => b.absAmount.compareTo(a.absAmount));
      return list;
    });
  }

  Stream<int> watchNetDebt(int personId) {
    final t = db.transactions;
    final sumExp = t.debtDelta.sum();
    final q = db.selectOnly(t)
      ..addColumns([sumExp])
      ..where(t.deletedAt.isNull() & t.personId.equals(personId));
    return q.watchSingle().map((row) => row.read(sumExp) ?? 0);
  }

  Future<int> netDebtOf(int personId) async {
    final t = db.transactions;
    final sumExp = t.debtDelta.sum();
    final q = db.selectOnly(t)
      ..addColumns([sumExp])
      ..where(t.deletedAt.isNull() & t.personId.equals(personId));
    return (await q.getSingle()).read(sumExp) ?? 0;
  }

  // ----- Giao dịch ------------------------------------------------------

  /// Danh sách giao dịch, đã ghép sẵn tên ví / danh mục / người.
  ///
  /// Dùng một câu SQL với các phép join trái, để Drift chỉ phải theo dõi một
  /// truy vấn duy nhất và phát lại đúng một lần khi có thay đổi.
  Stream<List<TxView>> watchTransactions({
    int? limit,
    int? walletId,
    int? personId,
    int? categoryId,
    bool uncategorized = false,
    int? monthKey,
    TxKind? kind,
  }) {
    final where = <String>['t.deleted_at IS NULL'];
    final vars = <Variable>[];

    if (walletId != null) {
      where.add('(t.wallet_from_id = ? OR t.wallet_to_id = ?)');
      vars..add(Variable.withInt(walletId))..add(Variable.withInt(walletId));
    }
    if (personId != null) {
      where.add('t.person_id = ?');
      vars.add(Variable.withInt(personId));
    }
    if (categoryId != null) {
      where.add('t.category_id = ?');
      vars.add(Variable.withInt(categoryId));
    }
    if (uncategorized) {
      where.add('t.category_id IS NULL');
    }
    if (monthKey != null) {
      where.add('t.month_key = ?');
      vars.add(Variable.withInt(monthKey));
    }
    if (kind != null) {
      where.add('t.kind = ?');
      vars.add(Variable.withString(kind.name));
    }

    final sql = '''
      SELECT t.*,
             wf.name AS wf_name, wf.color_value AS wf_color, wf.icon_key AS wf_icon,
             wt.name AS wt_name, wt.color_value AS wt_color, wt.icon_key AS wt_icon,
             c.name  AS c_name,  c.color_value  AS c_color,  c.icon_key  AS c_icon,
             p.name  AS p_name,  p.avatar_color AS p_color
      FROM transactions t
      LEFT JOIN wallets    wf ON wf.id = t.wallet_from_id
      LEFT JOIN wallets    wt ON wt.id = t.wallet_to_id
      LEFT JOIN categories c  ON c.id  = t.category_id
      LEFT JOIN people     p  ON p.id  = t.person_id
      WHERE ${where.join(' AND ')}
      ORDER BY t.occurred_at DESC, t.id DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''';

    return db
        .customSelect(
          sql,
          variables: vars,
          readsFrom: {
            db.transactions,
            db.wallets,
            db.categories,
            db.people,
          },
        )
        .watch()
        .map((rows) => rows.map(_rowToTxView).toList());
  }

  TxView _rowToTxView(QueryRow row) {
    final tx = db.transactions.map(row.data);
    return TxView(
      tx: tx,
      walletFrom: _lightWallet(
        tx.walletFromId,
        row.read<String?>('wf_name'),
        row.read<int?>('wf_color'),
        row.read<String?>('wf_icon'),
      ),
      walletTo: _lightWallet(
        tx.walletToId,
        row.read<String?>('wt_name'),
        row.read<int?>('wt_color'),
        row.read<String?>('wt_icon'),
      ),
      category: tx.categoryId == null || row.read<String?>('c_name') == null
          ? null
          : Category(
              id: tx.categoryId!,
              name: row.read<String>('c_name'),
              flow: tx.kind == TxKind.income ? 'income' : 'expense',
              iconKey: row.read<String?>('c_icon'),
              colorValue: row.read<int?>('c_color'),
              isArchived: false,
              sortOrder: 0,
              createdAt: 0,
              updatedAt: 0,
            ),
      person: tx.personId == null || row.read<String?>('p_name') == null
          ? null
          : Person(
              id: tx.personId!,
              name: row.read<String>('p_name'),
              avatarColor: row.read<int?>('p_color'),
              isArchived: false,
              sortOrder: 0,
              createdAt: 0,
              updatedAt: 0,
            ),
    );
  }

  /// Chỉ dựng phần thông tin ví cần cho việc hiển thị; các cột còn lại không
  /// được dùng tới ở danh sách nên để giá trị trung tính.
  Wallet? _lightWallet(int? id, String? name, int? color, String? icon) {
    if (id == null || name == null) return null;
    return Wallet(
      id: id,
      name: name,
      type: 'other',
      initialBalance: 0,
      iconKey: icon,
      colorValue: color,
      isArchived: false,
      sortOrder: 0,
      createdAt: 0,
      updatedAt: 0,
    );
  }

  Future<TxView?> getTransaction(int id) async {
    final list = await watchTransactionById(id).first;
    return list;
  }

  Stream<TxView?> watchTransactionById(int id) {
    return db
        .customSelect(
          '''
          SELECT t.*,
                 wf.name AS wf_name, wf.color_value AS wf_color, wf.icon_key AS wf_icon,
                 wt.name AS wt_name, wt.color_value AS wt_color, wt.icon_key AS wt_icon,
                 c.name  AS c_name,  c.color_value  AS c_color,  c.icon_key  AS c_icon,
                 p.name  AS p_name,  p.avatar_color AS p_color
          FROM transactions t
          LEFT JOIN wallets    wf ON wf.id = t.wallet_from_id
          LEFT JOIN wallets    wt ON wt.id = t.wallet_to_id
          LEFT JOIN categories c  ON c.id  = t.category_id
          LEFT JOIN people     p  ON p.id  = t.person_id
          WHERE t.id = ?
          ''',
          variables: [Variable.withInt(id)],
          readsFrom: {db.transactions, db.wallets, db.categories, db.people},
        )
        .watch()
        .map((rows) => rows.isEmpty ? null : _rowToTxView(rows.first));
  }

  /// Thêm giao dịch.
  ///
  /// `debtDelta` và các khoá ngày tháng được suy ra tự động từ [kind] và
  /// [occurredAt], để không nơi nào khác trong app phải tự tính dấu.
  Future<int> addTransaction({
    required TxKind kind,
    required int amount,
    required DateTime occurredAt,
    int? walletFromId,
    int? walletToId,
    int? categoryId,
    int? personId,
    int? fundId,
    String? note,
    String? groupId,
    int? recurringId,
    bool isWriteoff = false,
  }) {
    assert(amount > 0, 'amount phải dương, dấu suy ra từ kind');
    final now = _now();
    return db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            kind: kind,
            amount: amount,
            occurredAt: occurredAt.millisecondsSinceEpoch,
            dayKey: dayKeyOf(occurredAt),
            monthKey: monthKeyOf(occurredAt),
            walletFromId: Value(walletFromId),
            walletToId: Value(walletToId),
            categoryId: Value(categoryId),
            personId: Value(personId),
            fundId: Value(fundId),
            debtDelta: Value(kind.debtDelta(amount)),
            note: Value(note),
            groupId: Value(groupId),
            recurringId: Value(recurringId),
            isWriteoff: Value(isWriteoff),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateTransaction({
    required int id,
    required TxKind kind,
    required int amount,
    required DateTime occurredAt,
    int? walletFromId,
    int? walletToId,
    int? categoryId,
    int? personId,
    int? fundId,
    String? note,
  }) {
    assert(amount > 0);
    return (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        kind: Value(kind),
        amount: Value(amount),
        occurredAt: Value(occurredAt.millisecondsSinceEpoch),
        dayKey: Value(dayKeyOf(occurredAt)),
        monthKey: Value(monthKeyOf(occurredAt)),
        walletFromId: Value(walletFromId),
        walletToId: Value(walletToId),
        categoryId: Value(categoryId),
        personId: Value(personId),
        fundId: Value(fundId),
        debtDelta: Value(kind.debtDelta(amount)),
        note: Value(note),
        updatedAt: Value(_now()),
      ),
    );
  }

  /// Xoá mềm, để còn hoàn tác được.
  Future<void> softDeleteTransaction(int id) =>
      (db.update(db.transactions)..where((t) => t.id.equals(id)))
          .write(TransactionsCompanion(deletedAt: Value(_now())));

  Future<void> restoreTransaction(int id) =>
      (db.update(db.transactions)..where((t) => t.id.equals(id)))
          .write(const TransactionsCompanion(deletedAt: Value(null)));

  /// Xoá cả nhóm giao dịch sinh cùng lúc (ví dụ cặp giao dịch của trả dùm).
  /// Trả về danh sách id để hoàn tác.
  Future<List<int>> softDeleteGroup(String groupId) async {
    final rows = await (db.select(db.transactions)
          ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull()))
        .get();
    await (db.update(db.transactions)
          ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull()))
        .write(TransactionsCompanion(deletedAt: Value(_now())));
    return rows.map((r) => r.id).toList();
  }

  Future<void> restoreMany(List<int> ids) =>
      (db.update(db.transactions)..where((t) => t.id.isIn(ids)))
          .write(const TransactionsCompanion(deletedAt: Value(null)));

  Future<int> countInGroup(String groupId) async {
    final t = db.transactions;
    final countExp = t.id.count();
    final q = db.selectOnly(t)
      ..addColumns([countExp])
      ..where(t.groupId.equals(groupId) & t.deletedAt.isNull());
    return (await q.getSingle()).read(countExp) ?? 0;
  }

  /// Ghi một bữa trả dùm: mình trả trước toàn bộ, những người khác nợ lại
  /// phần của họ.
  ///
  /// Sinh ra nhiều giao dịch cùng một [groupId]:
  ///   * một khoản chi đúng bằng phần của mình — chỉ phần này mới vào thống kê
  ///     và ngân sách, nên một bữa 200k chia bốn chỉ tính 50k tiền ăn;
  ///   * mỗi người một khoản cho mượn bằng phần của họ, vào sổ nợ.
  ///
  /// Tổng tiền rời ví vẫn đúng bằng số đã trả. Bỏ qua phần của tôi nếu bằng 0
  /// (trường hợp trả hộ hoàn toàn, mình không ăn).
  ///
  /// Trả về id của các giao dịch đã tạo.
  Future<List<int>> addSplitBill({
    required int walletFromId,
    required int myShare,
    required Map<int, int> sharesByPerson,
    required DateTime occurredAt,
    int? categoryId,
    String? note,
  }) async {
    assert(myShare >= 0);
    assert(sharesByPerson.values.every((v) => v > 0));

    final groupId = _uuid();
    final ids = <int>[];

    await db.transaction(() async {
      if (myShare > 0) {
        ids.add(await addTransaction(
          kind: TxKind.expense,
          amount: myShare,
          occurredAt: occurredAt,
          walletFromId: walletFromId,
          categoryId: categoryId,
          note: note,
          groupId: groupId,
        ));
      }
      for (final entry in sharesByPerson.entries) {
        ids.add(await addTransaction(
          kind: TxKind.lend,
          amount: entry.value,
          occurredAt: occurredAt,
          walletFromId: walletFromId,
          personId: entry.key,
          note: note == null ? 'Trả dùm' : '$note (trả dùm)',
          groupId: groupId,
        ));
      }
    });

    return ids;
  }

  /// Các giao dịch cùng một nhóm với giao dịch đã cho (kể cả chính nó).
  Future<List<TxView>> transactionsInGroup(String groupId) async {
    final rows = await db.customSelect(
      '''
      SELECT t.*,
             wf.name AS wf_name, wf.color_value AS wf_color, wf.icon_key AS wf_icon,
             wt.name AS wt_name, wt.color_value AS wt_color, wt.icon_key AS wt_icon,
             c.name  AS c_name,  c.color_value  AS c_color,  c.icon_key  AS c_icon,
             p.name  AS p_name,  p.avatar_color AS p_color
      FROM transactions t
      LEFT JOIN wallets    wf ON wf.id = t.wallet_from_id
      LEFT JOIN wallets    wt ON wt.id = t.wallet_to_id
      LEFT JOIN categories c  ON c.id  = t.category_id
      LEFT JOIN people     p  ON p.id  = t.person_id
      WHERE t.group_id = ? AND t.deleted_at IS NULL
      ORDER BY t.kind DESC, t.id
      ''',
      variables: [Variable.withString(groupId)],
      readsFrom: {db.transactions, db.wallets, db.categories, db.people},
    ).get();
    return rows.map(_rowToTxView).toList();
  }

  /// Điều chỉnh số dư ví cho khớp thực tế.
  ///
  /// Không sửa thẳng số dư ban đầu mà ghi một giao dịch chênh lệch, để lịch sử
  /// vẫn giải thích được vì sao số dư nhảy. Trả về null nếu không có chênh
  /// lệch nào.
  Future<int?> adjustWalletBalance({
    required int walletId,
    required int newBalance,
    String? note,
  }) async {
    final current = await balanceOf(walletId);
    final delta = newBalance - current;
    if (delta == 0) return null;

    return addTransaction(
      kind: TxKind.adjust,
      amount: delta.abs(),
      occurredAt: DateTime.now(),
      walletFromId: delta < 0 ? walletId : null,
      walletToId: delta > 0 ? walletId : null,
      note: note ?? 'Điều chỉnh số dư',
    );
  }

  // ----- Thống kê -------------------------------------------------------

  /// Tổng thu / chi trong tháng. Chỉ tính thu nhập và chi tiêu — chuyển ví,
  /// vay mượn và điều chỉnh số dư không phải tiêu dùng.
  Stream<MonthTotals> watchMonthTotals(int monthKey) {
    return db.customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN kind = 'income'  THEN amount END), 0) AS income,
        COALESCE(SUM(CASE WHEN kind = 'expense' THEN amount END), 0) AS expense
      FROM transactions
      WHERE deleted_at IS NULL AND month_key = ?
      ''',
      variables: [Variable.withInt(monthKey)],
      readsFrom: {db.transactions},
    ).watchSingle().map(
          (row) => MonthTotals(
            income: row.read<int>('income'),
            expense: row.read<int>('expense'),
          ),
        );
  }

  /// Chi tiêu (hoặc thu nhập) trong tháng, gom theo danh mục, nhiều nhất
  /// trước. Danh mục đã bị xoá gom chung vào "Chưa phân loại".
  Stream<List<CategoryTotal>> watchCategoryTotals(
    int monthKey, {
    String flow = 'expense',
  }) {
    final kind = flow == 'income' ? TxKind.income : TxKind.expense;
    return db.customSelect(
      '''
      SELECT t.category_id AS cid,
             c.name        AS cname,
             c.color_value AS ccolor,
             c.icon_key    AS cicon,
             SUM(t.amount) AS total
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.deleted_at IS NULL AND t.month_key = ? AND t.kind = ?
      GROUP BY t.category_id
      ORDER BY total DESC
      ''',
      variables: [
        Variable.withInt(monthKey),
        Variable.withString(kind.name),
      ],
      readsFrom: {db.transactions, db.categories},
    ).watch().map((rows) => rows
        .map((row) => CategoryTotal(
              categoryId: row.read<int?>('cid'),
              name: row.read<String?>('cname') ?? 'Chưa phân loại',
              colorValue: row.read<int?>('ccolor'),
              iconKey: row.read<String?>('cicon'),
              total: row.read<int>('total'),
            ))
        .toList());
  }

  /// Vài khoản chi lớn nhất trong tháng.
  Stream<List<TxView>> watchTopExpenses(int monthKey, {int limit = 5}) {
    return db
        .customSelect(
          '''
          SELECT t.*,
                 wf.name AS wf_name, wf.color_value AS wf_color, wf.icon_key AS wf_icon,
                 wt.name AS wt_name, wt.color_value AS wt_color, wt.icon_key AS wt_icon,
                 c.name  AS c_name,  c.color_value  AS c_color,  c.icon_key  AS c_icon,
                 p.name  AS p_name,  p.avatar_color AS p_color
          FROM transactions t
          LEFT JOIN wallets    wf ON wf.id = t.wallet_from_id
          LEFT JOIN wallets    wt ON wt.id = t.wallet_to_id
          LEFT JOIN categories c  ON c.id  = t.category_id
          LEFT JOIN people     p  ON p.id  = t.person_id
          WHERE t.deleted_at IS NULL AND t.month_key = ? AND t.kind = 'expense'
          ORDER BY t.amount DESC
          LIMIT $limit
          ''',
          variables: [Variable.withInt(monthKey)],
          readsFrom: {db.transactions, db.wallets, db.categories, db.people},
        )
        .watch()
        .map((rows) => rows.map(_rowToTxView).toList());
  }

  // ----- Ngân sách ------------------------------------------------------

  /// Hạn mức từng danh mục kèm số đã tiêu trong tháng.
  ///
  /// Số đã tiêu chỉ đếm giao dịch `expense`, nên tiền trả dùm cho bạn bè —
  /// vốn được ghi thành các khoản `lend` — không làm vượt ngân sách oan.
  ///
  /// [now] là mốc "hôm nay" để tính số ngày đã qua; truyền vào để nơi gọi đổi
  /// được mốc khi qua nửa đêm mà không cần đợi dữ liệu thay đổi.
  Stream<List<BudgetProgress>> watchBudgets(int monthKey, {DateTime? now}) {
    return db
        .customSelect(
          '''
      SELECT b.id            AS budget_id,
             b.limit_amount  AS limit_amount,
             b.month_key     AS budget_month,
             c.id            AS category_id,
             c.name          AS category_name,
             c.color_value   AS category_color,
             c.icon_key      AS category_icon,
             COALESCE((
               SELECT SUM(t.amount) FROM transactions t
               WHERE t.category_id = c.id
                 AND t.kind = 'expense'
                 AND t.month_key = ?
                 AND t.deleted_at IS NULL
             ), 0) AS spent
      FROM budgets b
      JOIN categories c ON c.id = b.category_id
      WHERE (b.month_key IS NULL OR b.month_key = ?)
        AND c.is_archived = 0
      ORDER BY c.sort_order, c.id
      ''',
          variables: [Variable.withInt(monthKey), Variable.withInt(monthKey)],
          readsFrom: {db.budgets, db.categories, db.transactions},
        )
        .watch()
        .map((rows) {
          // Tính một lần cho cả danh sách thay vì lặp lại ở từng dòng.
          final totalDays = daysInMonth(monthKey);
          final elapsed = daysElapsedIn(monthKey, now: now);

          return rows
              .map(
                (row) => BudgetProgress(
                  budgetId: row.read<int>('budget_id'),
                  categoryId: row.read<int>('category_id'),
                  categoryName: row.read<String>('category_name'),
                  colorValue: row.read<int?>('category_color'),
                  iconKey: row.read<String?>('category_icon'),
                  limitAmount: row.read<int>('limit_amount'),
                  spent: row.read<int>('spent'),
                  isRecurring: row.read<int?>('budget_month') == null,
                  monthKey: monthKey,
                  daysInMonth: totalDays,
                  daysElapsed: elapsed,
                ),
              )
              .toList();
        });
  }

  /// Tổng chi tiêu trong một ngày, gom theo danh mục có đặt hạn mức.
  ///
  /// Dùng ở màn Tổng quan để trả lời câu "hôm nay mình đã tiêu bao nhiêu rồi",
  /// đối chiếu ngay với mức khuyến nghị mỗi ngày.
  Stream<Map<int, int>> watchSpentByCategoryOnDay(int dayKey) {
    return db.customSelect(
      '''
      SELECT category_id AS cid, SUM(amount) AS total
      FROM transactions
      WHERE deleted_at IS NULL
        AND kind = 'expense'
        AND day_key = ?
        AND category_id IS NOT NULL
      GROUP BY category_id
      ''',
      variables: [Variable.withInt(dayKey)],
      readsFrom: {db.transactions},
    ).watch().map((rows) => {
          for (final row in rows) row.read<int>('cid'): row.read<int>('total'),
        });
  }

  /// Tiền đã ra khỏi ví trong một ngày cho những việc NGOÀI các ngân sách:
  /// chi vào danh mục không đặt hạn mức (kể cả chưa phân loại) và cho mượn —
  /// gồm cả phần trả dùm.
  ///
  /// Khoản chi lấy từ quỹ không tính: tiền đó đã được để dành sẵn, không lấy
  /// từ tiền tự do.
  Stream<int> watchSpentOutsideBudgetsOnDay(int dayKey, int monthKey) {
    return db.customSelect(
      '''
      SELECT COALESCE(SUM(t.amount), 0) AS total
      FROM transactions t
      WHERE t.deleted_at IS NULL
        AND t.day_key = ?
        AND t.fund_id IS NULL
        AND t.wallet_from_id IS NOT NULL
        AND (
          t.kind = 'lend'
          OR (t.kind = 'expense' AND (
            t.category_id IS NULL OR t.category_id NOT IN (
              SELECT b.category_id FROM budgets b
              JOIN categories c ON c.id = b.category_id
              WHERE (b.month_key IS NULL OR b.month_key = ?)
                AND c.is_archived = 0
            )
          ))
        )
      ''',
      variables: [Variable.withInt(dayKey), Variable.withInt(monthKey)],
      readsFrom: {db.transactions, db.budgets, db.categories},
    ).watchSingle().map((row) => row.read<int>('total'));
  }

  /// Đặt hoặc cập nhật hạn mức cho một danh mục.
  ///
  /// [monthKey] null nghĩa là áp dụng cho mọi tháng.
  ///
  /// Tự tìm rồi cập nhật thay vì dựa vào `insertOnConflictUpdate`: SQLite coi
  /// hai giá trị NULL là khác nhau, nên chỉ mục duy nhất trên
  /// `(category_id, month_key)` không bắt được xung đột ở các hạn mức áp dụng
  /// cho mọi tháng, và mỗi lần đặt lại sẽ đẻ thêm một dòng mới.
  Future<void> setBudget({
    required int categoryId,
    required int limitAmount,
    int? monthKey,
  }) async {
    assert(limitAmount > 0);
    final now = _now();

    await db.transaction(() async {
      final query = db.select(db.budgets)
        ..where((b) => b.categoryId.equals(categoryId))
        ..where((b) => monthKey == null
            ? b.monthKey.isNull()
            : b.monthKey.equals(monthKey));
      final existing = await query.getSingleOrNull();

      if (existing == null) {
        await db.into(db.budgets).insert(
              BudgetsCompanion.insert(
                categoryId: categoryId,
                monthKey: Value(monthKey),
                limitAmount: limitAmount,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (db.update(db.budgets)..where((b) => b.id.equals(existing.id)))
            .write(
          BudgetsCompanion(
            limitAmount: Value(limitAmount),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> deleteBudget(int id) =>
      (db.delete(db.budgets)..where((b) => b.id.equals(id))).go();

  int _now() => DateTime.now().millisecondsSinceEpoch;

  String _uuid() => const Uuid().v4();
}

/// Tình trạng nhịp độ tiêu tiền so với chặng đường của tháng.
enum BudgetPace {
  /// Đã tiêu hết hạn mức.
  over,

  /// Tiêu nhanh hơn nhịp đều đáng kể — cứ đà này sẽ hết sớm.
  fast,

  /// Bám sát nhịp đều.
  onTrack,

  /// Tiêu chậm hơn nhịp, đang dư dả.
  slow,
}

/// Một hạn mức kèm tiến độ chi tiêu trong tháng.
///
/// Ngoài chuyện đã tiêu bao nhiêu, lớp này còn trả lời câu hỏi quan trọng hơn:
/// *tiêu như vậy có nhanh quá so với thời điểm này của tháng không*, và
/// *những ngày còn lại được tiêu bao nhiêu mỗi ngày thì vừa đủ*.
class BudgetProgress {
  const BudgetProgress({
    required this.budgetId,
    required this.categoryId,
    required this.categoryName,
    required this.limitAmount,
    required this.spent,
    required this.isRecurring,
    required this.monthKey,
    required this.daysInMonth,
    required this.daysElapsed,
    this.colorValue,
    this.iconKey,
    this.cashCap,
  });

  final int budgetId;
  final int categoryId;
  final String categoryName;
  final int limitAmount;
  final int spent;

  /// Hạn mức áp dụng cho mọi tháng, không riêng tháng nào.
  final bool isRecurring;

  final int monthKey;
  final int daysInMonth;

  /// Số ngày của tháng đã trôi qua, tính cả hôm nay.
  final int daysElapsed;

  final int? colorValue;
  final String? iconKey;

  /// Phần tiền THẬT trong ví dành được cho hạn mức này, null nếu không giới
  /// hạn. Xem [capBudgetsByCash].
  final int? cashCap;

  BudgetProgress withCashCap(int? cap) => BudgetProgress(
    budgetId: budgetId,
    categoryId: categoryId,
    categoryName: categoryName,
    limitAmount: limitAmount,
    spent: spent,
    isRecurring: isRecurring,
    monthKey: monthKey,
    daysInMonth: daysInMonth,
    daysElapsed: daysElapsed,
    colorValue: colorValue,
    iconKey: iconKey,
    cashCap: cap,
  );

  int get remaining => limitAmount - spent;

  /// Số thực sự còn tiêu được: phần còn lại của hạn mức, nhưng không quá số
  /// tiền đang có. Hạn mức chỉ là lời hứa với bản thân, còn tiền hết là hết —
  /// tiêu lố ở danh mục khác thì ví vơi đi dù hạn mức này chưa hề đụng tới.
  int get spendable {
    final cap = cashCap;
    if (cap == null || cap >= remaining) return remaining;
    return cap < 0 ? 0 : cap;
  }

  /// Tiền trong ví đã ít hơn phần còn lại của hạn mức.
  bool get isLimitedByCash =>
      cashCap != null && remaining > 0 && cashCap! < remaining;
  double get ratio => limitAmount == 0 ? 0 : spent / limitAmount;
  bool get isOver => spent > limitAmount;

  /// Sắp chạm hạn mức: từ 80% trở lên nhưng chưa vượt.
  bool get isNearLimit => !isOver && ratio >= 0.8;

  // ----- Nhịp độ --------------------------------------------------------

  /// Số ngày còn lại của tháng, không tính hôm nay.
  int get daysRemaining => (daysInMonth - daysElapsed).clamp(0, 31);

  /// Tháng đã kết thúc thì không còn gì để cảnh báo nữa.
  bool get isPastMonth => daysRemaining == 0 && daysElapsed >= daysInMonth;

  /// Mức tiêu trung bình mỗi ngày nếu chia đều hạn mức cả tháng.
  ///
  /// Ngân sách ăn uống 3 triệu cho tháng 30 ngày thì đây là 100k.
  int get dailyAllowance =>
      daysInMonth == 0 ? 0 : limitAmount ~/ daysInMonth;

  /// Thực tế đang tiêu bao nhiêu một ngày.
  int get dailyAverage => daysElapsed == 0 ? 0 : spent ~/ daysElapsed;

  /// Đáng lẽ đến giờ này mới nên tiêu tới đây.
  int get expectedByNow =>
      daysInMonth == 0 ? 0 : (limitAmount * daysElapsed) ~/ daysInMonth;

  /// Tiêu quá mức đáng lẽ bao nhiêu. Âm nghĩa là đang tiêu tiết kiệm.
  int get paceDelta => spent - expectedByNow;

  /// Mức nên tiêu trong HÔM NAY.
  ///
  /// Phải cộng lại phần đã tiêu hôm nay rồi mới chia, vì [remaining] đã trừ nó
  /// đi rồi còn [daysRemaining] lại không đếm hôm nay — lấy tiền của những ngày
  /// sau đem chia cho hôm nay thì sai cả tử lẫn mẫu.
  ///
  /// Tuyệt đối không cộng thêm số đã tiêu hôm nay vào kết quả này để làm mốc so
  /// sánh: làm vậy thì càng tiêu nhiều mốc càng cao và không bao giờ báo vượt.
  int budgetForToday(int spentToday) {
    final daysLeftIncludingToday = daysRemaining + 1;
    if (daysLeftIncludingToday <= 0) return 0;
    final pot = spendable + spentToday;
    if (pot <= 0) return 0;
    return pot ~/ daysLeftIncludingToday;
  }

  /// Hôm nay còn tiêu được bao nhiêu nữa.
  ///
  /// Đây là con số dùng để quyết định: đứng trước quầy nước thì cái cần biết là
  /// còn bao nhiêu, chứ không phải đã tiêu bao nhiêu. Âm nghĩa là đã lố.
  int leftForToday(int spentToday) => budgetForToday(spentToday) - spentToday;

  /// Phần đã dùng của hạn mức hôm nay, từ 0 tới 1.
  ///
  /// Dùng để vẽ thanh vơi dần: 1 là còn nguyên, 0 là hết sạch.
  double remainingRatioToday(int spentToday) {
    final target = budgetForToday(spentToday);
    if (target <= 0) return 0;
    final left = leftForToday(spentToday);
    if (left <= 0) return 0;
    return (left / target).clamp(0.0, 1.0);
  }

  /// Còn bao nhiêu tiền mỗi ngày cho những ngày CÒN LẠI, không tính hôm nay.
  ///
  /// Đây là con số hữu ích nhất: hôm nay lỡ tay thì ngày mai biết phải rút
  /// xuống bao nhiêu để cả tháng vẫn nằm trong hạn mức.
  int get remainingDailyAllowance {
    if (daysRemaining <= 0) return 0;
    if (spendable <= 0) return 0;
    return spendable ~/ daysRemaining;
  }

  /// Những ngày TRƯỚC hôm nay đã tiêu vượt nhịp đều bao nhiêu. Âm là đang dư.
  ///
  /// Không phụ thuộc vào lúc nào khoản chi được ghi: quên ghi hôm qua, sáng nay
  /// ghi bù với ngày của hôm qua thì con số này vẫn lộ ra. Nhờ vậy màn hình giải
  /// thích được vì sao mốc hôm nay thấp hơn bình thường, thay vì lặng lẽ hạ mốc
  /// mà không ai hay.
  int overspentBeforeToday(int spentToday) {
    if (daysInMonth == 0 || daysElapsed == 0) return 0;
    final before = spent - spentToday;
    final expected = (limitAmount * (daysElapsed - 1)) ~/ daysInMonth;
    return before - expected;
  }

  /// Cứ giữ nhịp này thì hết tháng sẽ tiêu hết bao nhiêu.
  int get projectedTotal =>
      daysElapsed == 0 ? 0 : (spent * daysInMonth) ~/ daysElapsed;

  /// Cứ giữ nhịp này thì còn cầm cự được thêm bao nhiêu ngày nữa.
  /// Trả về null nếu đủ tiền tới hết tháng.
  int? get daysUntilRunOut {
    if (dailyAverage <= 0 || spendable <= 0) return null;
    final days = spendable ~/ dailyAverage;
    if (days >= daysRemaining) return null;
    return days;
  }

  /// Cứ giữ nhịp này thì hạn mức cạn vào ngày thứ mấy của tháng.
  /// Trả về null nếu đủ tiền tới hết tháng.
  int? get projectedRunOutDay {
    final days = daysUntilRunOut;
    if (days == null) return null;
    final day = daysElapsed + days;
    return day > daysInMonth ? null : day;
  }

  BudgetPace get pace {
    if (isOver) return BudgetPace.over;
    if (daysElapsed == 0 || limitAmount == 0) return BudgetPace.onTrack;
    final expected = expectedByNow;
    if (expected == 0) return BudgetPace.onTrack;

    final overshoot = (spent - expected) / expected;
    // Ngưỡng 15%: đủ rộng để một bữa đắt hơn thường lệ không làm nổ cảnh báo,
    // đủ hẹp để bắt được xu hướng tiêu vượt thật sự.
    if (overshoot > 0.15) return BudgetPace.fast;
    if (overshoot < -0.15) return BudgetPace.slow;
    return BudgetPace.onTrack;
  }

  /// Có nên nhắc người dùng về hạn mức này không.
  ///
  /// Chỉ nhắc khi đã vượt, sắp chạm, hoặc đang tiêu nhanh hơn nhịp — và bỏ qua
  /// những tháng đã kết thúc vì không còn gì để điều chỉnh.
  bool get needsAttention {
    if (isPastMonth) return false;
    return isOver || isNearLimit || pace == BudgetPace.fast || isLimitedByCash;
  }
}

/// Chặn các hạn mức bằng số tiền thật đang có.
///
/// Hạn mức ăn uống còn 300k nhưng ví chỉ còn 190k — vì tiền đã chảy sang những
/// khoản khác — thì con số "mỗi ngày được tiêu" phải tính trên 190k. Có nhiều
/// hạn mức thì chia tiền theo tỉ lệ phần còn lại của từng cái, để tổng các
/// phần không vượt quá số tiền đang có. Đủ tiền cho tất cả thì giữ nguyên.
List<BudgetProgress> capBudgetsByCash(List<BudgetProgress> budgets, int cash) {
  final open = budgets.fold<int>(
    0,
    (sum, b) => sum + (b.remaining > 0 ? b.remaining : 0),
  );
  if (open <= cash) return budgets;

  final available = cash < 0 ? 0 : cash;
  return [
    for (final b in budgets)
      b.withCashCap(
        b.remaining <= 0 ? 0 : (available * (b.remaining / open)).floor(),
      ),
  ];
}

/// Tổng tiền của một danh mục trong một tháng.
class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.name,
    required this.total,
    this.colorValue,
    this.iconKey,
  });

  final int? categoryId;
  final String name;
  final int total;
  final int? colorValue;
  final String? iconKey;
}
