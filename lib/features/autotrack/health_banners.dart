import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../wallets/adjust_balance_sheet.dart';
import 'autotrack_health.dart';
import 'autotrack_providers.dart';
import 'autotrack_settings_screen.dart';
import 'event_log_screen.dart';

/// Cảnh báo của tính năng tự động ghi, trên màn Tổng quan. Mọi thứ ổn thì
/// không hiện gì.
class AutoTrackHealthBanners extends ConsumerWidget {
  const AutoTrackHealthBanners({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(autoTrackHealthProvider).value;
    if (health == null || !health.enabled || health.isHealthy) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        if (health.permissionGranted == false) const _PermissionBanner(),
        for (final f in health.formatChanges) _FormatBanner(change: f),
        for (final m in health.mismatches) _BalanceBanner(mismatch: m),
        if (health.silentSince != null)
          _SilentBanner(since: health.silentSince!),
      ],
    );
  }
}

/// Khung chung của một cảnh báo.
class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.serious = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final List<Widget> actions;
  final bool serious;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = serious ? scheme.errorContainer : scheme.tertiaryContainer;
    final fg = serious ? scheme.onErrorContainer : scheme.onTertiaryContainer;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: bg,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(message, style: TextStyle(color: fg)),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(spacing: 4, children: actions),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionBanner extends ConsumerWidget {
  const _PermissionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Banner(
      serious: true,
      icon: Icons.notifications_off_outlined,
      title: 'Mất quyền đọc thông báo',
      message:
          'Giao dịch ngân hàng đang KHÔNG được tự ghi. Bật lại "Truy cập '
          'thông báo" cho app. Nếu nút bị mờ: Cài đặt → Ứng dụng → app này → '
          '⋮ → Cho phép cài đặt bị hạn chế.',
      actions: [
        TextButton(
          onPressed: () =>
              ref.read(autoTrackPlatformProvider).openListenerSettings(),
          child: const Text('Bật lại'),
        ),
      ],
    );
  }
}

class _FormatBanner extends StatelessWidget {
  const _FormatBanner({required this.change});
  final SuspectedFormatChange change;

  @override
  Widget build(BuildContext context) {
    return _Banner(
      serious: true,
      icon: Icons.report_gmailerrorred_outlined,
      title: '${change.bankName} có thể đã đổi mẫu thông báo',
      message:
          '${change.count} thông báo có số tiền nhưng app đọc không ra, nên '
          'chưa được ghi. Chúng vẫn được giữ lại và sẽ tự ghi khi app được '
          'cập nhật bộ đọc mới.',
      actions: [
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventLogScreen()),
          ),
          child: const Text('Xem thông báo'),
        ),
      ],
    );
  }
}

class _BalanceBanner extends ConsumerWidget {
  const _BalanceBanner({required this.mismatch});
  final BalanceMismatch mismatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = mismatch;
    return _Banner(
      icon: Icons.balance_outlined,
      title: '${m.walletName} lệch ${formatVndSigned(m.diff)}',
      message:
          'Lúc ${formatDateTime(m.at)} ngân hàng báo số dư '
          '${formatVnd(m.bankBalance)}, app tính ${formatVnd(m.appBalance)}. '
          'Có thể một giao dịch bị lọt, bị ghi trùng, hoặc ngân hàng thu phí '
          'không báo.',
      actions: [
        TextButton(
          onPressed: () async {
            await dismissBalanceMismatch(
              ref.read(autoTrackRepositoryProvider),
              m,
            );
            ref.read(autoTrackHealthTickProvider.notifier).state++;
          },
          child: const Text('Bỏ qua'),
        ),
        FilledButton.tonal(
          onPressed: () => _adjust(context, ref),
          child: const Text('Điều chỉnh'),
        ),
      ],
    );
  }

  Future<void> _adjust(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final wallets = await ref.read(walletsProvider.future);
    final wallet = wallets.where((w) => w.id == mismatch.walletId).firstOrNull;
    if (wallet == null || !context.mounted) return;
    // Số dư thật bây giờ = số app đang có + phần lệch tại lúc thông báo.
    await showAdjustBalanceSheet(
      context,
      wallet,
      suggested: wallet.balance + mismatch.diff,
    );
    // Khoản điều chỉnh ghi vào lúc này, sau thông báo, nên không làm số tại
    // lúc thông báo khớp lại; điều chỉnh rồi thì coi như đã xử lý.
    if (await repo.balanceOf(wallet.id) != wallet.balance) {
      await dismissBalanceMismatch(ref.read(autoTrackRepositoryProvider), mismatch);
    }
    ref.read(autoTrackHealthTickProvider.notifier).state++;
  }
}

class _SilentBanner extends ConsumerWidget {
  const _SilentBanner({required this.since});
  final DateTime since;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = DateTime.now().difference(since).inDays;
    return _Banner(
      icon: Icons.hourglass_empty,
      title: 'Không nhận được thông báo ngân hàng $days ngày',
      message:
          'Tin cuối lúc ${formatDateTime(since)}. Nếu mấy ngày qua bạn vẫn có '
          'giao dịch, có thể máy đã tắt app ngầm: bật Tự khởi chạy và đặt Pin '
          '"Không giới hạn" cho app.',
      actions: [
        TextButton(
          onPressed: () async {
            await dismissSilence(ref.read(autoTrackRepositoryProvider), since);
            ref.read(autoTrackHealthTickProvider.notifier).state++;
          },
          child: const Text('Không sao'),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AutoTrackSettingsScreen()),
          ),
          child: const Text('Cài đặt'),
        ),
      ],
    );
  }
}
