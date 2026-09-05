import 'package:intl/intl.dart';

/// yyyymmdd theo giờ địa phương. 6/9/2026 -> 20260906.
int dayKeyOf(DateTime local) =>
    local.year * 10000 + local.month * 100 + local.day;

/// yyyymm theo giờ địa phương. Tháng 9/2026 -> 202609.
int monthKeyOf(DateTime local) => local.year * 100 + local.month;

/// Tháng hiện tại.
int currentMonthKey() => monthKeyOf(DateTime.now());

/// Tháng liền trước. 202601 -> 202512.
int previousMonthKey(int monthKey) {
  final year = monthKey ~/ 100;
  final month = monthKey % 100;
  return month == 1 ? (year - 1) * 100 + 12 : year * 100 + (month - 1);
}

/// Tháng liền sau. 202612 -> 202701.
int nextMonthKey(int monthKey) {
  final year = monthKey ~/ 100;
  final month = monthKey % 100;
  return month == 12 ? (year + 1) * 100 + 1 : year * 100 + (month + 1);
}

/// "Tháng 9/2026"
String monthKeyLabel(int monthKey) =>
    'Tháng ${monthKey % 100}/${monthKey ~/ 100}';

DateTime dayKeyToDate(int dayKey) => DateTime(
      dayKey ~/ 10000,
      (dayKey ~/ 100) % 100,
      dayKey % 100,
    );

/// "06/09/2026"
String formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

/// "06/09/2026 21:30"
String formatDateTime(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);

/// "21:30"
String formatTime(DateTime d) => DateFormat('HH:mm').format(d);

/// Tiêu đề nhóm ngày trong danh sách giao dịch: "Hôm nay", "Hôm qua",
/// hoặc "Thứ Bảy, 06/09".
String dayHeaderLabel(int dayKey) {
  final date = dayKeyToDate(dayKey);
  final today = DateTime.now();
  final todayKey = dayKeyOf(today);
  if (dayKey == todayKey) return 'Hôm nay';
  if (dayKey == dayKeyOf(today.subtract(const Duration(days: 1)))) {
    return 'Hôm qua';
  }
  final weekday = _weekdayNames[date.weekday]!;
  final sameYear = date.year == today.year;
  final tail = sameYear
      ? DateFormat('dd/MM').format(date)
      : DateFormat('dd/MM/yyyy').format(date);
  return '$weekday, $tail';
}

const _weekdayNames = <int, String>{
  DateTime.monday: 'Thứ Hai',
  DateTime.tuesday: 'Thứ Ba',
  DateTime.wednesday: 'Thứ Tư',
  DateTime.thursday: 'Thứ Năm',
  DateTime.friday: 'Thứ Sáu',
  DateTime.saturday: 'Thứ Bảy',
  DateTime.sunday: 'Chủ Nhật',
};

/// Kẹp ngày trong tháng về ngày cuối cùng nếu tháng đó không có.
/// Ví dụ ngày 31 ở tháng 2 sẽ thành 28 (hoặc 29 năm nhuận).
DateTime clampDayOfMonth(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}
