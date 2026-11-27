import '../../core/domain/tx_kind.dart';

/// Ảnh chụp những lựa chọn đang có trên màn ghi giao dịch, kèm mọi quy tắc:
/// công tắc nào được bật, đổi loại thì dọn trường nào, chọn còn thiếu gì, và
/// khi lưu thì gửi id nào xuống DB.
///
/// Không giữ trạng thái: màn hình vẫn sở hữu các trường và dựng một bản chụp
/// mỗi lần cần hỏi. Nhờ vậy quy tắc test được mà không cần dựng widget. Mọi
/// khác biệt giữa các loại giao dịch đều hỏi cờ của [TxKind], không so sánh
/// loại ở đây.
class TxForm {
  const TxForm({
    required this.kind,
    this.walletFromId,
    this.walletToId,
    this.categoryId,
    this.personId,
    this.fundId,
    this.paidByOther = false,
    this.splitEnabled = false,
    this.billEnabled = false,
    this.isEditing = false,
  });

  final TxKind kind;
  final int? walletFromId;
  final int? walletToId;
  final int? categoryId;
  final int? personId;
  final int? fundId;

  /// Công tắc "người khác trả dùm" đang bật (có thể chưa được phép, xem
  /// [isPaidByOther]).
  final bool paidByOther;
  final bool splitEnabled;
  final bool billEnabled;
  final bool isEditing;

  /// Chỉ đổi các công tắc, giữ nguyên loại và các id.
  TxForm copyWithFlags({
    bool? paidByOther,
    bool? splitEnabled,
    bool? billEnabled,
    bool? isEditing,
  }) => TxForm(
    kind: kind,
    walletFromId: walletFromId,
    walletToId: walletToId,
    categoryId: categoryId,
    personId: personId,
    fundId: fundId,
    paidByOther: paidByOther ?? this.paidByOther,
    splitEnabled: splitEnabled ?? this.splitEnabled,
    billEnabled: billEnabled ?? this.billEnabled,
    isEditing: isEditing ?? this.isEditing,
  );

  /// Có được chia tiền ở trạng thái hiện tại không. Trả dùm và hoá đơn chi
  /// tiết không đi cùng nhau: trả dùm tách hoá đơn thành nhiều giao dịch.
  /// Người khác trả thì mình chỉ ghi phần của mình, không có gì để chia. Sửa
  /// một giao dịch đã có thì không đụng tới cả nhóm.
  bool get canSplit =>
      !isEditing && kind.canSplit && !billEnabled && !paidByOther;

  /// Đang ghi kiểu chia tiền.
  bool get usesSplit => canSplit && splitEnabled;

  bool get canPayByOther => kind.canBePaidByOther && !splitEnabled;

  /// Người khác trả dùm: không chọn ví, chọn người mình nợ.
  bool get isPaidByOther => canPayByOther && paidByOther;

  bool get canBill => kind.canHaveBill && !splitEnabled;

  /// Đang dùng hoá đơn chi tiết: số tiền là tổng hoá đơn.
  bool get usesBill => canBill && billEnabled;

  /// Có lưu được các trường đang nhập thành mẫu chi tiêu không.
  bool get canSaveAsTemplate =>
      !isEditing &&
      kind.canSaveAsTemplate &&
      !splitEnabled &&
      !billEnabled &&
      !paidByOther;

  /// Ô "Lấy từ quỹ": người khác trả thì tiền không qua quỹ nào của mình.
  bool get showsFundPicker => kind.canUseFund && !isPaidByOther;

  /// Thanh chọn loại giao dịch: ẩn khi đang ghi/sửa khoản "Ghi nợ" (người
  /// khác trả dùm, loại luôn là chi tiêu).
  bool get showsKindSelector => !isPaidByOther;

  /// Ô chọn người: các loại nợ hoặc khoản chi do người khác trả dùm.
  bool get showsPersonPicker => kind.needsPerson || isPaidByOther;

  /// Tiêu đề thanh trên cùng của màn hình ghi/sửa giao dịch.
  String get title => isPaidByOther
      ? 'Ghi nợ'
      : (isEditing ? 'Sửa giao dịch' : 'Ghi giao dịch');

  /// Đổi loại giao dịch thì phải dọn những trường không còn ý nghĩa, nếu không
  /// sẽ ghi xuống DB một danh mục hoặc một người chẳng liên quan gì.
  ///
  /// Ví đang chọn được giữ lại khi đổi giữa các loại một chân ví, để đỡ phải
  /// chọn lại. Cùng loại thì trả về chính bản này.
  TxForm afterKindChange(TxKind next) {
    if (next == kind) return this;

    int? from;
    int? to;
    if (next.requiresBothWallets) {
      from = walletFromId ?? walletToId;
      to = null;
    } else {
      final currentWallet = kind.needsWalletFrom
          ? walletFromId
          : (kind.needsWalletTo ? walletToId : null);
      if (next.needsWalletFrom) {
        from = currentWallet;
      } else if (next.needsWalletTo) {
        to = currentWallet;
      }
    }

    return TxForm(
      kind: next,
      walletFromId: from,
      walletToId: to,
      categoryId: next.needsCategory ? categoryId : null,
      personId: next.needsPerson ? personId : null,
      // Chia tiền và lấy từ quỹ chỉ có nghĩa với loại cho phép.
      fundId: next.canUseFund ? fundId : null,
      splitEnabled: next.canSplit ? splitEnabled : false,
      paidByOther: next.canBePaidByOther ? paidByOther : false,
      billEnabled: billEnabled,
      isEditing: isEditing,
    );
  }

  /// Lý do chưa lưu được vì chọn thiếu, hoặc null nếu đủ.
  String? validateSelection() {
    if (kind.needsCategory && categoryId == null) {
      return 'Hãy chọn danh mục';
    }
    if (kind.needsPerson && personId == null) {
      return 'Hãy chọn người';
    }
    if (isPaidByOther) {
      return personId == null ? 'Hãy chọn người đã trả dùm' : null;
    }
    if (kind.requiresBothWallets) {
      if (walletFromId == null) return 'Hãy chọn ví nguồn';
      if (walletToId == null) return 'Hãy chọn ví nhận';
      // Nạp / rút quỹ ngay trong ví giữ quỹ thì hai chân trùng nhau là đúng.
      if (walletFromId == walletToId && fundId == null) {
        return 'Ví nguồn và ví nhận phải khác nhau';
      }
      return null;
    }
    if (kind.needsWalletFrom && walletFromId == null) {
      return 'Hãy chọn ví';
    }
    if (kind.needsWalletTo && walletToId == null) {
      return 'Hãy chọn ví';
    }
    return null;
  }

  // Người khác trả thì tiền không qua ví hay quỹ nào. Khoản chi thường thì
  // không mang người theo — có người là thành nợ.

  int? get walletFromIdToSave => isPaidByOther ? null : walletFromId;

  int? get fundIdToSave => isPaidByOther ? null : fundId;

  int? get personIdToSave =>
      kind.needsPerson || isPaidByOther ? personId : null;
}
