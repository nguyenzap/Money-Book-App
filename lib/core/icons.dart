import 'package:flutter/material.dart';

/// Icon vẽ riêng, nằm trong font `MoneyBookIcons` (dựng bằng
/// `tool/build_icon_font.py`). Phải là `const` để tree-shaking giữ lại glyph.
const kSnackIcon = IconData(0xE001, fontFamily: 'MoneyBookIcons');

/// Icon được lưu xuống DB bằng khoá dạng chuỗi thay vì mã điểm ảnh, để việc
/// bật tree-shaking icon lúc build release không làm mất icon, và để file sao
/// lưu vẫn đọc được bằng mắt.
const kIconMap = <String, IconData>{
  // Ví
  'cash': Icons.payments,
  'bank': Icons.account_balance,
  'ewallet': Icons.account_balance_wallet,
  'card': Icons.credit_card,
  'savings': Icons.savings,
  'phone': Icons.phone_android,

  // Chi tiêu
  'food': Icons.restaurant,
  'coffee': Icons.local_cafe,
  'snack': kSnackIcon,
  'transport': Icons.directions_bike,
  'car': Icons.directions_car,
  'fuel': Icons.local_gas_station,
  'home': Icons.home,
  'bill': Icons.receipt_long,
  'shopping': Icons.shopping_bag,
  'fun': Icons.sports_esports,
  'movie': Icons.movie,
  'health': Icons.local_hospital,
  'study': Icons.school,
  'pet': Icons.pets,
  'gift': Icons.card_giftcard,
  'travel': Icons.flight,
  'clothes': Icons.checkroom,
  'phone_bill': Icons.wifi,

  // Thu nhập
  'salary': Icons.work,
  'bonus': Icons.emoji_events,
  'invest': Icons.trending_up,

  // Quỹ
  'piggy': Icons.savings,
  'house': Icons.house,
  'electric': Icons.bolt,
  'water': Icons.water_drop,
  'credit_debt': Icons.credit_score,
  'target': Icons.flag,

  // Chung
  'other': Icons.more_horiz,
  'star': Icons.star,
  'heart': Icons.favorite,
};

IconData iconFor(String? key, {IconData fallback = Icons.circle}) =>
    kIconMap[key] ?? fallback;

/// Danh sách khoá icon để hiện ra cho người dùng chọn.
const kWalletIconKeys = [
  'cash',
  'bank',
  'ewallet',
  'card',
  'savings',
  'phone',
];

const kCategoryIconKeys = [
  'food',
  'coffee',
  'snack',
  'transport',
  'car',
  'fuel',
  'home',
  'bill',
  'phone_bill',
  'shopping',
  'clothes',
  'fun',
  'movie',
  'health',
  'study',
  'pet',
  'gift',
  'travel',
  'salary',
  'bonus',
  'invest',
  'star',
  'heart',
  'other',
];

/// Icon gợi ý cho quỹ: những khoản người ta hay để dành trước.
const kFundIconKeys = [
  'piggy',
  'house',
  'electric',
  'water',
  'phone_bill',
  'credit_debt',
  'study',
  'travel',
  'gift',
  'health',
  'car',
  'target',
];
