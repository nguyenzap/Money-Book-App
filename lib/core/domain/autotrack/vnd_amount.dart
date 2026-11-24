/// Đọc số tiền VND trong thông báo ngân hàng thành số đồng (`int`, có dấu).
///
/// Nhận `-80,000 VND`, `+5.000.000đ`, `2,702,202 VND`, `150000`. Trả về null
/// nếu không chắc chắn đọc đúng:
/// - dấu phân cách nghìn phải đều nhau và mỗi nhóm sau nó đúng 3 chữ số, nên
///   `80,00` bị từ chối chứ không bị đọc thành 8000;
/// - không có phần thập phân (VND không có xu);
/// - không trộn `.` và `,` trong cùng một số.
///
/// Không bao giờ đi qua `double`.
///
/// [requireSign]: dòng số tiền giao dịch luôn có `+`/`-` ở cả BIDV lẫn
/// Eximbank, và dấu chính là chiều tiền. Thiếu dấu thì không đoán.
int? parseVnd(String raw, {bool requireSign = false}) {
  final m = _vnd.firstMatch(raw.trim());
  if (m == null) return null;
  final sign = m.group(1);
  if (requireSign && sign == null) return null;
  final digits = m.group(2)!;
  if (digits.contains('.') && digits.contains(',')) return null;
  final plain = digits.replaceAll(RegExp('[.,]'), '');
  // 15 chữ số = nghìn tỉ đồng. Hơn thế chắc chắn là đọc nhầm (mã giao
  // dịch...), và còn an toàn với giới hạn int.
  if (plain.length > 15) return null;
  final value = int.parse(plain);
  return sign == '-' ? -value : value;
}

final _vnd = RegExp(
  r'^([+-])?\s*(\d{1,3}(?:[.,]\d{3})+|\d+)\s*(?:vnd|vnđ|đ|₫)?$',
  caseSensitive: false,
);
