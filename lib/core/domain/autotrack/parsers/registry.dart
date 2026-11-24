import 'bidv_parser.dart';
import 'eximbank_parser.dart';
import 'notification_parser.dart';

/// Mọi ngân hàng app đọc được. Thêm ngân hàng mới: viết parser, thêm vào đây,
/// thêm mẫu vào `test/fixtures/autotrack/<id>/`.
const List<NotificationParser> kParsers = [BidvParser(), EximbankParser()];

NotificationParser? parserById(String id) {
  for (final p in kParsers) {
    if (p.id == id) return p;
  }
  return null;
}
