import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/domain/autotrack/categorizer.dart';
import 'package:moneybook/core/domain/autotrack/receiver_normalizer.dart';

/// Phân loại trong máy: chuẩn hoá người nhận rồi đoán danh mục.
void main() {
  group('normalizeReceiver', () {
    test('bỏ dấu, ký hiệu, mã tham chiếu và chữ ngân hàng tự thêm', () {
      expect(normalizeReceiver('GRAB*FOOD 8812 TT QR'), 'GRAB FOOD');
      expect(normalizeReceiver('Cà phê Phúc Long - CN Q3'),
          'CA PHE PHUC LONG CN Q3');
      expect(normalizeReceiver('NGUYEN VAN A chuyen tien'), 'NGUYEN VAN A');
      expect(normalizeReceiver('Đặng Thị Đào'), 'DANG THI DAO');
    });

    test('nội dung chuyển khoản thật của BIDV', () {
      expect(
        normalizeReceiver(
          'TKThe :1234560145, tai Eximbank. NGUYEN VAN A chuyen tien '
          '-CTLNHIDI000017560393038-1/1-CRE-002',
        ),
        'EXIMBANK NGUYEN VAN A',
      );
    });

    test('"chuyen tien" là cụm bỏ đi, nhưng tên TIEN vẫn giữ', () {
      expect(normalizeReceiver('NGUYEN VAN TIEN chuyen tien'),
          'NGUYEN VAN TIEN');
    });

    test('"THE" trong tên quán không bị bỏ', () {
      expect(normalizeReceiver('THE COFFEE HOUSE'), 'THE COFFEE HOUSE');
    });

    test('chỉ toàn chữ ngân hàng thêm vào thì rỗng: không đủ để học', () {
      expect(normalizeReceiver('THANH TOAN'), '');
      expect(normalizeReceiver('Thanh toan QR 123456789'), '');
      expect(normalizeReceiver(null), '');
    });
  });

  group('categorize', () {
    const rules = [
      RuleEntry(key: 'PHUC LONG CN Q3', flow: 'expense', categoryId: 1,
          displayName: 'Phúc Long CN Q3', hitCount: 5),
      RuleEntry(key: 'NGUYEN VAN A', flow: 'income', categoryId: 10),
      RuleEntry(key: 'NGUYEN VAN A', flow: 'expense', categoryId: 2),
    ];
    const keywords = [
      KeywordEntry(keyword: 'CAFE', flow: 'expense', categoryId: 1),
      KeywordEntry(keyword: 'GRAB', flow: 'expense', categoryId: 3),
      KeywordEntry(keyword: 'GRAB FOOD', flow: 'expense', categoryId: 1),
      KeywordEntry(keyword: 'BE', flow: 'expense', categoryId: 3),
      KeywordEntry(keyword: 'LUONG', flow: 'income', categoryId: 11),
      KeywordEntry(keyword: 'SHOP', flow: 'expense', categoryId: 4),
      KeywordEntry(keyword: 'MART', flow: 'expense', categoryId: 5),
    ];

    CategoryGuess guess(String key, {String flow = 'expense'}) => categorize(
      receiverKey: key,
      flow: flow,
      rules: rules,
      keywords: keywords,
    );

    test('đúng người nhận: tin được, không cần xem lại', () {
      final g = guess('PHUC LONG CN Q3');
      expect(g.categoryId, 1);
      expect(g.source, CategorySource.name);
      expect(g.needsReview, isFalse);
    });

    test('cùng người nhưng khác chiều tiền thì theo quy tắc của chiều đó', () {
      expect(guess('NGUYEN VAN A').categoryId, 2);
      expect(guess('NGUYEN VAN A', flow: 'income').categoryId, 10);
    });

    test('tên gần giống: đoán, phải xem lại', () {
      final g = guess('PHUC LONG CN Q3 VINCOM');
      expect(g.categoryId, 1);
      expect(g.source, CategorySource.similar);
      expect(g.needsReview, isTrue);
      expect(g.reason, contains('Phúc Long CN Q3'));
    });

    test('ngắn hơn nhưng là phần đầu nguyên chữ, từ 2 chữ: giống', () {
      expect(guess('PHUC LONG').source, CategorySource.similar);
    });

    test('một chữ chung không đủ gọi là giống', () {
      expect(guess('PHUC THINH').source, isNot(CategorySource.similar));
    });

    test('từ khoá: đoán, chỉ khớp nguyên chữ', () {
      final g = guess('HIGHLAND CAFE Q1');
      expect(g.categoryId, 1);
      expect(g.source, CategorySource.keyword);
      expect(g.needsReview, isTrue);
      expect(guess('BEP NHA LAN').categoryId, isNull,
          reason: '"BE" không được khớp trong "BEP"');
    });

    test('từ khoá dài hơn thắng: GRAB FOOD là ăn uống, GRAB là đi lại', () {
      expect(guess('GRAB FOOD').categoryId, 1);
      expect(guess('GRAB').categoryId, 3);
    });

    test('hai từ khoá cùng độ dài, khác danh mục: không đoán bừa', () {
      expect(guess('MART SHOP').categoryId, isNull);
    });

    test('từ khoá của danh mục thu không gắn vào khoản chi', () {
      expect(guess('TIEN LUONG').categoryId, isNull);
      expect(guess('TIEN LUONG', flow: 'income').categoryId, 11);
    });

    test('không có gì khớp, hoặc người nhận rỗng: chưa phân loại', () {
      expect(guess('ABC XYZ'), isA<CategoryGuess>()
          .having((g) => g.categoryId, 'categoryId', isNull)
          .having((g) => g.needsReview, 'needsReview', isTrue));
      expect(guess('').categoryId, isNull);
    });

    test('tắt đoán theo tên giống / từ khoá thì chỉ còn quy tắc đúng', () {
      CategoryGuess off(String key) => categorize(
        receiverKey: key,
        flow: 'expense',
        rules: rules,
        keywords: keywords,
        useSimilar: false,
        useKeywords: false,
      );
      expect(off('PHUC LONG').categoryId, isNull);
      expect(off('CAFE').categoryId, isNull);
      expect(off('PHUC LONG CN Q3').categoryId, 1);
    });
  });

  test('similarity', () {
    expect(similarity(['A', 'B'], ['A', 'B']), 1);
    expect(similarity(['A', 'B'], ['A', 'B', 'C']), 1, reason: 'phần đầu');
    expect(similarity(['A'], ['A', 'B']), 0.5, reason: 'một chữ thì không');
    expect(similarity(['B', 'C', 'D', 'E'], ['A', 'B', 'C', 'D', 'E']), 0.8);
  });
}
