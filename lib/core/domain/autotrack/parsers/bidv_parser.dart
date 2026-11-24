import 'notification_parser.dart';

/// BIDV SmartBanking.
///
/// Thông báo đẩy thật có tiêu đề `Thông báo BIDV`, thân bắt đầu ngay ở dòng
/// thời gian. Cùng nội dung đó ở chỗ khác (hộp thư trong app) lại mở đầu bằng
/// `BIDV xin thông báo tới Quý khách`, nên nhận cả hai làm dòng đầu.
///
/// ```
/// Thông báo BIDV                              ← tiêu đề
/// Thời gian giao dịch: 18:57 21/11/2026
/// Tài khoản thanh toán: <số tài khoản>
/// Số tiền GD: -80,000 VND
/// Số dư cuối: 2,702,202 VND
/// Nội dung giao dịch: <nội dung>
/// Mã giao dịch: <mã>
/// ```
class BidvParser extends LabeledLinesParser {
  const BidvParser();

  @override
  String get id => 'bidv';

  @override
  int get version => 2;

  @override
  String get displayName => 'BIDV SmartBanking';

  @override
  Set<String> get knownPackages => const {'com.vnpay.bidv'};

  @override
  RegExp get header =>
      RegExp(r'^(thong bao bidv|bidv xin thong bao toi quy khach)$');

  @override
  Map<String, Field> get labels => const {
    'Thời gian giao dịch': Field.timeHmDmy,
    'Tài khoản thanh toán': Field.account,
    'Số tiền GD': Field.signedAmount,
    'Số dư cuối': Field.balance,
    'Nội dung giao dịch': Field.receiver,
    'Mã giao dịch': Field.reference,
  };
}
