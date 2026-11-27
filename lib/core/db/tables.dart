import 'package:drift/drift.dart';

import '../domain/tx_kind.dart';

/// Nguồn tiền: tiền mặt, MoMo, MB Bank, Techcombank...
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// cash | bank | ewallet | credit | savings | other
  TextColumn get type => text().withDefault(const Constant('other'))();

  /// Số dư ban đầu, tính bằng ĐỒNG. Có thể âm (thẻ tín dụng).
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();

  TextColumn get iconKey => text().nullable()();
  IntColumn get colorValue => integer().nullable()();
  TextColumn get note => text().nullable()();

  /// Ví đã lưu trữ: ẩn khỏi các ô chọn nhưng vẫn giữ nguyên lịch sử.
  /// Dùng thay cho xoá, vì xoá ví có giao dịch sẽ làm thủng sổ sách.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Loại giao dịch do người dùng tự đặt. App chỉ gieo sẵn vài cái cho đỡ trống,
/// và tất cả đều xoá được.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Một danh mục chỉ thuộc một chiều. Lưu bằng tên enum: 'expense' / 'income'.
  TextColumn get flow => textEnum<CategoryFlow>()();

  TextColumn get iconKey => text().nullable()();
  IntColumn get colorValue => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Danh bạ chủ nợ / con nợ. Thêm một lần, những lần sau chỉ việc chọn.
@DataClassName('Person')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get avatarColor => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Mẫu giao dịch lặp lại (tiền trọ, internet...) — một chạm là ghi xong.
class RecurringTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 80)();
  TextColumn get kind => textEnum<TxKind>()();
  IntColumn get amount => integer()();

  IntColumn get walletFromId => integer().nullable()();
  IntColumn get walletToId => integer().nullable()();
  IntColumn get categoryId => integer().nullable()();
  IntColumn get personId => integer().nullable()();
  TextColumn get note => text().nullable()();

  /// none | daily | weekly | monthly | yearly
  TextColumn get freq => text().withDefault(const Constant('monthly'))();
  IntColumn get intervalN => integer().withDefault(const Constant(1))();

  /// 1..31 cho chu kỳ tháng. Ngày 31 ở tháng thiếu sẽ tự lùi về ngày cuối.
  IntColumn get dayOfMonth => integer().nullable()();

  /// 1..7 theo DateTime.weekday, cho chu kỳ tuần.
  IntColumn get weekday => integer().nullable()();

  IntColumn get nextDueAt => integer().nullable()();
  IntColumn get lastRunAt => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Mẫu chi tiêu: khoản chi hay lặp lại (cà phê, gửi xe, ăn trưa...) để ghi
/// bằng một chạm.
///
/// Khác [RecurringTemplates] ở chỗ không có lịch: mẫu chỉ chạy khi người dùng
/// bấm, và thời điểm luôn là lúc bấm. Mọi trường đều có thể để trống — thiếu
/// trường nào thì bấm vào mẫu sẽ mở màn ghi đã điền sẵn phần còn lại, để khoản
/// như đổ xăng (ví, danh mục cố định nhưng số tiền mỗi lần một khác) vẫn đỡ
/// được mấy bước chọn.
class ExpenseTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Cũng là nhãn của mẫu. Để trống thì mẫu mang tên danh mục.
  TextColumn get note => text().nullable()();

  /// Số đồng, luôn dương. Null nghĩa là mỗi lần một khác, hỏi lúc ghi.
  IntColumn get amount => integer().nullable()();

  IntColumn get walletId => integer().nullable().references(Wallets, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Bảng trung tâm của toàn bộ app.
///
/// Mọi loại giao dịch đều nằm ở đây, phân biệt bằng [kind]. Mỗi dòng có tối đa
/// hai chân ví — [walletFromId] (tiền ra) và [walletToId] (tiền vào) — nên số
/// dư của mọi ví luôn tính được bằng đúng một công thức, không cần rẽ nhánh
/// theo loại giao dịch. Xem [TxKind] để biết chi tiết quy ước dấu.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<TxKind>()();

  /// LUÔN là số dương. Dấu suy ra từ [kind], không bao giờ lưu vào đây.
  IntColumn get amount => integer()();

  /// Thời điểm giao dịch, epoch millis.
  IntColumn get occurredAt => integer()();

  /// yyyymmdd theo giờ ĐỊA PHƯƠNG, ví dụ 20260906.
  ///
  /// Tính sẵn ở Dart thay vì dùng strftime của SQLite, vì SQLite quy về UTC —
  /// một giao dịch lúc 23h30 ngày cuối tháng sẽ bị xếp nhầm sang tháng sau.
  IntColumn get dayKey => integer()();

  /// yyyymm theo giờ địa phương, ví dụ 202609.
  IntColumn get monthKey => integer()();

  // Hai cột cùng trỏ về Wallets nên phải đặt tên tham chiếu khác nhau.
  @ReferenceName('outgoingTransactions')
  IntColumn get walletFromId =>
      integer().nullable().references(Wallets, #id)();

  @ReferenceName('incomingTransactions')
  IntColumn get walletToId => integer().nullable().references(Wallets, #id)();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  IntColumn get personId => integer().nullable().references(People, #id)();

  /// Thay đổi công nợ. Xem [TxKindX.debtDelta].
  IntColumn get debtDelta => integer().withDefault(const Constant(0))();

  TextColumn get note => text().nullable()();

  /// Gom nhiều giao dịch sinh ra cùng lúc thành một nhóm (trả dùm tạo ra một
  /// khoản chi cho phần mình ăn và một khoản cho mượn cho phần bạn bè).
  TextColumn get groupId => text().nullable()();

  IntColumn get recurringId =>
      integer().nullable().references(RecurringTemplates, #id)();

  /// Quỹ mà giao dịch này nạp vào hoặc lấy ra.
  ///
  /// Không phải một loại giao dịch riêng: nạp quỹ là một [TxKind.transfer] có
  /// gắn quỹ, chi từ quỹ là một [TxKind.expense] có gắn quỹ. Nhờ vậy công thức
  /// tính số dư ví không phải rẽ nhánh thêm lần nào nữa.
  ///
  /// Chiều tiền của quỹ suy ra từ chân ví giống hệt cách làm với số dư: giao
  /// dịch đưa tiền vào ví giữ quỹ thì quỹ tăng, lấy tiền ra thì quỹ giảm.
  IntColumn get fundId => integer().nullable().references(Funds, #id)();

  /// Quỹ tăng (+) hay giảm (-) bao nhiêu vì giao dịch này. Xem [fundDeltaOf].
  ///
  /// Lưu sẵn chứ không suy ra lúc truy vấn, vì nạp / rút quỹ ngay trong chính
  /// ví giữ quỹ có hai chân trùng nhau — từ chân ví không biết được chiều.
  IntColumn get fundDelta => integer().withDefault(const Constant(0))();

  /// Tất toán không có dòng tiền (xoá nợ, cho luôn). Khi đó không ví nào bị
  /// đụng tới, nhưng công nợ vẫn về 0.
  BoolColumn get isWriteoff => boolean().withDefault(const Constant(false))();

  /// Giao dịch nợ mà dòng này tất toán (một phần hoặc toàn bộ). Null với
  /// giao dịch thường hoặc tất toán gộp cả người.
  @ReferenceName('settlementTransactions')
  IntColumn get settlesTxId => integer().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Thông báo ngân hàng đã sinh ra giao dịch này. Null = nhập tay.
  IntColumn get autoEventId => integer().nullable().references(
    NotificationEvents,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Giao dịch tự ghi còn chờ mình xem lại (chưa phân loại, phân loại đoán).
  /// Không ảnh hưởng số dư hay thống kê.
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  /// Xoá mềm, để còn hoàn tác được. Mọi truy vấn đều phải lọc
  /// `deletedAt IS NULL`.
  IntColumn get deletedAt => integer().nullable()();
}

/// Hoá đơn chi tiết của một khoản chi: mỗi dòng là một món đã mua.
///
/// Có hoá đơn thì [Transactions.amount] chính là tổng hoá đơn
/// (`billTotal`), tính lúc ghi. Món không đổi thống kê hay ngân sách: chúng
/// vẫn chỉ thấy một khoản chi của danh mục đó.
///
/// Xoá mềm giao dịch thì các dòng vẫn nằm đó để hoàn tác; xoá hẳn thì khoá
/// ngoại `ON DELETE CASCADE` dọn theo.
class BillItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId =>
      integer().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  /// Đơn giá, LUÔN dương. Dòng giảm giá đánh dấu bằng [isDiscount], giống
  /// cách [Transactions.amount] để dấu cho kind.
  IntColumn get unitPrice => integer()();
  BoolColumn get isDiscount => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// Hạn mức chi tiêu theo danh mục.
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();

  /// yyyymm, hoặc null nghĩa là áp dụng cho mọi tháng.
  IntColumn get monthKey => integer().nullable()();

  IntColumn get limitAmount => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

/// Cấu hình linh tinh dạng khoá - giá trị.
class SettingsKv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Quỹ: tiền đã dành sẵn cho một khoản chi đã biết trước.
///
/// Tiền quỹ KHÔNG nằm ở đâu khác ngoài các ví thật — thường là một ngân hàng ít
/// dùng, chuyển sang đó cho khỏi tiêu nhầm. Quỹ chỉ là lời hứa "phần này không
/// được đụng", nên số dư ví vẫn luôn khớp với app ngân hàng.
///
/// Vì vậy tiền quỹ bị trừ khỏi "tiền tiêu được" nhưng vẫn nằm trong tổng tài
/// sản đầy đủ: nó là tiền của mình, chỉ là đã có chỗ đến.
@DataClassName('Fund')
class Funds extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// Ví đang giữ tiền của quỹ này. Xoá ví thì quỹ mất chỗ neo nên chặn lại.
  IntColumn get walletId => integer().references(Wallets, #id)();

  /// Số tiền mục tiêu, hoặc null nếu chỉ để dành mà không có đích cụ thể.
  IntColumn get targetAmount => integer().nullable()();

  /// Hạn cần dùng tới, dạng yyyymmdd. Dùng để nhắc và để sắp xếp.
  IntColumn get dueDayKey => integer().nullable()();

  TextColumn get note => text().nullable()();
  TextColumn get iconKey => text().nullable()();
  IntColumn get colorValue => integer().nullable()();

  /// Quỹ đã dùng xong nhưng giữ lại để xem lịch sử.
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

// ---------------------------------------------------------------------------
// Tự động ghi từ thông báo ngân hàng. Xem finance-app-plan.md.
// ---------------------------------------------------------------------------

/// Ứng dụng mà app nghe thông báo.
///
/// Có [parserId]: app ngân hàng được hỗ trợ, thông báo được đọc thành giao
/// dịch. Không có: chế độ "ghi mẫu", chỉ lưu thông báo thô tới [captureUntil]
/// để viết parser cho ngân hàng mới.
class TrackedApps extends Table {
  TextColumn get packageName => text()();
  TextColumn get parserId => text().nullable()();

  /// Tên app lúc chọn, để hiển thị khi app đã bị gỡ.
  TextColumn get label => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Ví nhận mọi giao dịch của app này, trừ khi số tài khoản có ví riêng
  /// trong [AccountWallets].
  IntColumn get defaultWalletId => integer().nullable().references(
    Wallets,
    #id,
    onDelete: KeyAction.setNull,
  )();

  IntColumn get captureUntil => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {packageName};
}

/// Một ngân hàng có nhiều tài khoản: số đuôi tài khoản nào vào ví nào.
class AccountWallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text().references(
    TrackedApps,
    #packageName,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get accountSuffix => text()();
  IntColumn get walletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.cascade)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {packageName, accountSuffix},
  ];
}

/// Thông báo thô nhận từ ứng dụng đang nghe.
///
/// Chứa số tài khoản và số dư nên KHÔNG bao giờ được xuất ra file sao lưu.
/// Tin không đọc thành giao dịch (`unmatched`, `captured`) bị dọn sau một
/// thời gian.
class NotificationEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get body => text()();

  /// Lúc thông báo đến máy, epoch millis.
  IntColumn get postedAt => integer()();

  /// Chống ghi trùng tin thô: gói + nội dung + phút đến. Xem `eventDedupeHash`.
  TextColumn get dedupeHash => text().unique()();

  /// new | parsed | unmatched | failed | unmapped | captured | duplicate
  TextColumn get status => text().withDefault(const Constant('new'))();

  /// Lý do không ghi được, cho màn nhật ký.
  TextColumn get statusReason => text().nullable()();

  TextColumn get parserId => text().nullable()();
  IntColumn get parserVersion => integer().nullable()();

  /// Khoá của GIAO DỊCH đọc được (ngân hàng + mã giao dịch, hoặc thời gian +
  /// số tiền + số dư). Hai tin khác chữ nhưng cùng khoá là một giao dịch.
  TextColumn get txnKey => text().nullable()();

  /// Người nhận đã chuẩn hoá, để gom nhóm và học phân loại.
  TextColumn get receiverKey => text().nullable()();

  /// account | name | similar | keyword | user — vì sao có danh mục này.
  TextColumn get categorySource => text().nullable()();

  IntColumn get createdAt => integer()();
}

/// Người nhận nào thuộc danh mục nào, học từ những lần mình tự phân loại.
class ReceiverRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// account | name
  TextColumn get matchType => text()();
  TextColumn get matchKey => text()();

  /// Chiều tiền, lưu bằng tên enum — cùng một người có thể vừa nhận vừa gửi
  /// tiền.
  TextColumn get flow => textEnum<CategoryFlow>()();

  /// Tên người nhận như lần gần nhất thấy, để hiển thị.
  TextColumn get displayName => text()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get hitCount => integer().withDefault(const Constant(0))();
  IntColumn get lastUsedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {matchType, matchKey, flow},
  ];
}

/// Từ khoá gợi ý danh mục (CAFE → Ăn uống) cho người nhận chưa có quy tắc.
class CategoryKeywords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Đã chuẩn hoá: chữ hoa, không dấu.
  TextColumn get keyword => text()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {keyword, categoryId},
  ];
}
