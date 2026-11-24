import '../parsed_txn.dart';
import '../text_fold.dart';
import '../vnd_amount.dart';

/// Đọc thông báo của MỘT ứng dụng ngân hàng.
///
/// Mỗi ngân hàng một lớp, viết tay trong mã nguồn và kiểm bằng các mẫu thật
/// trong `test/fixtures/autotrack/`. Ngân hàng đổi câu chữ thì sửa lớp đó,
/// thêm mẫu, tăng [version] rồi phát hành bản mới: các thông báo không đọc
/// được trong lúc chờ sẽ được đọc lại sau khi cập nhật.
///
/// Parser là hàm thuần: không I/O, không đồng hồ, không cài đặt.
abstract class NotificationParser {
  const NotificationParser();

  /// Khoá cố định, lưu vào từng thông báo. Không được đổi.
  String get id;

  /// Tăng mỗi lần đổi cách đọc. Thông báo `unmatched` / `failed` đọc bằng
  /// phiên bản cũ hơn sẽ được đọc lại.
  int get version;

  /// Tên hiện trong cài đặt.
  String get displayName;

  /// Tên gói Android quen thuộc của app ngân hàng. Chỉ là gợi ý mặc định:
  /// người dùng chọn lại được trong cài đặt nếu máy dùng gói khác.
  Set<String> get knownPackages;

  ParseResult parse(String title, String text);
}

/// Các trường một dòng `Nhãn: giá trị` có thể mang.
enum Field {
  /// `18:57 21/11/2026`
  timeHmDmy,

  /// `21/11/2026 18:57`
  timeDmyHm,
  account,

  /// `-80,000 VND` — dấu là chiều tiền, bắt buộc.
  signedAmount,
  balance,
  receiver,
  reference,
}

/// Thông báo dạng một dòng đầu cố định, theo sau là các dòng `Nhãn: giá trị`.
///
/// Cả BIDV lẫn Eximbank đều viết như vậy. Đọc từng dòng theo nhãn thay vì một
/// regex dài cho cả thông báo, nên ngân hàng thêm hay đảo thứ tự một dòng thì
/// vẫn đọc được.
///
/// Một thông báo chỉ được coi là giao dịch khi CÓ dòng đầu khớp [header] VÀ
/// có dòng số tiền. OTP hay khuyến mãi không có đủ hai thứ đó nên bị bỏ qua.
abstract class LabeledLinesParser extends NotificationParser {
  const LabeledLinesParser();

  /// So với dòng đầu ĐÃ GẤP bằng [foldVi] (chữ thường, không dấu). Nhóm có
  /// tên `time`, nếu có, được đọc theo [headerTimeField].
  RegExp get header;

  Field? get headerTimeField => null;

  /// Nhãn viết nguyên văn như trong thông báo; khi so sẽ được gấp.
  Map<String, Field> get labels;

  @override
  ParseResult parse(String title, String text) {
    final lines = '$title\n$text'
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final headerAt = lines.indexWhere((l) => header.hasMatch(foldVi(l)));
    if (headerAt < 0) return const ParseIgnored('không có dòng đầu');

    final folded = {
      for (final e in labels.entries) foldVi(e.key): e.value,
    };
    final values = <Field, String>{};

    final headerTime = header.firstMatch(foldVi(lines[headerAt]));
    if (headerTimeField != null && headerTime != null) {
      final names = headerTime.groupNames;
      if (names.contains('time')) {
        final t = headerTime.namedGroup('time');
        if (t != null) values[headerTimeField!] = t;
      }
    }

    Field? previous;
    for (final line in lines.skip(headerAt + 1)) {
      // Cắt ở dấu ':' ĐẦU TIÊN: giá trị thời gian cũng có ':'.
      final colon = line.indexOf(':');
      final field = colon <= 0
          ? null
          : folded[foldVi(line.substring(0, colon))];
      if (field == null) {
        // Nội dung chuyển khoản dài có thể xuống dòng: dòng không có nhãn
        // ngay sau nó là phần tiếp theo. Dòng lạ ở chỗ khác thì bỏ qua,
        // không làm hỏng cả tin.
        if (previous == Field.receiver && values[Field.receiver] != null) {
          values[Field.receiver] = '${values[Field.receiver]} $line';
        }
        continue;
      }
      previous = field;
      final value = line.substring(colon + 1).trim();
      if (value.isEmpty) continue; // để trống nghĩa là không có
      values.putIfAbsent(field, () => value);
    }

    final amountRaw = values[Field.signedAmount];
    if (amountRaw == null) return const ParseIgnored('không có dòng số tiền');

    final signed = parseVnd(amountRaw, requireSign: true);
    if (signed == null || signed == 0) {
      return ParseFailed('không đọc được số tiền "$amountRaw"');
    }

    final balanceRaw = values[Field.balance];
    return ParseMatched(
      ParsedTxn(
        direction: signed < 0 ? TxDirection.expense : TxDirection.income,
        amount: signed.abs(),
        occurredAt: _time(values),
        accountSuffix: _suffix(values[Field.account]),
        balanceAfter: balanceRaw == null ? null : parseVnd(balanceRaw),
        receiver: values[Field.receiver],
        reference: values[Field.reference],
      ),
    );
  }

  static DateTime? _time(Map<Field, String> values) {
    final hmDmy = values[Field.timeHmDmy];
    if (hmDmy != null) {
      final m = RegExp(
        r'^(\d{1,2}):(\d{2})(?::\d{2})?\s+(\d{1,2})/(\d{1,2})/(\d{4})$',
      ).firstMatch(hmDmy);
      if (m != null) return _date(m[5]!, m[4]!, m[3]!, m[1]!, m[2]!);
    }
    final dmyHm = values[Field.timeDmyHm];
    if (dmyHm != null) {
      final m = RegExp(
        r'^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})(?::\d{2})?$',
      ).firstMatch(dmyHm);
      if (m != null) return _date(m[3]!, m[2]!, m[1]!, m[4]!, m[5]!);
    }
    return null;
  }

  static DateTime? _date(String y, String mo, String d, String h, String mi) {
    final year = int.parse(y), month = int.parse(mo), day = int.parse(d);
    final hour = int.parse(h), minute = int.parse(mi);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (hour > 23 || minute > 59) return null;
    final dt = DateTime(year, month, day, hour, minute);
    // 31/02 bị DateTime đẩy sang tháng 3: coi như không đọc được.
    if (dt.month != month || dt.day != day) return null;
    return dt;
  }

  /// Tối đa 4 chữ số cuối, đủ để phân biệt tài khoản mà không lưu cả số.
  static String? _suffix(String? account) {
    if (account == null) return null;
    final digits = account.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  }
}
