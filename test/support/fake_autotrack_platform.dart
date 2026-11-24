import 'package:moneybook/features/autotrack/autotrack_platform.dart';

const bidvPkg = 'com.vnpay.bidv';

/// Hộp thư phía Android, giả lập.
class FakePlatform implements AutoTrackPlatform {
  final inbox = <InboxItem>[];
  List<String> watched = [];
  int _nextId = 1;

  void post(String text, DateTime at, {String pkg = bidvPkg, String title = ''}) {
    inbox.add(
      InboxItem(
        id: _nextId++,
        packageName: pkg,
        title: title,
        text: text,
        postedAt: at,
      ),
    );
  }

  @override
  Future<List<InboxItem>> readInbox() async => List.of(inbox);

  @override
  Future<void> ackInbox(int maxId) async =>
      inbox.removeWhere((i) => i.id <= maxId);

  @override
  Future<void> setWatchedPackages(List<String> packages) async =>
      watched = packages;

  /// Quyền đọc thông báo đã bật chưa.
  bool listenerEnabled = true;

  @override
  Future<bool> isListenerEnabled() async => listenerEnabled;
  @override
  Future<void> openListenerSettings() async {}
  @override
  Future<void> requestRebind() async {}
  @override
  Future<List<LaunchableApp>> listLaunchableApps() async => const [];
  /// Gói giả coi như đã cài trên máy.
  Set<String> installed = {bidvPkg};

  @override
  Future<bool> isPackageInstalled(String packageName) async =>
      installed.contains(packageName);
  @override
  Stream<void> get newItems => const Stream.empty();
}
