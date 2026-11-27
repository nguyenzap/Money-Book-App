/// Dữ liệu tối thiểu của một giao dịch nợ để phân bổ phần còn lại.
class DebtRow {
  const DebtRow({
    required this.id,
    required this.occurredAt,
    required this.debtDelta,
    this.settlesTxId,
    this.deletedAt,
  });

  final int id;
  final int occurredAt;
  final int debtDelta;
  final int? settlesTxId;
  final int? deletedAt;
}

/// Phân bổ phần nợ còn lại cho từng khoản của **một người**, theo thứ tự thời
/// gian `(occurredAt, id)` (FIFO). Không rẽ nhánh theo loại giao dịch.
///
/// Quy tắc:
/// - Bỏ qua dòng đã xoá mềm (`deletedAt != null`) hoặc `debtDelta == 0`.
/// - Dòng có `settlesTxId` trừ vào khoản đích trước (tối đa phần còn mở của
///   đích, nếu ngược dấu); phần dư (nếu có) xử lý như dòng không gắn đích.
/// - Dòng không gắn đích trừ lần lượt vào các khoản đang mở **ngược dấu**, cũ
///   nhất trước; phần còn dư mở một khoản mới theo chiều của chính dòng đó.
///
/// Trả về `txId -> remaining` (`>= 0`) cho các dòng không có `settlesTxId`.
/// Dòng tất toán (`settlesTxId != null`) không có mặt trong kết quả (`null`).
Map<int, int> allocateDebts(Iterable<DebtRow> rows) {
  final active = rows
      .where((r) => r.deletedAt == null && r.debtDelta != 0)
      .toList()
    ..sort((a, b) {
      final byTime = a.occurredAt.compareTo(b.occurredAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

  // LinkedHashMap giữ nguyên thứ tự chèn theo thời gian (cũ nhất trước).
  // Giá trị là phần còn mở CÓ DẤU (cùng dấu với debtDelta của dòng, hoặc 0).
  final open = <int, int>{};

  for (final row in active) {
    var leftover = row.debtDelta;

    final targetId = row.settlesTxId;
    if (targetId != null) {
      final targetOpen = open[targetId];
      if (targetOpen != null &&
          targetOpen != 0 &&
          (targetOpen > 0) != (leftover > 0)) {
        final applied = leftover.abs() < targetOpen.abs()
            ? leftover.abs()
            : targetOpen.abs();
        open[targetId] =
            targetOpen > 0 ? targetOpen - applied : targetOpen + applied;
        leftover = leftover > 0 ? leftover - applied : leftover + applied;
      }
    }

    if (leftover != 0) {
      for (final entryId in open.keys) {
        if (leftover == 0) break;
        final current = open[entryId]!;
        if (current == 0 || (current > 0) == (leftover > 0)) continue;
        final applied =
            leftover.abs() < current.abs() ? leftover.abs() : current.abs();
        open[entryId] = current > 0 ? current - applied : current + applied;
        leftover = leftover > 0 ? leftover - applied : leftover + applied;
      }
    }

    open[row.id] = leftover;
  }

  return <int, int>{
    for (final row in active)
      if (row.settlesTxId == null) row.id: open[row.id]!.abs(),
  };
}
