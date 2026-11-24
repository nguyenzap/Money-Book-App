import 'package:flutter/services.dart';

/// Một thông báo thô trong hộp thư phía Android.
class InboxItem {
  const InboxItem({
    required this.id,
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedAt,
  });

  final int id;
  final String packageName;
  final String title;
  final String text;
  final DateTime postedAt;
}

/// Một app có biểu tượng ngoài màn hình chính.
class LaunchableApp {
  const LaunchableApp({
    required this.packageName,
    required this.label,
    this.icon,
  });

  final String packageName;
  final String label;

  /// PNG 96×96, null nếu không lấy được.
  final Uint8List? icon;
}

/// Phần Android của tính năng tự động ghi. Tách thành interface để kiểm thử
/// dịch vụ mà không cần máy thật.
abstract class AutoTrackPlatform {
  Future<List<InboxItem>> readInbox();

  /// Báo đã lưu xong mọi tin có id <= [maxId], cho phía Android xoá.
  Future<void> ackInbox(int maxId);

  Future<void> setWatchedPackages(List<String> packages);
  Future<bool> isListenerEnabled();
  Future<void> openListenerSettings();
  Future<void> requestRebind();
  Future<List<LaunchableApp>> listLaunchableApps();
  Future<bool> isPackageInstalled(String packageName);

  /// Phát mỗi khi có tin mới lúc app đang mở.
  Stream<void> get newItems;
}

class ChannelAutoTrackPlatform implements AutoTrackPlatform {
  static const _methods = MethodChannel('moneybook/autotrack');
  static const _events = EventChannel('moneybook/autotrack/events');

  @override
  Future<List<InboxItem>> readInbox() async {
    final raw = await _methods.invokeListMethod<Map>('readInbox') ?? const [];
    return [
      for (final m in raw)
        InboxItem(
          id: (m['id'] as num).toInt(),
          packageName: m['packageName'] as String,
          title: m['title'] as String? ?? '',
          text: m['text'] as String? ?? '',
          postedAt: DateTime.fromMillisecondsSinceEpoch(
            (m['postedAt'] as num).toInt(),
          ),
        ),
    ];
  }

  @override
  Future<void> ackInbox(int maxId) =>
      _methods.invokeMethod('ackInbox', {'maxId': maxId});

  @override
  Future<void> setWatchedPackages(List<String> packages) =>
      _methods.invokeMethod('setWatchedPackages', {'packages': packages});

  @override
  Future<bool> isListenerEnabled() async =>
      await _methods.invokeMethod<bool>('isListenerEnabled') ?? false;

  @override
  Future<void> openListenerSettings() =>
      _methods.invokeMethod('openListenerSettings');

  @override
  Future<void> requestRebind() => _methods.invokeMethod('requestRebind');

  @override
  Future<List<LaunchableApp>> listLaunchableApps() async {
    final raw =
        await _methods.invokeListMethod<Map>('listLaunchableApps') ?? const [];
    return [
      for (final m in raw)
        LaunchableApp(
          packageName: m['packageName'] as String,
          label: m['label'] as String? ?? m['packageName'] as String,
          icon: m['icon'] as Uint8List?,
        ),
    ];
  }

  @override
  Future<bool> isPackageInstalled(String packageName) async =>
      await _methods.invokeMethod<bool>('isPackageInstalled', {
        'packageName': packageName,
      }) ??
      false;

  @override
  Stream<void> get newItems => _events.receiveBroadcastStream();
}
