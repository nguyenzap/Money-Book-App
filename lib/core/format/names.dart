import 'package:characters/characters.dart';

/// Chữ cái đại diện cho một cái tên, dùng làm ảnh đại diện.
///
/// Tên tiếng Việt xếp họ trước, tên gọi sau — "Nguyễn Văn Nam" thì mọi người
/// gọi nhau là Nam chứ không ai gọi là N của Nguyễn. Vì vậy lấy chữ cái đầu
/// của từ CUỐI, khác với cách làm quen thuộc của tên phương Tây.
String initialOf(String name) {
  final words = name.trim().split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return '?';
  return words.last.characters.first.toUpperCase();
}