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

  /// 'expense' hoặc 'income' — một danh mục chỉ thuộc một chiều.
  TextColumn get flow => text()();

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

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  /// Xoá mềm, để còn hoàn tác được. Mọi truy vấn đều phải lọc
  /// `deletedAt IS NULL`.
  IntColumn get deletedAt => integer().nullable()();
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
