

/// Phiên bản định dạng file sao lưu.
///
/// Tăng lên mỗi khi cấu trúc file đổi, để bản app cũ biết mà từ chối file mới
/// thay vì đọc bừa rồi hỏng dữ liệu.
const kBackupFormatVersion = 7;

class BackupStats {
  const BackupStats({
    required this.wallets,
    required this.categories,
    required this.people,
    required this.transactions,
    required this.budgets,
    required this.funds,
    this.templates = 0,
  });

  final int wallets;
  final int categories;
  final int people;
  final int transactions;
  final int budgets;
  final int funds;
  final int templates;

  int get total =>
      wallets +
      categories +
      people +
      transactions +
      budgets +
      funds +
      templates;
}

/// Cách xử lý khi nhập một file sao lưu.
enum ImportMode {
  /// Xoá sạch dữ liệu hiện có rồi nạp file vào.
  replace,

  /// Giữ dữ liệu cũ, thêm dữ liệu trong file vào.
  merge,
}

class ImportResult {
  const ImportResult({required this.stats, required this.mode});
  final BackupStats stats;
  final ImportMode mode;
}

/// Lỗi có thông điệp đọc được, hiện thẳng cho người dùng.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}
