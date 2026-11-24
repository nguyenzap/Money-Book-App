import 'dart:convert';

import '../../core/db/autotrack_repository.dart';
import '../../core/db/database.dart';
import '../../core/db/repository.dart';
import '../../core/domain/autotrack/categorizer.dart';
import '../../core/domain/autotrack/parsed_txn.dart';
import '../../core/domain/autotrack/parsers/notification_parser.dart';
import '../../core/domain/autotrack/parsers/registry.dart';
import '../../core/domain/autotrack/receiver_normalizer.dart';
import '../../core/domain/tx_kind.dart';
import 'autotrack_platform.dart';

/// Kết quả một lần đồng bộ, để báo cho người dùng.
class SyncReport {
  int received = 0;
  int created = 0;
  int unmatched = 0;
  int failed = 0;
  int unmapped = 0;
  int duplicates = 0;

  /// Trong số [created]: đã có danh mục chắc chắn (theo quy tắc đã học).
  int categorized = 0;

  @override
  String toString() =>
      'SyncReport(received=$received, created=$created, '
      'unmatched=$unmatched, failed=$failed, unmapped=$unmapped, '
      'duplicates=$duplicates)';
}

/// Lấy thông báo từ hộp thư phía Android, đọc chúng và ghi giao dịch qua
/// [Repository.addTransaction] — đúng con đường của giao dịch nhập tay.
///
/// Chạy khi mở app, khi app quay lại từ nền và khi có tin mới lúc app đang
/// mở. Mỗi lúc chỉ một lần chạy: gọi chồng thì dùng chung lần đang chạy.
class AutoTrackService {
  AutoTrackService({
    required this.repo,
    required this.auto,
    required this.platform,
    this.parsers = kParsers,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final Repository repo;
  final AutoTrackRepository auto;
  final AutoTrackPlatform platform;
  final List<NotificationParser> parsers;
  final DateTime Function() _clock;

  /// Lệch quá chừng này so với lúc thông báo đến thì nghi là đọc nhầm ngày,
  /// dùng lúc đến thay cho thời gian in trong tin.
  static const maxClockSkew = Duration(days: 3);

  Future<SyncReport>? _running;

  Future<SyncReport> sync() {
    return _running ??= _sync().whenComplete(() => _running = null);
  }

  Future<SyncReport> _sync() async {
    final now = _clock();
    await pushWatchedPackages();
    await auto.seedKeywordsOnce();

    final items = await platform.readInbox();
    var received = 0;
    for (final item in items) {
      final id = await auto.insertEvent(
        packageName: item.packageName,
        title: item.title,
        body: item.text,
        postedAt: item.postedAt,
        dedupeHash: eventDedupeHash(
          item.packageName,
          item.title,
          item.text,
          item.postedAt,
        ),
      );
      if (id != null) received++;
    }
    // Chỉ xoá bên Android SAU KHI đã lưu xong bên này.
    if (items.isNotEmpty) {
      await platform.ackInbox(items.map((i) => i.id).reduce(_max));
    }

    final report = await processPending()..received = received;
    await auto.purgeOld(now: now);
    return report;
  }

  /// Gửi danh sách gói cần nghe sang Android. Gọi lại mỗi khi đổi cài đặt.
  Future<void> pushWatchedPackages() async {
    await platform.setWatchedPackages(await auto.watchedPackages(_clock()));
  }

  /// Xử lý mọi thông báo đang chờ, kể cả những tin trước đây chưa đọc được
  /// mà nay parser đã có bản mới hơn.
  Future<SyncReport> processPending() async {
    final report = SyncReport();
    CategorizerData? categorizer; // đọc một lần, chỉ khi có tin cần ghi
    for (final event in await auto.eventsToProcess()) {
      final app = await auto.trackedApp(event.packageName);
      final parser = _parserFor(app);
      final status = EventStatus.parse(event.status);

      if (parser == null) {
        // Không có parser: app đang ghi mẫu, hoặc đã bị bỏ theo dõi.
        if (status == EventStatus.pending) {
          await auto.setEventResult(event.id, status: EventStatus.captured);
        }
        continue;
      }
      if (!app!.enabled) continue;

      // Đã đọc bằng chính phiên bản này mà không ra: đọc lại cũng thế.
      final sameParser =
          event.parserId == parser.id && event.parserVersion == parser.version;
      if ((status == EventStatus.unmatched || status == EventStatus.failed) &&
          sameParser) {
        continue;
      }

      categorizer ??= await auto.loadCategorizerData();
      switch (await _process(event, parser, categorizer, report)) {
        case EventStatus.parsed:
          report.created++;
        case EventStatus.unmatched:
          report.unmatched++;
        case EventStatus.failed:
          report.failed++;
        case EventStatus.unmapped:
          report.unmapped++;
        case EventStatus.duplicate:
          report.duplicates++;
        case EventStatus.pending || EventStatus.captured:
          break;
      }
    }
    return report;
  }

  NotificationParser? _parserFor(TrackedApp? app) {
    final id = app?.parserId;
    if (id == null) return null;
    for (final p in parsers) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<EventStatus> _process(
    NotificationEvent event,
    NotificationParser parser,
    CategorizerData categorizer,
    SyncReport report,
  ) async {
    Future<EventStatus> mark(
      EventStatus status, {
      String? reason,
      String? txnKey,
    }) async {
      await auto.setEventResult(
        event.id,
        status: status,
        reason: reason,
        parserId: parser.id,
        parserVersion: parser.version,
        txnKey: txnKey,
      );
      return status;
    }

    final result = parser.parse(event.title, event.body);
    final ParsedTxn txn;
    switch (result) {
      case ParseIgnored(:final reason):
        return mark(EventStatus.unmatched, reason: reason);
      case ParseFailed(:final reason):
        return mark(EventStatus.failed, reason: reason);
      case ParseMatched(txn: final t):
        txn = t;
    }

    final postedAt = DateTime.fromMillisecondsSinceEpoch(event.postedAt);
    final occurredAt = pickOccurredAt(txn.occurredAt, postedAt);
    final key = txnKeyOf(parser.id, txn, occurredAt);

    if (key != null && await auto.txnKeyExists(key)) {
      return mark(EventStatus.duplicate, reason: 'đã ghi từ tin khác');
    }

    final walletId = await auto.resolveWallet(
      event.packageName,
      txn.accountSuffix,
    );
    if (walletId == null) {
      return mark(
        EventStatus.unmapped,
        reason: txn.accountSuffix == null
            ? 'chưa chọn ví cho ${parser.displayName}'
            : 'chưa chọn ví cho tài khoản …${txn.accountSuffix}',
      );
    }

    final isExpense = txn.direction == TxDirection.expense;
    final flow = isExpense ? 'expense' : 'income';
    final receiverKey = normalizeReceiver(txn.receiver);
    final guess = categorizer.guess(receiverKey, flow);

    await repo.db.transaction(() async {
      await repo.addTransaction(
        kind: isExpense ? TxKind.expense : TxKind.income,
        amount: txn.amount,
        occurredAt: occurredAt,
        walletFromId: isExpense ? walletId : null,
        walletToId: isExpense ? null : walletId,
        categoryId: guess.categoryId,
        note: txn.receiver,
        autoEventId: event.id,
        // Theo quy tắc đã học thì tin được; chưa có hoặc mới đoán thì chờ
        // mình xem.
        needsReview: guess.needsReview,
      );
      await auto.setEventResult(
        event.id,
        status: EventStatus.parsed,
        reason: guess.reason,
        parserId: parser.id,
        parserVersion: parser.version,
        txnKey: key,
        receiverKey: receiverKey,
        categorySource: guess.source?.name,
      );
      if (guess.source == CategorySource.name) {
        await auto.bumpRuleHit(receiverKey, flow);
      }
    });
    if (!guess.needsReview) report.categorized++;
    return EventStatus.parsed;
  }
}

/// Thời gian in trong tin nếu hợp lý, không thì lúc tin đến.
DateTime pickOccurredAt(DateTime? printed, DateTime postedAt) {
  if (printed == null) return postedAt;
  final skew = printed.difference(postedAt).abs();
  return skew > AutoTrackService.maxClockSkew ? postedAt : printed;
}

/// Khoá nhận diện một GIAO DỊCH (không phải một tin): cùng khoá là cùng giao
/// dịch dù chữ trong tin khác nhau. Null nếu không đủ thông tin để chắc.
String? txnKeyOf(String parserId, ParsedTxn txn, DateTime occurredAt) {
  final ref = txn.reference;
  if (ref != null) return '$parserId|ref:$ref';
  final balance = txn.balanceAfter;
  // Không có mã thì cần cả số dư sau giao dịch: hai khoản cùng số tiền cùng
  // phút vẫn khác số dư.
  if (txn.occurredAt == null || balance == null) return null;
  final signed = txn.direction == TxDirection.expense ? -txn.amount : txn.amount;
  final minute = occurredAt.millisecondsSinceEpoch ~/ 60000;
  return '$parserId|${txn.accountSuffix ?? ''}|$minute|$signed|$balance';
}

/// Chống lưu trùng tin thô: app ngân hàng hay đăng lại cùng một thông báo.
/// FNV-1a 64 bit trên gói + tiêu đề + nội dung + phút đến.
String eventDedupeHash(
  String packageName,
  String title,
  String text,
  DateTime postedAt,
) {
  final minute = postedAt.millisecondsSinceEpoch ~/ 60000;
  final bytes = utf8.encode('$packageName\u0000$title\u0000$text\u0000$minute');
  // 0xcbf29ce484222325 viết dạng có dấu: số đó vượt giới hạn literal int.
  var h = -3750763034362895579;
  for (final b in bytes) {
    h ^= b;
    h *= 0x100000001b3; // tràn số 64 bit là có chủ ý
  }
  return h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

int _max(int a, int b) => a > b ? a : b;
