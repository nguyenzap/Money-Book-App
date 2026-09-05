import 'package:flutter/material.dart';

/// Loại giao dịch.
///
/// Đây là nguồn sự thật DUY NHẤT về dấu tiền trong toàn bộ app.
///
/// Quy tắc bất di bất dịch:
///   * `amount` trong DB LUÔN là số dương (số đồng VND).
///   * Dấu (+/-) không bao giờ được lưu, mà luôn suy ra từ [TxKind].
///   * Mỗi giao dịch có tối đa 2 "chân ví": walletFrom (tiền RA) và
///     walletTo (tiền VÀO). Số dư của ví W luôn được tính bằng đúng một
///     công thức, không phân biệt loại giao dịch:
///
///       balance(W) = initialBalance
///                  + tổng amount của các giao dịch có walletTo   == W
///                  - tổng amount của các giao dịch có walletFrom == W
///
/// Nhờ vậy không có chỗ nào trong app được phép viết
/// `if (kind == expense) balance -= amount` — đó là nguồn gốc của mọi sai lệch
/// sổ sách.
enum TxKind {
  /// Tiền vào ví từ bên ngoài: lương, thưởng, được cho...
  income,

  /// Tiền ra khỏi ví: ăn uống, xăng xe...
  expense,

  /// Chuyển tiền giữa 2 ví của chính mình. Không phải thu, cũng không phải chi.
  transfer,

  /// Vay nợ: mình NHẬN tiền của người ta, và mắc nợ họ.
  borrow,

  /// Trả nợ: mình TRẢ lại tiền đã vay.
  repay,

  /// Cho mượn / trả dùm: mình ĐƯA tiền, người ta nợ mình.
  lend,

  /// Thu nợ: người ta TRẢ lại tiền đã mượn của mình.
  collect,

  /// Điều chỉnh số dư cho khớp thực tế (đếm lại ví, phí ngân hàng lẻ...).
  adjust,
}

extension TxKindX on TxKind {
  /// Giá trị lưu xuống DB. Cố định, không được đổi — đổi là hỏng dữ liệu cũ.
  String get id => name;

  static TxKind fromId(String id) =>
      TxKind.values.firstWhere((k) => k.name == id);

  String get label => switch (this) {
        TxKind.income => 'Thu nhập',
        TxKind.expense => 'Chi tiêu',
        TxKind.transfer => 'Chuyển ví',
        TxKind.borrow => 'Vay nợ',
        TxKind.repay => 'Trả nợ',
        TxKind.lend => 'Cho mượn',
        TxKind.collect => 'Thu nợ',
        TxKind.adjust => 'Điều chỉnh số dư',
      };

  /// Mô tả ngắn hiển thị dưới chip chọn loại, giúp khỏi chọn nhầm.
  String get hint => switch (this) {
        TxKind.income => 'Tiền vào ví',
        TxKind.expense => 'Tiền ra khỏi ví',
        TxKind.transfer => 'Giữa 2 ví của bạn',
        TxKind.borrow => 'Bạn nhận tiền, nợ người ta',
        TxKind.repay => 'Bạn trả lại tiền đã vay',
        TxKind.lend => 'Bạn đưa tiền, người ta nợ bạn',
        TxKind.collect => 'Người ta trả lại tiền',
        TxKind.adjust => 'Sửa cho khớp số dư thật',
      };

  IconData get icon => switch (this) {
        TxKind.income => Icons.arrow_downward,
        TxKind.expense => Icons.arrow_upward,
        TxKind.transfer => Icons.swap_horiz,
        TxKind.borrow => Icons.south_west,
        TxKind.repay => Icons.north_east,
        TxKind.lend => Icons.north_east,
        TxKind.collect => Icons.south_west,
        TxKind.adjust => Icons.tune,
      };

  /// Giao dịch này có cần chọn danh mục không.
  bool get needsCategory => this == TxKind.income || this == TxKind.expense;

  /// Giao dịch này có cần chọn người (chủ nợ / con nợ) không.
  bool get needsPerson => const {
        TxKind.borrow,
        TxKind.repay,
        TxKind.lend,
        TxKind.collect,
      }.contains(this);

  /// Có thể dùng chân ví nguồn (tiền đi ra) không.
  ///
  /// [TxKind.adjust] dùng được cả hai chân vì hướng của nó phụ thuộc vào dấu
  /// của chênh lệch, chỉ biết được lúc người dùng nhập số dư thật: số dư giảm
  /// thì tiền "ra" (chân from), tăng thì tiền "vào" (chân to). Đúng một trong
  /// hai chân được dùng cho mỗi giao dịch điều chỉnh cụ thể.
  bool get needsWalletFrom => const {
        TxKind.expense,
        TxKind.transfer,
        TxKind.repay,
        TxKind.lend,
        TxKind.adjust,
      }.contains(this);

  /// Có thể dùng chân ví đích (tiền đi vào) không. Xem thêm [needsWalletFrom].
  bool get needsWalletTo => const {
        TxKind.income,
        TxKind.transfer,
        TxKind.borrow,
        TxKind.collect,
        TxKind.adjust,
      }.contains(this);

  /// Có tính vào thống kê thu/chi không.
  ///
  /// Chỉ [income] và [expense]. Chuyển ví không phải chi tiêu (tiền vẫn là của
  /// mình); vay/cho mượn cũng không (đó là dòng nợ, không phải tiêu dùng); điều
  /// chỉnh số dư càng không. Tính chúng vào sẽ thổi phồng con số một cách vô
  /// nghĩa.
  bool get countsInStats => this == TxKind.income || this == TxKind.expense;

  /// Có thuộc sổ nợ không.
  bool get isDebtKind => needsPerson;

  /// Thay đổi công nợ với người liên quan.
  ///
  ///   * Kết quả > 0: người đó nợ mình THÊM [amount].
  ///   * Kết quả < 0: mình nợ người đó THÊM [amount].
  ///
  /// Cách nhớ: hướng công nợ trùng hướng dòng tiền. Tiền rời ví mình
  /// ([lend], [repay]) thì cán cân nghiêng về phía có lợi cho mình (+);
  /// tiền vào ví mình ([borrow], [collect]) thì ngược lại (-).
  ///
  /// Giá trị này được lưu sẵn vào cột `debt_delta` thay vì suy ra lúc truy vấn,
  /// để sổ nợ chỉ còn là một phép SUM, và để xử lý được cả trường hợp xoá nợ
  /// (write-off) — khi đó không có ví nào bị đụng tới nên không thể suy ngược
  /// từ dòng tiền.
  int debtDelta(int amount) => switch (this) {
        TxKind.lend || TxKind.repay => amount,
        TxKind.borrow || TxKind.collect => -amount,
        _ => 0,
      };
}

/// Các loại giao dịch hiện trên thanh chọn nhanh, theo thứ tự dùng nhiều nhất.
const kQuickTxKinds = [
  TxKind.expense,
  TxKind.income,
  TxKind.transfer,
];

/// Bốn loại thuộc sổ nợ, gom lại cho UI.
const kDebtTxKinds = [
  TxKind.lend,
  TxKind.collect,
  TxKind.borrow,
  TxKind.repay,
];
