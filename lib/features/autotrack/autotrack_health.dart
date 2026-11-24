import '../../core/db/autotrack_repository.dart';
import '../../core/db/repository.dart';
import '../../core/domain/autotrack/parsed_txn.dart';
import '../../core/domain/autotrack/parsers/notification_parser.dart';
import '../../core/domain/autotrack/parsers/registry.dart';
import 'autotrack_platform.dart';

/// Ví mà số dư app tính khác số dư ngân hàng báo trong thông báo gần nhất.
class BalanceMismatch {
  const BalanceMismatch({
    required this.walletId,
    required this.walletName,
    required this.bankBalance,
    required this.appBalance,
    required this.eventId,
    required this.at,
  });

  final int walletId;
  final String walletName;

  /// Ngân hàng báo, ngay sau giao dịch lúc [at].
  final int bankBalance;

  /// App tính, cũng tới hết lúc [at].
  final int appBalance;
  final int eventId;
  final DateTime at;

  /// Dương: ngân hàng có nhiều hơn app nghĩ.
  int get diff => bankBalance - appBalance;
}

/// Ngân hàng có vẻ đã đổi câu chữ: tin có số tiền +/- mà không đọc được.
class SuspectedFormatChange {
  const SuspectedFormatChange(this.bankName, this.count);
  final String bankName;
  final int count;
}

class AutoTrackHealth {
  const AutoTrackHealth({
    this.enabled = false,
    this.permissionGranted,
    this.mismatches = const [],
    this.formatChanges = const [],
    this.silentSince,
  });

  static const off = AutoTrackHealth();

  final bool enabled;

  /// Null nếu không hỏi được (không có phần Android, ví dụ khi chạy test).
  final bool? permissionGranted;
  final List<BalanceMismatch> mismatches;
  final List<SuspectedFormatChange> formatChanges;

  /// Đã lâu không nhận thông báo nào từ ngân hàng: lúc nhận tin cuối.
  final DateTime? silentSince;

  bool get isHealthy =>
      permissionGranted != false &&
      mismatches.isEmpty &&
      formatChanges.isEmpty &&
      silentSince == null;
}

/// Bao lâu không có tin nào từ ngân hàng thì nhắc. Không ngắn hơn: có những
/// ngày đơn giản là không tiêu gì.
const kSilentAfter = Duration(days: 3);

/// Số tiền có dấu kiểu ngân hàng (-80,000 VND). OTP hay khuyến mãi không có,
/// nên tin không đọc được mà có cái này gần như chắc là một giao dịch bị lọt.
final _signedAmount = RegExp(
  r'[+-]\s?\d{1,3}(?:[.,]\d{3})+\s*(?:vnd|vnđ|đ|₫)',
  caseSensitive: false,
);

String _dismissBalanceKey(int walletId) =>
    'autotrack.dismiss.balance.$walletId';
const _dismissSilentKey = 'autotrack.dismiss.silent';

/// Kiểm tra mọi thứ có thể hỏng mà không ai thấy: mất quyền, lệch số dư,
/// ngân hàng đổi mẫu, im lặng quá lâu.
Future<AutoTrackHealth> checkAutoTrackHealth({
  required Repository repo,
  required AutoTrackRepository auto,
  AutoTrackPlatform? platform,
  required DateTime now,
  List<NotificationParser> parsers = kParsers,
}) async {
  if (!await auto.isEnabled()) return AutoTrackHealth.off;

  bool? permission;
  try {
    permission = await platform?.isListenerEnabled();
  } catch (_) {
    permission = null;
  }

  NotificationParser? parserOf(String? id) =>
      parsers.where((p) => p.id == id).firstOrNull;

  // 1. Số dư.
  final mismatches = <BalanceMismatch>[];
  for (final e in await auto.latestParsedPerWallet()) {
    final parsed = parserOf(e.parserId)?.parse(e.title, e.body);
    if (parsed is! ParseMatched) continue;
    final bank = parsed.txn.balanceAfter;
    if (bank == null) continue;
    final dismissed = await auto.setting(_dismissBalanceKey(e.walletId));
    if (dismissed == '${e.eventId}') continue;
    final app = await repo.balanceOf(e.walletId, asOf: e.occurredAt);
    if (app == bank) continue;
    mismatches.add(
      BalanceMismatch(
        walletId: e.walletId,
        walletName: e.walletName,
        bankBalance: bank,
        appBalance: app,
        eventId: e.eventId,
        at: e.occurredAt,
      ),
    );
  }

  // 2. Ngân hàng đổi mẫu: tin có số tiền +/- mà đọc không ra, trong 7 ngày.
  final counts = <String, int>{};
  final apps = {
    for (final a in await auto.watchTrackedApps().first) a.packageName: a,
  };
  for (final e in await auto.recentUnparsed(
    now.subtract(const Duration(days: 7)),
  )) {
    if (!_signedAmount.hasMatch('${e.title}\n${e.body}')) continue;
    final name =
        parserOf(apps[e.packageName]?.parserId)?.displayName ?? e.packageName;
    counts[name] = (counts[name] ?? 0) + 1;
  }

  // 3. Im lặng quá lâu (chỉ khi còn quyền: mất quyền đã có cảnh báo riêng).
  DateTime? silentSince;
  if (permission != false) {
    final last = await auto.lastBankEventAt();
    if (last != null && now.difference(last) > kSilentAfter) {
      final dismissed = await auto.setting(_dismissSilentKey);
      if (dismissed != '${last.millisecondsSinceEpoch}') silentSince = last;
    }
  }

  return AutoTrackHealth(
    enabled: true,
    permissionGranted: permission,
    mismatches: mismatches,
    formatChanges: [
      for (final e in counts.entries) SuspectedFormatChange(e.key, e.value),
    ],
    silentSince: silentSince,
  );
}

/// Ẩn cảnh báo lệch số dư của ví này cho tới khi có thông báo mới.
Future<void> dismissBalanceMismatch(
  AutoTrackRepository auto,
  BalanceMismatch m,
) => auto.setSetting(_dismissBalanceKey(m.walletId), '${m.eventId}');

/// Ẩn cảnh báo im lặng cho tới khi có thông báo mới rồi lại im.
Future<void> dismissSilence(AutoTrackRepository auto, DateTime lastEventAt) =>
    auto.setSetting(_dismissSilentKey, '${lastEventAt.millisecondsSinceEpoch}');
