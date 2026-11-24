import 'text_fold.dart';

/// Rút nội dung chuyển khoản về một khoá ổn định để nhận ra "cùng một người
/// nhận" giữa các lần giao dịch.
///
/// Chữ hoa, không dấu, chỉ chữ và số; bỏ mã tham chiếu (dãy số, token dài lẫn
/// số) và các chữ ngân hàng tự thêm (`CHUYEN TIEN`, `TT`, `QR`...). Có thể ra
/// chuỗi rỗng — khi đó không đủ thông tin để học, giao dịch phải phân loại tay.
///
/// ```
/// "GRAB*FOOD 8812 TT QR"            → "GRAB FOOD"
/// "Cà phê Phúc Long - CN Q3"        → "CA PHE PHUC LONG CN Q3"
/// "NGUYEN VAN A chuyen tien"        → "NGUYEN VAN A"
/// ```
String normalizeReceiver(String? raw) => receiverTokens(raw).join(' ');

List<String> receiverTokens(String? raw) {
  if (raw == null) return const [];
  final ascii = foldVi(raw).toUpperCase().replaceAll(RegExp('[^A-Z0-9]+'), ' ');
  final tokens = ascii
      .split(' ')
      .where((t) => t.isNotEmpty && !_isReferenceCode(t))
      .toList();

  // Cụm nhiều chữ trước, để "CHUYEN TIEN" bị bỏ mà tên "NGUYEN VAN TIEN" vẫn
  // giữ chữ TIEN.
  final out = <String>[];
  for (var i = 0; i < tokens.length; i++) {
    final phrase = _phrases.where((p) => _startsWith(tokens, i, p)).firstOrNull;
    if (phrase != null) {
      i += phrase.length - 1;
      continue;
    }
    if (_fillers.contains(tokens[i])) continue;
    out.add(tokens[i]);
  }
  return out;
}

bool _isReferenceCode(String t) {
  final digits = t.replaceAll(RegExp('[^0-9]'), '').length;
  if (digits == 0) return false;
  if (digits == t.length) return true; // dãy số thuần: mã, số tài khoản, ngày
  if (digits >= 4) return true; // FT26325ABC123, XXXXXX0145
  return t.length >= 10; // CTLNHIDI038...: mã dài lẫn số
}

bool _startsWith(List<String> tokens, int i, List<String> phrase) {
  if (i + phrase.length > tokens.length) return false;
  for (var k = 0; k < phrase.length; k++) {
    if (tokens[i + k] != phrase[k]) return false;
  }
  return true;
}

const _phrases = [
  ['CHUYEN', 'TIEN'],
  ['CHUYEN', 'KHOAN'],
  ['THANH', 'TOAN'],
  ['NAP', 'TIEN'],
  ['RUT', 'TIEN'],
  ['NOI', 'DUNG'],
];

// KHÔNG có "THE": "THE COFFEE HOUSE" là tên quán.
const _fillers = {
  'CT', 'TT', 'QR', 'CK', 'ND', 'GD', 'TK', 'TKTHE', 'CRE', 'DEB', 'IBFT',
  'FT', 'REF', 'TRACE', 'TAI', 'TU', 'DEN', 'TOI', 'VA', 'MBVCB', 'VCB',
};
