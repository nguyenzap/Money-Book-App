import '../domain/tx_kind.dart';
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
    this.billCount = 0,
    this.debtRemaining,
  });

  final Transaction tx;
  final Wallet? walletFrom;
  final Wallet? walletTo;
  final Category? category;
  final Person? person;

  /// Số dòng trong hoá đơn chi tiết, 0 nếu không có hoá đơn.
  final int billCount;

  /// Phần nợ còn lại của khoản nợ này (>= 0). Null nếu không phải khoản nợ
  /// (debt_delta == 0 hoặc chính nó là dòng tất toán của khoản khác).
  final int? debtRemaining;

  bool get hasBill => billCount > 0;

  /// Dòng này là một giao dịch tất toán cho một khoản nợ cụ thể.
  bool get isSettlement => tx.settlesTxId != null;

  /// Là một khoản nợ có thể theo dõi phần còn lại (debt_delta != 0 và không
  /// phải dòng tất toán).
  bool get isDebtEntry => tx.debtDelta != 0 && tx.settlesTxId == null;

  /// Khoản nợ đã tất toán xong (phần còn lại = 0).
  bool get isDebtSettled => isDebtEntry && debtRemaining == 0;

  /// Khoản nợ đã trả một phần (0 < còn lại < |debt_delta|).
  bool get isDebtPartlySettled =>
      isDebtEntry &&
      debtRemaining != null &&
      debtRemaining! > 0 &&
      debtRemaining! < tx.debtDelta.abs();

  /// Còn có thể bấm "Tất toán khoản này".
  bool get canSettleEntry => isDebtEntry && (debtRemaining ?? 0) > 0;

  TxKind get kind => tx.kind;

  /// Khoản chi người khác trả dùm: không đụng ví, mình nợ [person].
  bool get isPaidByOther => kind.canBePaidByOther && tx.personId != null;

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
    if (isPaidByOther) return '${person?.name ?? '?'} trả dùm';
    final wallet = walletFrom ?? walletTo;
    return <String>[
      if (wallet != null) wallet.name,
      if (person != null && category != null) person!.name,
    ].join(' · ');
  }

  /// Số tiền có dấu, theo góc nhìn "tổng tài sản của tôi tăng hay giảm".
  /// Chuyển ví trả về 0 vì tổng tài sản không đổi.
  ///
  /// Người khác trả dùm thì ví không đổi nhưng mình mắc nợ thêm, nên vẫn là
  /// một khoản trừ.
  int get signedAmount {
    if (kind == TxKind.transfer) return 0;
    if (isPaidByOther) return -tx.amount;
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

/// Một mẫu chi tiêu kèm tên ví / danh mục, và mẫu đó có ghi thẳng được không.
class TemplateView {
  const TemplateView({
    required this.template,
    this.walletName,
    this.walletArchived = false,
    this.categoryName,
    this.categoryIconKey,
    this.categoryColorValue,
    this.categoryArchived = false,
  });

  final ExpenseTemplate template;
  final String? walletName;
  final bool walletArchived;
  final String? categoryName;
  final String? categoryIconKey;
  final int? categoryColorValue;
  final bool categoryArchived;

  int get id => template.id;
  int? get amount => template.amount;

  /// Nhãn trên nút: ghi chú, không có thì tên danh mục.
  String get label {
    final note = template.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    return categoryName ?? 'Mẫu chi tiêu';
  }

  /// Ví còn dùng được. Ví đã lưu trữ thì không ghi thẳng vào nữa — lưu trữ
  /// nghĩa là không muốn tiêu từ đó.
  bool get hasWallet =>
      template.walletId != null && walletName != null && !walletArchived;

  bool get hasCategory =>
      template.categoryId != null && categoryName != null && !categoryArchived;

  bool get hasAmount => (template.amount ?? 0) > 0;

  /// Đủ cả số tiền, ví và danh mục: bấm là ghi luôn. Thiếu thì mở màn ghi
  /// điền sẵn phần đã có.
  bool get isOneTap => hasAmount && hasWallet && hasCategory;
}

/// Tổng thu / chi của một tháng.
class MonthTotals {
  const MonthTotals({required this.income, required this.expense});
  final int income;
  final int expense;
  int get net => income - expense;

  static const zero = MonthTotals(income: 0, expense: 0);
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
