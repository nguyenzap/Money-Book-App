/// Quỹ tăng hay giảm bao nhiêu vì một giao dịch gắn quỹ.
///
/// Chiều tiền xét theo VÍ ĐANG GIỮ QUỸ: tiền vào ví đó thì quỹ tăng, tiền ra
/// khỏi ví đó thì quỹ giảm. Chuyển giữa hai ví khác (hay chi từ ví khác) thì
/// quỹ không đổi.
///
/// Riêng trường hợp cả hai chân đều là ví giữ quỹ — tiền đã nằm sẵn trong ví
/// đó, chỉ dán nhãn thêm hoặc gỡ nhãn — thì hai chân triệt tiêu và không suy
/// ra được chiều. Khi đó [intoFund] quyết định: true là nạp, false là rút.
/// Vì không suy ngược được nên con số này được LƯU SẴN vào cột `fund_delta`
/// lúc ghi, cùng cách với `debt_delta`.
int fundDeltaOf({
  required int amount,
  required int fundWalletId,
  int? walletFromId,
  int? walletToId,
  bool? intoFund,
}) {
  final inLeg = walletToId == fundWalletId;
  final outLeg = walletFromId == fundWalletId;
  if (inLeg && outLeg) {
    if (intoFund == null) return 0;
    return intoFund ? amount : -amount;
  }
  if (inLeg) return amount;
  if (outLeg) return -amount;
  return 0;
}
