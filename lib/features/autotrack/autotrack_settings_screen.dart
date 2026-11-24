import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/db/repository.dart';
import '../../core/domain/autotrack/parsers/notification_parser.dart';
import '../../core/domain/autotrack/parsers/registry.dart';
import '../../core/format/dates.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'app_picker_screen.dart';
import 'autotrack_platform.dart';
import 'autotrack_providers.dart';
import 'categorize_rules_screen.dart';
import 'event_log_screen.dart';
import 'review_screen.dart';

/// Cài đặt tự động ghi từ thông báo ngân hàng.
class AutoTrackSettingsScreen extends ConsumerStatefulWidget {
  const AutoTrackSettingsScreen({super.key});

  @override
  ConsumerState<AutoTrackSettingsScreen> createState() =>
      _AutoTrackSettingsScreenState();
}

class _AutoTrackSettingsScreenState
    extends ConsumerState<AutoTrackSettingsScreen> {
  // Quay lại từ màn cấp quyền của hệ thống thì xem lại quyền.
  late final _lifecycle = AppLifecycleListener(
    onResume: () {
      ref.invalidate(listenerEnabledProvider);
      _apply();
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Gửi cài đặt mới sang Android và ghi những tin đang chờ (ví dụ vừa chọn
  /// ví cho ngân hàng).
  Future<void> _apply() async {
    try {
      final platform = ref.read(autoTrackPlatformProvider);
      await ref.read(autoTrackServiceProvider).sync();
      await platform.requestRebind();
    } catch (e) {
      if (mounted) showSnack(context, 'Lỗi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(autoTrackEnabledProvider).value ?? false;
    final apps = ref.watch(trackedAppsProvider).value ?? const <TrackedApp>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Tự động ghi')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SwitchListTile(
            title: const Text('Ghi từ thông báo ngân hàng'),
            subtitle: const Text(
              'Đọc thông báo biến động số dư và ghi thành giao dịch. '
              'Mọi thứ xử lý trong máy, không gửi đi đâu.',
            ),
            value: enabled,
            onChanged: (v) async {
              await ref.read(autoTrackRepositoryProvider).setEnabled(v);
              await _apply();
            },
          ),
          if (enabled) ...[
            const _ListenerStatus(),
            const _SectionLabel('Ngân hàng'),
            for (final parser in kParsers)
              _BankCard(
                parser: parser,
                app: apps.where((a) => a.parserId == parser.id).firstOrNull,
                onChanged: _apply,
              ),
            const _SectionLabel('Ghi mẫu cho ngân hàng mới'),
            for (final app in apps.where((a) => a.parserId == null))
              _CaptureTile(app: app, onChanged: _apply),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Ghi mẫu một app'),
              subtitle: const Text(
                'Lưu thông báo của app đó trong 7 ngày, không ghi giao dịch. '
                'Dùng để viết bộ đọc cho ngân hàng chưa hỗ trợ.',
              ),
              onTap: _addCapture,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.label_important_outline),
              title: const Text('Phân loại giao dịch'),
              subtitle: const Text('Hàng chờ: chưa phân loại và cần xem lại'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReviewScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Phân loại tự động'),
              subtitle: const Text('Người nhận đã học và từ khoá'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategorizeRulesScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_outlined),
              title: const Text('Nhật ký thông báo'),
              subtitle: const Text('Tin đã nhận và vì sao có / không ghi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventLogScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addCapture() async {
    final app = await Navigator.push<LaunchableApp>(
      context,
      MaterialPageRoute(
        builder: (_) => const AppPickerScreen(title: 'Chọn app để ghi mẫu'),
      ),
    );
    if (app == null) return;
    await ref.read(autoTrackRepositoryProvider).startCapture(
      packageName: app.packageName,
      label: app.label,
      until: DateTime.now().add(const Duration(days: 7)),
    );
    await _apply();
  }
}

/// Quyền "Truy cập thông báo" của app.
class _ListenerStatus extends ConsumerWidget {
  const _ListenerStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final granted = ref.watch(listenerEnabledProvider);
    return granted.when(
      loading: () => const ListTile(title: Text('Đang kiểm tra quyền…')),
      error: (e, _) => ListTile(
        leading: Icon(Icons.error_outline, color: scheme.error),
        title: const Text('Máy này không hỗ trợ đọc thông báo'),
        subtitle: Text('$e'),
      ),
      data: (ok) => ok
          ? ListTile(
              leading: Icon(Icons.verified_outlined, color: scheme.primary),
              title: const Text('Đã có quyền đọc thông báo'),
              subtitle: const Text(
                'Trên Xiaomi: bật Tự khởi chạy, đặt Pin thành "Không giới '
                'hạn" và khoá app trong đa nhiệm để không bị tắt ngầm.',
              ),
            )
          : Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: scheme.errorContainer,
              child: ListTile(
                leading: Icon(
                  Icons.notifications_off_outlined,
                  color: scheme.onErrorContainer,
                ),
                title: Text(
                  'Chưa có quyền đọc thông báo',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
                subtitle: Text(
                  'Bật "Quản Lý Chi Tiêu" trong mục Truy cập thông báo.',
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
                trailing: FilledButton(
                  onPressed: () => ref
                      .read(autoTrackPlatformProvider)
                      .openListenerSettings(),
                  child: const Text('Mở'),
                ),
              ),
            ),
    );
  }
}

/// Một ngân hàng được hỗ trợ: app đọc từ đó, bật/tắt, ví nhận giao dịch.
class _BankCard extends ConsumerWidget {
  const _BankCard({
    required this.parser,
    required this.app,
    required this.onChanged,
  });

  final NotificationParser parser;
  final TrackedApp? app;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final auto = ref.read(autoTrackRepositoryProvider);
    final wallets = ref.watch(walletsProvider).value ?? const [];
    final bound = app;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    parser.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (bound != null)
                  Switch(
                    value: bound.enabled,
                    onChanged: (v) async {
                      await auto.setAppEnabled(bound.packageName, v);
                      await onChanged();
                    },
                  ),
              ],
            ),
            if (bound == null)
              _Unbound(parser: parser, onChanged: onChanged)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Đọc từ: ${bound.label ?? bound.packageName}',
                      style: TextStyle(color: scheme.outline, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickApp(context, ref),
                    child: const Text('Đổi app'),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: DropdownButtonFormField<int?>(
                  initialValue: wallets.any((w) => w.id == bound.defaultWalletId)
                      ? bound.defaultWalletId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Ví nhận giao dịch',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Chưa chọn'),
                    ),
                    for (final w in wallets)
                      DropdownMenuItem(value: w.id, child: Text(w.name)),
                  ],
                  onChanged: (id) async {
                    await auto.setDefaultWallet(bound.packageName, id);
                    await onChanged();
                  },
                ),
              ),
              _AccountWallets(
                packageName: bound.packageName,
                wallets: wallets,
                onChanged: onChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickApp(BuildContext context, WidgetRef ref) async {
    final picked = await Navigator.push<LaunchableApp>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AppPickerScreen(title: 'App ${parser.displayName} trên máy'),
      ),
    );
    if (picked == null) return;
    await ref.read(autoTrackRepositoryProvider).bindParser(
      parserId: parser.id,
      packageName: picked.packageName,
      label: picked.label,
    );
    await onChanged();
  }
}

/// Ngân hàng chưa gắn với app nào: gợi ý app quen thuộc nếu máy có.
class _Unbound extends ConsumerStatefulWidget {
  const _Unbound({required this.parser, required this.onChanged});

  final NotificationParser parser;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_Unbound> createState() => _UnboundState();
}

class _UnboundState extends ConsumerState<_Unbound> {
  late final Future<String?> _installed = _findInstalled();

  Future<String?> _findInstalled() async {
    final platform = ref.read(autoTrackPlatformProvider);
    for (final pkg in widget.parser.knownPackages) {
      try {
        if (await platform.isPackageInstalled(pkg)) return pkg;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _installed,
      builder: (context, snap) {
        final pkg = snap.data;
        return Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (pkg != null)
              FilledButton(
                onPressed: () => _bind(pkg, widget.parser.displayName),
                child: const Text('Dùng app trên máy'),
              ),
            OutlinedButton(
              onPressed: _pick,
              child: Text(pkg == null ? 'Chọn app' : 'Chọn app khác'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bind(String packageName, String? label) async {
    await ref.read(autoTrackRepositoryProvider).bindParser(
      parserId: widget.parser.id,
      packageName: packageName,
      label: label,
    );
    await widget.onChanged();
  }

  Future<void> _pick() async {
    final picked = await Navigator.push<LaunchableApp>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AppPickerScreen(title: 'App ${widget.parser.displayName} trên máy'),
      ),
    );
    if (picked != null) await _bind(picked.packageName, picked.label);
  }
}

/// Ví riêng theo số đuôi tài khoản, khi một ngân hàng có nhiều tài khoản.
class _AccountWallets extends ConsumerWidget {
  const _AccountWallets({
    required this.packageName,
    required this.wallets,
    required this.onChanged,
  });

  final String packageName;
  final List<WalletWithBalance> wallets;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(accountWalletsProvider(packageName)).value ?? [];
    final auto = ref.read(autoTrackRepositoryProvider);
    String walletName(int id) =>
        wallets.where((w) => w.id == id).firstOrNull?.name ?? '(ví đã lưu trữ)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.credit_card, size: 20),
            title: Text('Tài khoản …${r.accountSuffix} → ${walletName(r.walletId)}'),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Bỏ',
              onPressed: () async {
                await auto.removeAccountWallet(r.id);
                await onChanged();
              },
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ví riêng cho một tài khoản'),
          onPressed: wallets.isEmpty ? null : () => _add(context, ref),
        ),
      ],
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final suffix = TextEditingController();
    int? walletId = wallets.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ví riêng cho tài khoản'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: suffix,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Số cuối của tài khoản',
                  helperText: '3–4 số cuối, như trong thông báo',
                ),
              ),
              DropdownButtonFormField<int>(
                initialValue: walletId,
                decoration: const InputDecoration(labelText: 'Ví'),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(w.name)),
                ],
                onChanged: (v) => setState(() => walletId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    final digits = suffix.text.replaceAll(RegExp(r'\D'), '');
    suffix.dispose();
    if (ok != true || digits.length < 3 || walletId == null) return;
    await ref
        .read(autoTrackRepositoryProvider)
        .setAccountWallet(packageName, digits, walletId!);
    await onChanged();
  }
}

/// Một app đang (hoặc đã hết hạn) ghi mẫu.
class _CaptureTile extends ConsumerWidget {
  const _CaptureTile({required this.app, required this.onChanged});

  final TrackedApp app;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final until = DateTime.fromMillisecondsSinceEpoch(app.captureUntil ?? 0);
    final active = until.isAfter(DateTime.now());
    return ListTile(
      leading: Icon(active ? Icons.science_outlined : Icons.timer_off_outlined),
      title: Text(app.label ?? app.packageName),
      subtitle: Text(
        active ? 'Ghi mẫu tới ${formatDateTime(until)}' : 'Đã hết hạn ghi mẫu',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Dừng ghi mẫu',
        onPressed: () async {
          await ref.read(autoTrackRepositoryProvider).removeTrackedApp(
            app.packageName,
          );
          await onChanged();
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
