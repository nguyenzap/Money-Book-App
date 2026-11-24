import 'receiver_normalizer.dart';

/// Vì sao một giao dịch tự ghi có danh mục này. Lưu bằng [name] vào
/// `notification_events.category_source`.
enum CategorySource {
  /// Đúng người nhận đã có quy tắc (mình từng tự phân loại).
  name,

  /// Tên gần giống một người nhận đã có quy tắc. Chỉ là đoán.
  similar,

  /// Tên có chứa từ khoá của danh mục. Chỉ là đoán.
  keyword,

  /// Chính mình chọn.
  user;

  /// Đoán thì phải xem lại; quy tắc chính xác hoặc mình chọn thì tin được.
  bool get isGuess => this == similar || this == keyword;

  static CategorySource? parse(String? s) =>
      values.where((v) => v.name == s).firstOrNull;
}

/// Một quy tắc "người nhận → danh mục" đã học.
class RuleEntry {
  const RuleEntry({
    required this.key,
    required this.flow,
    required this.categoryId,
    this.displayName = '',
    this.hitCount = 0,
  });

  /// Đã chuẩn hoá bằng [normalizeReceiver].
  final String key;

  /// expense | income
  final String flow;
  final int categoryId;
  final String displayName;
  final int hitCount;
}

class KeywordEntry {
  const KeywordEntry({
    required this.keyword,
    required this.flow,
    required this.categoryId,
  });

  /// Đã chuẩn hoá bằng [normalizeReceiver].
  final String keyword;

  /// Chiều của danh mục, để từ khoá của danh mục thu không gắn vào khoản chi.
  final String flow;
  final int categoryId;
}

class CategoryGuess {
  const CategoryGuess(this.categoryId, this.source, {this.reason});

  /// Không đoán được gì.
  static const none = CategoryGuess(null, null);

  final int? categoryId;
  final CategorySource? source;

  /// Hiện cho người dùng: "giống PHUC LONG", "từ khoá CAFE".
  final String? reason;

  /// Chưa có danh mục, hoặc mới chỉ là đoán.
  bool get needsReview => categoryId == null || (source?.isGuess ?? true);
}

/// Ngưỡng giống nhau của tập chữ (Jaccard) để coi là cùng người nhận.
const kSimilarThreshold = 0.75;

/// Đoán danh mục cho một người nhận đã chuẩn hoá, chỉ trong máy.
///
/// Thứ tự, gặp là dừng: quy tắc đúng tên → tên gần giống → từ khoá → không
/// có. Mọi bước chỉ xét danh mục cùng chiều [flow] với giao dịch.
CategoryGuess categorize({
  required String receiverKey,
  required String flow,
  required List<RuleEntry> rules,
  List<KeywordEntry> keywords = const [],
  bool useSimilar = true,
  bool useKeywords = true,
}) {
  if (receiverKey.isEmpty) return CategoryGuess.none;
  final sameFlow = rules.where((r) => r.flow == flow).toList();

  for (final r in sameFlow) {
    if (r.key == receiverKey) {
      return CategoryGuess(r.categoryId, CategorySource.name);
    }
  }

  final tokens = receiverKey.split(' ');

  if (useSimilar) {
    RuleEntry? best;
    var bestScore = 0.0;
    for (final r in sameFlow) {
      final score = similarity(tokens, r.key.split(' '));
      if (score < kSimilarThreshold) continue;
      if (score > bestScore ||
          (score == bestScore && r.hitCount > (best?.hitCount ?? -1))) {
        best = r;
        bestScore = score;
      }
    }
    if (best != null) {
      return CategoryGuess(
        best.categoryId,
        CategorySource.similar,
        reason: 'giống "${best.displayName.isEmpty ? best.key : best.displayName}"',
      );
    }
  }

  if (useKeywords) {
    KeywordEntry? best;
    var bestLen = 0;
    var tie = false;
    for (final k in keywords) {
      if (k.flow != flow) continue;
      final kt = k.keyword.split(' ');
      if (!_containsRun(tokens, kt)) continue;
      // Từ khoá dài hơn cụ thể hơn: "GRAB FOOD" thắng "GRAB".
      final len = kt.length * 100 + k.keyword.length;
      if (len > bestLen) {
        best = k;
        bestLen = len;
        tie = false;
      } else if (len == bestLen && k.categoryId != best?.categoryId) {
        tie = true;
      }
    }
    if (best != null && !tie) {
      return CategoryGuess(
        best.categoryId,
        CategorySource.keyword,
        reason: 'từ khoá "${best.keyword}"',
      );
    }
  }

  return CategoryGuess.none;
}

/// 1 nếu cùng tập chữ, hoặc một bên là phần đầu nguyên chữ của bên kia và
/// dài từ 2 chữ ("PHUC LONG" với "PHUC LONG CN Q3"); còn lại là Jaccard.
double similarity(List<String> a, List<String> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final shorter = a.length <= b.length ? a : b;
  final longer = identical(shorter, a) ? b : a;
  if (shorter.length >= 2 && _startsWithRun(longer, shorter)) return 1;
  final sa = a.toSet(), sb = b.toSet();
  final inter = sa.intersection(sb).length;
  return inter / sa.union(sb).length;
}

bool _startsWithRun(List<String> list, List<String> prefix) {
  if (prefix.length > list.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (list[i] != prefix[i]) return false;
  }
  return true;
}

/// [needle] xuất hiện liền mạch, nguyên chữ, trong [hay]: "BE" không khớp
/// trong "BEP".
bool _containsRun(List<String> hay, List<String> needle) {
  if (needle.isEmpty || needle.length > hay.length) return false;
  for (var i = 0; i + needle.length <= hay.length; i++) {
    var ok = true;
    for (var k = 0; k < needle.length; k++) {
      if (hay[i + k] != needle[k]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

/// Từ khoá có sẵn, theo TÊN danh mục gieo sẵn của app. Danh mục đã đổi tên
/// hay xoá thì bỏ qua từ khoá của nó.
const kBuiltInKeywords = <String, List<String>>{
  'Ăn uống': [
    'CAFE', 'CA PHE', 'COFFEE', 'TRA SUA', 'HIGHLANDS', 'PHUC LONG',
    'KATINAT', 'STARBUCKS', 'GRABFOOD', 'GRAB FOOD', 'SHOPEEFOOD',
    'SHOPEE FOOD', 'BAEMIN', 'KFC', 'LOTTERIA', 'JOLLIBEE', 'PIZZA',
    'BANH MI', 'NHA HANG', 'QUAN AN',
  ],
  'Đi lại': [
    'GRAB', 'BE', 'XANH SM', 'GSM', 'PETROLIMEX', 'XANG', 'GUI XE', 'VETC',
    'EPASS', 'VIETJET', 'VIETNAM AIRLINES',
  ],
  'Mua sắm': [
    'SHOPEE', 'LAZADA', 'TIKI', 'TIKTOK SHOP', 'WINMART', 'BACH HOA XANH',
    'CIRCLE K', 'GS25', 'COOPMART', 'CO OP', 'MINISTOP', 'FAMILYMART',
    'UNIQLO', 'DIEN MAY XANH', 'THE GIOI DI DONG',
  ],
  'Hoá đơn': [
    'EVN', 'TIEN DIEN', 'TIEN NUOC', 'VNPT', 'VIETTEL', 'FPT TELECOM',
    'MOBIFONE', 'VINAPHONE',
  ],
  'Giải trí': ['CGV', 'LOTTE CINEMA', 'GALAXY CINEMA', 'NETFLIX', 'SPOTIFY'],
  'Sức khoẻ': ['PHARMACITY', 'LONG CHAU', 'NHA THUOC', 'BENH VIEN'],
  'Lương': ['LUONG', 'SALARY'],
};
