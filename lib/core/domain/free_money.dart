import '../db/repository.dart';

/// Một phần tiền đã được giữ chỗ, không phải tiền tự do.
typedef Reserve = ({String name, int amount});

/// Tiền tự do: phần tiền tiêu được sau khi đã giữ đủ cho các ngân sách tới hết
/// tháng.
///
/// Có 4 triệu, hạn mức ăn uống còn 2 triệu thì 2 triệu kia là tự do — tiêu vào
/// đâu cũng được mà không đụng tới tiền ăn. Hết phần đó mà vẫn tiêu tiếp thì
/// khoản chi ấy đang lấy tiền ăn của những ngày sau.
///
/// Ngân sách chỉ giữ phần tiền cho hôm nay và những ngày sau theo nhịp đều
/// ([BudgetProgress.reserved]): ngày nào tiêu không hết thì qua nửa đêm phần
/// dư thành tiền tự do, sau khi đã lấp xong chỗ hụt của những ngày tiêu lố.
///
/// Nợ phải trả đã bị trừ sẵn trong [spendable]
/// ([Repository.watchSpendableAssets]), không trừ lần nữa ở đây. [owed] chỉ
/// để hiển thị.
class FreeMoney {
  const FreeMoney({
    required this.spendable,
    required this.reserves,
    required this.owed,
    required this.daysRemaining,
    required this.spentToday,
  });

  /// Dựng từ ngân sách tháng này và sổ nợ.
  factory FreeMoney.from({
    required int spendable,
    required List<BudgetProgress> budgets,
    required List<DebtSummary> debts,
    required int daysRemaining,
    required int spentToday,
  }) {
    return FreeMoney(
      spendable: spendable,
      reserves: [
        for (final b in budgets)
          if (b.reserved > 0) (name: b.categoryName, amount: b.reserved),
      ],
      owed: debts
          .where((d) => d.iOweThem)
          .fold<int>(0, (sum, d) => sum + d.absAmount),
      daysRemaining: daysRemaining,
      spentToday: spentToday,
    );
  }

  /// Tiền tiêu được, đã trừ tiền quỹ và nợ phải trả.
  final int spendable;

  /// Phần từng hạn mức còn giữ cho hôm nay và những ngày sau.
  final List<Reserve> reserves;

  /// Tổng nợ mình đang phải trả người khác, đã nằm trong [spendable].
  final int owed;

  /// Số ngày còn lại của tháng, không tính hôm nay.
  final int daysRemaining;

  /// Hôm nay đã tiêu bao nhiêu NGOÀI các ngân sách (danh mục không đặt hạn
  /// mức, cho mượn, trả dùm).
  final int spentToday;

  int get reserved => reserves.fold<int>(0, (sum, r) => sum + r.amount);

  /// Âm nghĩa là tiền trong ví không đủ cho các ngân sách: đang thiếu.
  int get free => spendable - reserved;

  /// Đã hết tiền tự do: mọi khoản chi ngoài ngân sách từ giờ là lấn vào tiền
  /// đã giữ.
  bool get isExhausted => free <= 0;

  /// Mức tiêu tự do cho HÔM NAY, cách tính giống ngân sách từng mục: cộng lại
  /// phần đã tiêu hôm nay rồi chia cho số ngày còn lại kể cả hôm nay, để mốc
  /// không trôi lên khi tiêu thêm.
  int get budgetForToday {
    final pot = free + spentToday;
    if (pot <= 0) return 0;
    return pot ~/ (daysRemaining + 1);
  }

  /// Hôm nay còn tiêu tự do được bao nhiêu. Âm là đã lố.
  int get leftForToday => budgetForToday - spentToday;

  /// Những ngày sau hôm nay, mỗi ngày được tiêu tự do bao nhiêu.
  int get perDayAfterToday {
    if (daysRemaining <= 0 || free <= 0) return 0;
    return free ~/ daysRemaining;
  }

  /// Một khoản chi sắp ghi sẽ lấy tiền từ đâu.
  ///
  /// [amount] là phần tính vào danh mục có hạn mức [budget] (null nếu danh mục
  /// không có hạn mức). [outside] là phần luôn nằm ngoài ngân sách, như phần
  /// trả dùm cho người khác.
  SpendImpact preview({
    required int amount,
    BudgetProgress? budget,
    int outside = 0,
  }) {
    final room = budget == null
        ? 0
        : (budget.reserved > 0 ? budget.reserved : 0);
    final fromBudget = amount < room ? amount : room;
    final overflow = amount - fromBudget + outside;
    final freeNow = free > 0 ? free : 0;
    final fromFree = overflow < freeNow ? overflow : freeNow;

    return SpendImpact(
      budgetName: budget?.categoryName,
      fromBudget: fromBudget,
      budgetLeftAfter: budget == null ? null : budget.reserved - amount,
      fromFree: fromFree,
      fromReserve: overflow - fromFree,
      freeAfter: free - overflow,
      overToday: overflow > 0 && overflow > leftForToday,
    );
  }
}

/// Kết quả xem trước một khoản chi.
class SpendImpact {
  const SpendImpact({
    required this.budgetName,
    required this.fromBudget,
    required this.budgetLeftAfter,
    required this.fromFree,
    required this.fromReserve,
    required this.freeAfter,
    required this.overToday,
  });

  /// Tên hạn mức của danh mục, null nếu danh mục không đặt hạn mức.
  final String? budgetName;

  /// Phần nằm gọn trong hạn mức của chính danh mục.
  final int fromBudget;

  /// Phần hạn mức danh mục còn giữ ([BudgetProgress.reserved]) sau khoản này.
  /// Âm là đã lấn sang tiền tự do.
  final int? budgetLeftAfter;

  /// Phần lấy từ tiền tự do.
  final int fromFree;

  /// Phần lấn vào tiền đã giữ cho các ngân sách — đây là chỗ phải nhịn.
  final int fromReserve;

  /// Tiền tự do còn lại sau khoản này. Âm là đang thiếu.
  final int freeAfter;

  /// Phần tự do của khoản này vượt quá mức nên tiêu hôm nay.
  final bool overToday;
}
