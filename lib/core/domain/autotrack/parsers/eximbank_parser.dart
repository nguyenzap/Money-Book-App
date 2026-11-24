import 'notification_parser.dart';

/// Eximbank.
///
/// Dòng đầu mang tên chi nhánh và thời gian, ngược thứ tự với BIDV. Tiêu đề
/// thông báo là `Thông báo Eximbank`, không phải dòng đầu:
/// ```
/// Eximbank Mỹ Tho: 17/11/2026 20:25
/// Tài khoản: <số tài khoản>
/// Giao dịch: -328,000 VND
/// Số dư: 7,284,762 VND
/// Nội dung: THANH TOAN
/// Số tham chiếu: <mã>
/// ```
class EximbankParser extends LabeledLinesParser {
  const EximbankParser();

  @override
  String get id => 'eximbank';

  @override
  int get version => 2;

  @override
  String get displayName => 'Eximbank';

  // com.vnpay.EximBankOmni đã xác nhận trên máy thật (2026-11).
  @override
  Set<String> get knownPackages => const {'com.vnpay.EximBankOmni'};

  // Tên chi nhánh không cố định, chỉ cần có.
  @override
  RegExp get header => RegExp(
    r'^eximbank [^:]+: (?<time>\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2})$',
  );

  @override
  Field? get headerTimeField => Field.timeDmyHm;

  @override
  Map<String, Field> get labels => const {
    'Tài khoản': Field.account,
    'Giao dịch': Field.signedAmount,
    'Số dư': Field.balance,
    'Nội dung': Field.receiver,
    'Số tham chiếu': Field.reference,
  };
}
