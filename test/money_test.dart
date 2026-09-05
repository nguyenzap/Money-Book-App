import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/format/dates.dart';
import 'package:moneybook/core/format/money.dart';

void main() {
  group('hiển thị tiền', () {
    test('chèn dấu chấm ngăn cách hàng nghìn', () {
      expect(groupDigits(0), '0');
      expect(groupDigits(999), '999');
      expect(groupDigits(1000), '1.000');
      expect(groupDigits(50000), '50.000');
      expect(groupDigits(1250000), '1.250.000');
      expect(groupDigits(123456789), '123.456.789');
    });

    test('số âm giữ nguyên dấu trừ', () {
      expect(groupDigits(-50000), '-50.000');
      expect(formatVnd(-1250000), '-1.250.000 ₫');
    });

    test('formatVndSigned chỉ thêm dấu cộng cho số dương', () {
      expect(formatVndSigned(50000), '+50.000 ₫');
      expect(formatVndSigned(-50000), '-50.000 ₫');
      expect(formatVndSigned(0), '0 ₫');
    });

    test('rút gọn cho chỗ chật', () {
      expect(formatVndShort(500), '500');
      expect(formatVndShort(50000), '50k');
      expect(formatVndShort(1000000), '1tr');
      expect(formatVndShort(1250000), '1.25tr');
      expect(formatVndShort(2000000000), '2 tỷ');
      expect(formatVndShort(-50000), '-50k');
    });
  });

  group('đọc lại số tiền người dùng gõ', () {
    test('bỏ hết dấu chấm trước khi chuyển thành số', () {
      expect(parseVnd('1.250.000'), 1250000);
      expect(parseVnd('50.000'), 50000);
      expect(parseVnd('999'), 999);
    });

    test('chuỗi rỗng hoặc rác trả về 0 thay vì ném lỗi', () {
      expect(parseVnd(''), 0);
      expect(parseVnd('abc'), 0);
      expect(parseVnd('   '), 0);
    });

    test('bỏ qua ký tự lạ lẫn vào', () {
      expect(parseVnd('1.250.000 ₫'), 1250000);
      expect(parseVnd('50,000'), 50000);
    });

    test('gõ vào rồi đọc ra phải khớp', () {
      for (final value in [0, 1, 999, 1000, 50000, 1250000, 987654321]) {
        expect(parseVnd(groupDigits(value)), value, reason: 'với $value');
      }
    });
  });

  group('ThousandsFormatter', () {
    const formatter = ThousandsFormatter();

    TextEditingValue apply(String oldText, String newText) {
      return formatter.formatEditUpdate(
        TextEditingValue(text: oldText),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        ),
      );
    }

    test('tự chèn dấu chấm khi đang gõ', () {
      expect(apply('', '5').text, '5');
      expect(apply('5', '50').text, '50');
      expect(apply('500', '5000').text, '5.000');
      expect(apply('5.000', '50000').text, '50.000');
    });

    test('con trỏ luôn ở cuối sau khi định dạng lại', () {
      final result = apply('500', '5000');
      expect(result.selection.baseOffset, result.text.length);
    });

    test('xoá hết thì về chuỗi rỗng', () {
      expect(apply('5.000', '').text, '');
    });

    test('chặn số dài quá để khỏi tràn khi cộng tổng', () {
      final huge = '9' * 16;
      expect(apply('123', huge).text, '123', reason: 'giữ nguyên giá trị cũ');
    });
  });

  group('khoá ngày tháng', () {
    test('dayKey là yyyymmdd theo giờ địa phương', () {
      expect(dayKeyOf(DateTime(2026, 9, 6)), 20260906);
      expect(dayKeyOf(DateTime(2026, 12, 31, 23, 59)), 20261231);
      expect(dayKeyOf(DateTime(2026, 1, 1, 0, 0)), 20260101);
    });

    test('monthKey là yyyymm', () {
      expect(monthKeyOf(DateTime(2026, 9, 6)), 202609);
      expect(monthKeyOf(DateTime(2026, 1, 31)), 202601);
    });

    test('lùi tháng qua mốc năm', () {
      expect(previousMonthKey(202609), 202608);
      expect(previousMonthKey(202601), 202512);
    });

    test('tiến tháng qua mốc năm', () {
      expect(nextMonthKey(202609), 202610);
      expect(nextMonthKey(202612), 202701);
    });

    test('lùi rồi tiến thì về chỗ cũ', () {
      for (final key in [202601, 202606, 202612, 202702]) {
        expect(nextMonthKey(previousMonthKey(key)), key);
      }
    });

    test('nhãn tháng bằng tiếng Việt', () {
      expect(monthKeyLabel(202609), 'Tháng 9/2026');
      expect(monthKeyLabel(202512), 'Tháng 12/2025');
    });

    test('kẹp ngày về ngày cuối tháng nếu tháng đó không có', () {
      // Mẫu định kỳ đặt vào ngày 31 vẫn phải chạy được ở tháng chỉ có 28 ngày.
      expect(clampDayOfMonth(2026, 2, 31), DateTime(2026, 2, 28));
      expect(clampDayOfMonth(2024, 2, 31), DateTime(2024, 2, 29));
      expect(clampDayOfMonth(2026, 4, 31), DateTime(2026, 4, 30));
      expect(clampDayOfMonth(2026, 1, 31), DateTime(2026, 1, 31));
    });
  });
}
