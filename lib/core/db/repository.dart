import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/bill.dart';
import '../domain/budget_progress.dart';
import '../domain/debt_allocation.dart';
import '../domain/fund_delta.dart';
import '../domain/tx_kind.dart';
import '../domain/tx_rules.dart';
import '../format/dates.dart';
import 'database.dart';
import 'repository_models.dart';

export '../domain/budget_progress.dart';
export 'repository_models.dart';

part 'repository_bills.dart';
part 'repository_budgets.dart';
part 'repository_categories.dart';
part 'repository_debts.dart';
part 'repository_funds.dart';
part 'repository_people.dart';
part 'repository_stats.dart';
part 'repository_templates.dart';
part 'repository_transactions.dart';
part 'repository_wallets.dart';

/// Toàn bộ truy vấn của app nằm ở đây.
///
/// Gom một chỗ để điều kiện `deletedAt IS NULL` và công thức số dư không bị
/// viết lại rải rác mỗi nơi một kiểu.
class Repository {
  Repository(this.db);
  final AppDatabase db;

  // ----- Ví -------------------------------------------------------------

  /// Số dư của ví `w`, theo đúng một công thức cho mọi loại giao dịch:
  ///
  ///   số dư = số dư ban đầu + (tổng tiền vào ví) - (tổng tiền ra khỏi ví)
  ///
  /// Đây là chỗ DUY NHẤT viết công thức này (xem CLAUDE.md); truy vấn nào cần
  /// số dư một ví thì ghép biểu thức này vào với bí danh `w`.
  static final _walletBalanceExpr = _walletBalanceSql();

  /// [_walletBalanceExpr], có thể giới hạn thêm giao dịch bằng [until] (một
  /// điều kiện SQL trên `t`, ví dụ `AND t.occurred_at <= ?`, xuất hiện hai
  /// lần nên phải truyền tham số hai lần). Vẫn là cùng một công thức.
  static String _walletBalanceSql({String until = ''}) => '''(
        w.initial_balance
        + COALESCE((SELECT SUM(t.amount) FROM transactions t
                    WHERE t.wallet_to_id = w.id AND t.deleted_at IS NULL$until), 0)
        - COALESCE((SELECT SUM(t.amount) FROM transactions t
                    WHERE t.wallet_from_id = w.id AND t.deleted_at IS NULL$until), 0)
      )''';

  /// Tổng số dư mọi ví chưa lưu trữ, dạng biểu thức SQL để ghép vào truy vấn
  /// khác (xem [watchSpendableAssets]).
  static const _totalAssetsExpr = '''(
        COALESCE((SELECT SUM(initial_balance) FROM wallets WHERE is_archived = 0), 0)
           + COALESCE((SELECT SUM(t.amount) FROM transactions t
                       JOIN wallets w ON w.id = t.wallet_to_id
                       WHERE t.deleted_at IS NULL AND w.is_archived = 0), 0)
           - COALESCE((SELECT SUM(t.amount) FROM transactions t
                       JOIN wallets w ON w.id = t.wallet_from_id
                       WHERE t.deleted_at IS NULL AND w.is_archived = 0), 0)
      )''';

  // ----- Quỹ ------------------------------------------------------------

  /// Số tiền đang có trong quỹ `f`, dùng chung cho mọi truy vấn về quỹ.
  ///
  /// Chỉ là một phép SUM nhờ cột `fund_delta` đã lưu sẵn chiều lúc ghi (xem
  /// [fundDeltaOf]). Không suy từ chân ví được nữa: nạp quỹ ngay trong ví giữ
  /// quỹ có hai chân trùng nhau, hai vế triệt tiêu và quỹ sẽ luôn bằng 0.
  static const _fundSavedExpr = '''(
        COALESCE((SELECT SUM(t.fund_delta) FROM transactions t
                  WHERE t.fund_id = f.id AND t.deleted_at IS NULL), 0)
      )''';

  /// Tính `fund_delta` cho một giao dịch sắp ghi. Không gắn quỹ thì 0.
  Future<int> _fundDeltaFor({
    required int? fundId,
    required int amount,
    int? walletFromId,
    int? walletToId,
    bool? intoFund,
  }) async {
    if (fundId == null) return 0;
    final fund = await (db.select(db.funds)..where((f) => f.id.equals(fundId)))
        .getSingleOrNull();
    if (fund == null) return 0;
    return fundDeltaOf(
      amount: amount,
      fundWalletId: fund.walletId,
      walletFromId: walletFromId,
      walletToId: walletToId,
      intoFund: intoFund,
    );
  }

  /// Tổng tiền đang nằm trong các quỹ chưa lưu trữ.
  ///
  /// Số này bị trừ khỏi "tiền tiêu được" nhưng vẫn nằm trong tổng tài sản đầy
  /// đủ — tiền vẫn là của mình, chỉ là đã có chỗ đến.
  static const _totalInFundsExpr = '''(
      SELECT COALESCE(SUM(saved), 0) FROM (
        SELECT $_fundSavedExpr AS saved
        FROM funds f WHERE f.is_archived = 0
      )
    )''';

  /// Tổng nợ mình đang phải trả, cộng theo từng người.
  ///
  /// Cộng theo người chứ không cộng thẳng mọi debt_delta âm: người khác nợ
  /// mình không được bù vào phần mình nợ người khác.
  static const _totalOwedExpr = '''(
      SELECT COALESCE(SUM(-net), 0) FROM (
        SELECT SUM(debt_delta) AS net FROM transactions
        WHERE deleted_at IS NULL AND person_id IS NOT NULL
        GROUP BY person_id
      ) WHERE net < 0
    )''';

  // ----- Giao dịch ------------------------------------------------------

  TxView _rowToTxView(QueryRow row, {int? debtRemaining}) {
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
              flow: tx.kind.categoryFlow,
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
      billCount: row.read<int>('bill_count'),
      debtRemaining: debtRemaining,
    );
  }

  static const _billCountExpr =
      '(SELECT COUNT(*) FROM bill_items b WHERE b.transaction_id = t.id)';

  /// Phần SELECT … JOIN dùng chung cho mọi truy vấn trả về [TxView]; nơi gọi
  /// chỉ nối thêm WHERE / ORDER BY / LIMIT. Cột ở đây phải khớp với
  /// [_rowToTxView], nên chỉ được viết một lần.
  static const _txViewSelect = '''
      SELECT t.*,
             wf.name AS wf_name, wf.color_value AS wf_color, wf.icon_key AS wf_icon,
             wt.name AS wt_name, wt.color_value AS wt_color, wt.icon_key AS wt_icon,
             c.name  AS c_name,  c.color_value  AS c_color,  c.icon_key  AS c_icon,
             p.name  AS p_name,  p.avatar_color AS p_color,
             $_billCountExpr AS bill_count
      FROM transactions t
      LEFT JOIN wallets    wf ON wf.id = t.wallet_from_id
      LEFT JOIN wallets    wt ON wt.id = t.wallet_to_id
      LEFT JOIN categories c  ON c.id  = t.category_id
      LEFT JOIN people     p  ON p.id  = t.person_id''';

  /// Các bảng mọi truy vấn [TxView] đọc tới. Thiếu một bảng thì stream không
  /// phát lại khi bảng đó đổi (ví dụ đổi tên ví).
  Set<ResultSetImplementation<dynamic, dynamic>> get _txViewTables => {
    db.transactions,
    db.wallets,
    db.categories,
    db.people,
    db.billItems,
  };

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

  int _now() => DateTime.now().millisecondsSinceEpoch;

  String _uuid() => const Uuid().v4();
}
