import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/format/money.dart';

/// Mô phỏng một lần sửa văn bản: người dùng đang ở [oldText] với con trỏ tại
/// [oldCaret], thao tác xong thành [newText] với con trỏ tại [newCaret].
TextEditingValue edit(
  String oldText,
  int oldCaret,
  String newText,
  int newCaret,
) {
  const formatter = ThousandsFormatter();
  return formatter.formatEditUpdate(
    TextEditingValue(
      text: oldText,
      selection: TextSelection.collapsed(offset: oldCaret),
    ),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    ),
  );
}

void main() {
  group('con trỏ ở yên chỗ đang sửa', () {
    test('xoá chữ số giữa số thì con trỏ không nhảy về cuối', () {
      // "13.000", con trỏ sau số 3 (vị trí 2), bấm xoá -> "1.000".
      // Con trỏ phải nằm sau số 1, tức vị trí 1.
      final result = edit('13.000', 2, '1.000', 1);

      expect(result.text, '1.000');
      expect(result.selection.baseOffset, 1,
          reason: 'con trỏ phải ở ngay sau số 1, không bị đẩy về cuối');
    });

    test('xoá xong gõ lại thì chữ số mới vào đúng chỗ vừa xoá', () {
      // Sau khi xoá số 3 ở trên, người dùng gõ số 5 -> "15.000".
      final result = edit('1.000', 1, '15.000', 2);

      expect(result.text, '15.000');
      expect(result.selection.baseOffset, 2);
    });

    test('xoá chữ số đầu tiên', () {
      // "13.000" con trỏ ở vị trí 1, xoá số 1 -> "3.000", con trỏ về đầu.
      final result = edit('13.000', 1, '3.000', 0);

      expect(result.text, '3.000');
      expect(result.selection.baseOffset, 0);
    });

    test('gõ thêm ở cuối thì con trỏ vẫn ở cuối', () {
      final result = edit('1.300', 5, '13.000', 6);

      expect(result.text, '13.000');
      expect(result.selection.baseOffset, 6);
    });

    test('gõ chữ số vào giữa', () {
      // "1.300" con trỏ sau số 3 (vị trí 3), gõ số 5 -> "13.500".
      final result = edit('1.300', 3, '13.500', 4);

      expect(result.text, '13.500');
      expect(result.selection.baseOffset, 4,
          reason: 'ngay sau số 5 vừa gõ');
    });

    test('dấu chấm mới xuất hiện không làm lệch con trỏ', () {
      // "999" con trỏ ở cuối, gõ thêm 9 -> "9.999".
      // Chuỗi dài thêm 2 ký tự (một số và một dấu chấm) nên con trỏ phải nhảy
      // đúng 2 chỗ chứ không phải 1.
      final result = edit('999', 3, '9999', 4);

      expect(result.text, '9.999');
      expect(result.selection.baseOffset, 5);
    });

    test('dấu chấm biến mất không làm lệch con trỏ', () {
      // "9.999" xoá số cuối -> "999", không còn dấu chấm.
      final result = edit('9.999', 5, '9.99', 4);

      expect(result.text, '999');
      expect(result.selection.baseOffset, 3);
    });

    test('xoá đúng dấu chấm thì số bị nuốt theo', () {
      // Người dùng đặt con trỏ sau dấu chấm của "13.000" và bấm xoá.
      // Dấu chấm không phải chữ số nên chuỗi số không đổi, chỉ định dạng lại.
      final result = edit('13.000', 3, '13000', 2);

      expect(result.text, '13.000');
      // Hai chữ số đứng trước con trỏ -> ngay sau số 3.
      expect(result.selection.baseOffset, 2);
    });

    test('xoá sạch thì về chuỗi rỗng', () {
      final result = edit('13.000', 6, '', 0);
      expect(result.text, '');
    });

    test('chọn cả rồi thay bằng số mới', () {
      final result = edit('13.000', 6, '5', 1);
      expect(result.text, '5');
      expect(result.selection.baseOffset, 1);
    });

    test('số quá dài thì giữ nguyên giá trị cũ', () {
      final huge = '9' * 16;
      final result = edit('123', 3, huge, huge.length);
      expect(result.text, '123');
    });
  });

  group('giá trị số vẫn đúng sau mọi thao tác', () {
    test('định dạng lại không làm sai con số', () {
      expect(parseVnd(edit('13.000', 2, '1.000', 1).text), 1000);
      expect(parseVnd(edit('1.300', 3, '13.500', 4).text), 13500);
      expect(parseVnd(edit('999', 3, '9999', 4).text), 9999);
    });
  });
}
