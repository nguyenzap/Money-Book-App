import 'package:flutter/material.dart';

/// Xanh cho tiền vào, đỏ cho tiền ra. Chọn tông đủ đậm để đọc được cả trên nền
/// sáng lẫn nền tối.
const kIncomeColor = Color(0xFF2E7D32);
const kIncomeColorDark = Color(0xFF66BB6A);
const kExpenseColor = Color(0xFFC62828);
const kExpenseColorDark = Color(0xFFEF5350);
const kNeutralColor = Color(0xFF546E7A);

const kSeedColor = Color(0xFF00695C);

/// Bảng màu cho người dùng chọn khi tạo ví / danh mục / người.
const kPickerColors = <int>[
  0xFF00695C,
  0xFF1565C0,
  0xFF6A1B9A,
  0xFFC62828,
  0xFFEF6C00,
  0xFF2E7D32,
  0xFF4E342E,
  0xFF37474F,
  0xFFAD1457,
  0xFF283593,
];

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: brightness,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    dividerTheme: const DividerThemeData(space: 1, thickness: 1),
  );
}

/// Màu cho số tiền theo dấu, tự đổi theo nền sáng/tối.
Color amountColor(BuildContext context, int signedAmount) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (signedAmount > 0) return dark ? kIncomeColorDark : kIncomeColor;
  if (signedAmount < 0) return dark ? kExpenseColorDark : kExpenseColor;
  return kNeutralColor;
}

Color incomeColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? kIncomeColorDark
        : kIncomeColor;

Color expenseColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? kExpenseColorDark
        : kExpenseColor;
