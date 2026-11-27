import '../db/database.dart';

/// Tính số dư của từng ví ngay sau mỗi giao dịch, theo đúng một công thức:
///
/// ```
/// số dư = initial_balance
///       + tổng amount của giao dịch có wallet_to_id   = ví này
///       - tổng amount của giao dịch có wallet_from_id = ví này
///       (chỉ tính deleted_at IS NULL)
/// ```
///
/// Không rẽ nhánh theo `kind`. Thứ tự thời gian tăng dần theo `(occurredAt, id)`;
/// giao dịch cùng thời điểm được sắp theo `id` tăng dần.
///
/// Trả về bản đồ `txId -> {walletId: balanceAfterTx}` chỉ gồm các ví mà giao
/// dịch đó đụng tới (ví đi trước, ví đến sau). Giao dịch đã xoá mềm bị bỏ qua;
/// giao dịch không có chân ví (trả dùm bởi người khác, xoá nợ) có bản đồ rỗng.
Map<int, Map<int, int>> runningBalances(
  Iterable<Transaction> transactions,
  Map<int, int> initialBalances,
) {
  final active = transactions.where((t) => t.deletedAt == null).toList()
    ..sort((a, b) {
      final byTime = a.occurredAt.compareTo(b.occurredAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

  final balances = Map<int, int>.of(initialBalances);
  final result = <int, Map<int, int>>{};

  for (final tx in active) {
    final fromId = tx.walletFromId;
    final toId = tx.walletToId;

    if (fromId != null) {
      balances[fromId] = (balances[fromId] ?? 0) - tx.amount;
    }
    if (toId != null) {
      balances[toId] = (balances[toId] ?? 0) + tx.amount;
    }

    final touched = <int, int>{};
    if (fromId != null) touched[fromId] = balances[fromId]!;
    if (toId != null) touched[toId] = balances[toId]!;
    result[tx.id] = touched;
  }

  return result;
}
