/// Che số tài khoản và mã giao dịch trong một thông báo trước khi chép ra
/// ngoài (làm mẫu kiểm thử, gửi cho người khác xem).
///
/// Che mọi dãy từ 6 chữ số liền nhau trở lên, chỉ giữ 3 số cuối. Số tiền
/// (`2,702,202`) và ngày giờ (`21/11/2026 18:57`) không có dãy dài như vậy nên
/// giữ nguyên — chúng là thứ parser cần.
String maskDigits(String text) => text.replaceAllMapped(
  RegExp(r'\d{6,}'),
  (m) {
    final s = m[0]!;
    return 'x' * (s.length - 3) + s.substring(s.length - 3);
  },
);
