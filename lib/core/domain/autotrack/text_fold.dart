/// Gấp chữ tiếng Việt về dạng so sánh được: chữ thường, bỏ dấu, `đ` → `d`,
/// gộp khoảng trắng.
///
/// Dart không có sẵn chuẩn hoá Unicode (NFC), mà cùng một chữ "ộ" có thể đến
/// dưới dạng một ký tự dựng sẵn hoặc "o" + các dấu tổ hợp. So sánh trên dạng
/// đã gấp thì cả hai cách viết đều khớp, nên nhãn và dòng đầu thông báo ngân
/// hàng luôn được so ở dạng này. Giá trị (nội dung chuyển khoản...) thì giữ
/// nguyên văn.
String foldVi(String input) {
  final lower = input.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    // Dấu tổ hợp (U+0300–U+036F): bỏ, chữ gốc đứng trước đã được giữ.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final ch = String.fromCharCode(rune);
    out.write(_fold[ch] ?? ch);
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

final Map<String, String> _fold = _buildFoldTable();

Map<String, String> _buildFoldTable() {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final table = <String, String>{};
  groups.forEach((base, variants) {
    for (final rune in variants.runes) {
      table[String.fromCharCode(rune)] = base;
    }
  });
  return table;
}
