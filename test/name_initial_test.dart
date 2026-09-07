import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/format/names.dart';

void main() {
  group('chữ cái đại diện cho tên tiếng Việt', () {
    test('lấy chữ đầu của TỪ CUỐI, không phải từ đầu', () {
      // Người Việt gọi nhau bằng tên, không bằng họ.
      expect(initialOf('Nguyễn Văn Nam'), 'N');
      expect(initialOf('Trần Thị Bích'), 'B');
      expect(initialOf('Lê Hoàng Long'), 'L');
      expect(initialOf('Phạm Minh Tuấn'), 'T');
    });

    test('tên một chữ thì lấy luôn chữ đó', () {
      expect(initialOf('Nam'), 'N');
      expect(initialOf('Hùng'), 'H');
    });

    test('giữ nguyên dấu tiếng Việt', () {
      expect(initialOf('Nguyễn Thị Ánh'), 'Á');
      expect(initialOf('Đặng Đức Đạt'), 'Đ');
      expect(initialOf('Vũ Ước'), 'Ư');
    });

    test('bỏ qua khoảng trắng thừa', () {
      expect(initialOf('  Nguyễn   Văn   Nam  '), 'N');
      expect(initialOf('Trần  Bích'), 'B');
    });

    test('tên rỗng thì trả dấu hỏi', () {
      expect(initialOf(''), '?');
      expect(initialOf('   '), '?');
    });

    test('biệt danh có ký tự lạ vẫn dùng được', () {
      expect(initialOf('anh Ba'), 'B');
      expect(initialOf('chị hai'), 'H');
    });
  });
}
