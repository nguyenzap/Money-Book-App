/// Chiều tiền đọc được từ thông báo. Chỉ có hai chiều: thông báo ngân hàng
/// chỉ biết tiền vào hay ra khỏi tài khoản đó. Ghép thành chuyển ví là việc
/// của bước sau.
enum TxDirection { expense, income }

/// Một giao dịch đọc được từ một thông báo.
class ParsedTxn {
  const ParsedTxn({
    required this.direction,
    required this.amount,
    this.occurredAt,
    this.accountSuffix,
    this.balanceAfter,
    this.receiver,
    this.reference,
  }) : assert(amount > 0, 'amount luôn dương, chiều nằm ở direction');

  final TxDirection direction;

  /// Số đồng, LUÔN dương — cùng quy ước với `Transactions.amount`.
  final int amount;

  /// Thời điểm in trong thông báo, giờ địa phương. Null nếu không có; khi đó
  /// lấy lúc thông báo đến.
  final DateTime? occurredAt;

  /// Vài số cuối của tài khoản, để chọn ví khi một ngân hàng có nhiều tài
  /// khoản.
  final String? accountSuffix;

  /// Số dư sau giao dịch, để đối chiếu với số dư app tính.
  final int? balanceAfter;

  /// Nội dung giao dịch, nguyên văn. Null nếu ngân hàng để trống.
  final String? receiver;

  /// Mã giao dịch / số tham chiếu, để chống ghi trùng.
  final String? reference;

  @override
  String toString() =>
      'ParsedTxn(${direction.name} $amount, at=$occurredAt, '
      'account=$accountSuffix, balance=$balanceAfter, '
      'receiver=$receiver, ref=$reference)';
}

/// Kết quả đọc một thông báo.
sealed class ParseResult {
  const ParseResult();
}

/// Đây là thông báo giao dịch và đã đọc được.
class ParseMatched extends ParseResult {
  const ParseMatched(this.txn);
  final ParsedTxn txn;
}

/// Không phải thông báo giao dịch (OTP, khuyến mãi, mẫu lạ). Không ghi gì.
class ParseIgnored extends ParseResult {
  const ParseIgnored(this.reason);
  final String reason;
}

/// Trông như thông báo giao dịch nhưng đọc không ra (số tiền hỏng...). Giữ
/// lại để thấy được, thay vì lặng lẽ bỏ qua.
class ParseFailed extends ParseResult {
  const ParseFailed(this.reason);
  final String reason;
}
