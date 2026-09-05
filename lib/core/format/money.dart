import 'package:flutter/services.dart';

/// Số tiền trong app luôn là số nguyên ĐỒNG.
///
/// Không dùng double: VND không có phần lẻ, và số thực sẽ tích luỹ sai số
/// (0.1 + 0.2 != 0.3), làm số dư lệch dần theo thời gian.
typedef Vnd = int;

/// Định dạng tiền kiểu Việt Nam: 1250000 -> "1.250.000".
///
/// Tự viết thay vì dùng NumberFormat vì chỉ cần đúng một quy tắc, và như vậy
/// thì dùng được cả trong TextInputFormatter mà không phải khởi tạo locale.
String groupDigits(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return negative ? '-${buffer.toString()}' : buffer.toString();
}

/// "1.250.000 ₫"
String formatVnd(int value) => '${groupDigits(value)} ₫';

/// Có dấu cộng ở trước nếu dương: "+1.250.000 ₫" / "-50.000 ₫".
String formatVndSigned(int value) {
  if (value > 0) return '+${formatVnd(value)}';
  return formatVnd(value);
}

/// Rút gọn cho chỗ chật: 1.250.000 -> "1,25tr", 50.000 -> "50k".
String formatVndShort(int value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 1000000000) {
    return '$sign${_trim(abs / 1000000000)} tỷ';
  }
  if (abs >= 1000000) {
    return '$sign${_trim(abs / 1000000)}tr';
  }
  if (abs >= 1000) {
    return '$sign${_trim(abs / 1000)}k';
  }
  return '$sign$abs';
}

String _trim(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  // Chỉ cắt số 0 thừa ở phần thập phân — cắt cả chuỗi sẽ biến "50" thành "5".
  return v
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Bỏ hết dấu phân cách để lấy lại số nguyên. "1.250.000" -> 1250000.
///
/// Đây là chiều ngược của [groupDigits]; quên bước này là int.parse ném lỗi
/// ngay khi người dùng gõ số có dấu chấm.
int parseVnd(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}

/// Vừa gõ vừa tự chèn dấu chấm ngăn cách hàng nghìn.
class ThousandsFormatter extends TextInputFormatter {
  const ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    // Chặn số quá lớn để khỏi tràn khi tính tổng.
    if (digits.length > 15) return oldValue;

    final formatted = groupDigits(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
