import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../settings/settings_screen.dart';
import '../templates/template_screen.dart';
import 'budget_today_section.dart';
import 'free_money_section.dart';
import '../transactions/tx_editor_screen.dart';
import '../transactions/tx_tile.dart';
import '../wallets/wallet_detail_screen.dart';
import '../wallets/wallet_list_screen.dart';

/// Màn hình đầu tiên: tổng tài sản, các ví, thu chi tháng này và vài giao dịch
/// gần nhất.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: const [
          _TotalAssetsCard(),
          SizedBox(height: 12),
          // Ngay dưới số tiền đang có là câu hỏi quan trọng hơn: trong đó bao
          // nhiêu được tiêu thoải mái mà không đụng tới tiền ăn.
          FreeMoneySection(),
          // Không có mẫu thì cụm này tự ẩn, kể cả khoảng cách.
          _TemplatesSection(),
          SizedBox(height: 20),
          // Ngân sách nằm ngay dưới tổng tài sản: đây là con số quyết định
          // bữa trưa hôm nay, không phải thứ phải đi tìm trong Cài đặt.
          BudgetTodaySection(),
          SizedBox(height: 20),
          _MonthSummaryCard(),
          SizedBox(height: 20),
          _WalletsSection(),
          SizedBox(height: 20),
          _RecentSection(),
        ],
      ),
    );
  }
}

/// Tổng tài sản, mặc định chỉ tính phần thực sự tiêu được.
///
/// Tiền quỹ đã có chỗ đến rồi nên gộp vào đây dễ làm mình tưởng còn nhiều tiền
/// hơn thực tế. Bấm con mắt thì mới hiện thêm phần quỹ.
class _TotalAssetsCard extends ConsumerWidget {
  const _TotalAssetsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendable = ref.watch(spendableAssetsProvider);
    final inFunds = ref.watch(totalInFundsProvider).valueOrNull ?? 0;
    final showFunds = ref.watch(showFundsInTotalProvider);
    final scheme = Theme.of(context).colorScheme;

    final value = spendable.valueOrNull;
    final shown = value == null ? null : (showFunds ? value + inFunds : value);

    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: inFunds == 0
            ? null
            : () => ref.read(showFundsInTotalProvider.notifier).state =
                !showFunds,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    showFunds && inFunds > 0
                        ? 'Tổng tài sản, tính cả quỹ'
                        : 'Tiền tiêu được',
                    style: TextStyle(
                      color:
                          scheme.onPrimaryContainer.withValues(alpha: 0.75),
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (inFunds > 0) ...[
                    const SizedBox(width: 6),
                    Icon(
                      showFunds
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 16,
                      color:
                          scheme.onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              if (shown == null)
                const SizedBox(
                  height: 40,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Text(
                  formatVnd(shown),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              // Khi mắt nhắm thì không hé lộ phần để dành — chỉ con số tiêu
              // được. Muốn biết thì bấm con mắt.
              if (inFunds > 0 && showFunds) ...[
                const SizedBox(height: 8),
                Text(
                  'Trong đó ${formatVnd(inFunds)} đã dành cho quỹ',
                  style: TextStyle(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút ghi nhanh theo mẫu: bấm là ghi, giữ để sửa mẫu.
class _TemplatesSection extends ConsumerWidget {
  const _TemplatesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).valueOrNull ?? const [];
    if (templates.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Ghi nhanh',
            actionLabel: 'Quản lý',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TemplateScreen()),
            ),
          ),
          const SizedBox(height: 4),
          TemplateChips(
            templates: templates,
            onTap: (t) => useTemplate(context, ref, t),
            onLongPress: (t) => showTemplateEditor(context, editing: t),
          ),
        ],
      ),
    );
  }
}

class _MonthSummaryCard extends ConsumerWidget {
  const _MonthSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(currentMonthTotalsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthKeyLabel(currentMonthKey()),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 14),
            totals.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi: $e'),
              data: (t) => Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'Thu',
                      value: t.income,
                      color: incomeColor(context),
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Chi',
                      value: t.expense,
                      color: expenseColor(context),
                    ),
                  ),
                  Expanded(
                    // Thay cho "Còn lại" (Thu trừ Chi): với người chưa ghi thu
                    // nhập thì con số đó chỉ là ô "Chi" lặp lại kèm dấu trừ.
                    // Chi mỗi ngày nói lên nhịp độ, thứ thực sự dùng được.
                    child: _MiniStat(
                      label: 'Chi/ngày',
                      value: _dailyAverage(t.expense),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chi trung bình mỗi ngày tính trên số ngày đã trôi qua của tháng.
int _dailyAverage(int monthExpense) {
  final elapsed = daysElapsedIn(currentMonthKey());
  if (elapsed <= 0) return 0;
  return monthExpense ~/ elapsed;
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatVndShort(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletsSection extends ConsumerWidget {
  const _WalletsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Ví của tôi',
          actionLabel: 'Quản lý',
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WalletListScreen()),
          ),
        ),
        const SizedBox(height: 8),
        wallets.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Lỗi: $e'),
          data: (list) {
            if (list.isEmpty) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.add_card),
                  title: const Text('Thêm ví đầu tiên'),
                  subtitle: const Text('Tiền mặt, MoMo, MB Bank...'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WalletListScreen(),
                    ),
                  ),
                ),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 68),
                    _WalletRow(item: list[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.item});

  final WalletWithBalance item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.wallet.colorValue == null ? null : Color(item.wallet.colorValue!);
    return ListTile(
      leading: IconAvatar(
        icon: iconFor(item.wallet.iconKey, fallback: Icons.wallet),
        color: color,
      ),
      title: Text(item.name),
      trailing: MoneyText(item.balance, colored: false),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletDetailScreen(walletId: item.id),
        ),
      ),
    );
  }
}

class _RecentSection extends ConsumerWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(recentTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Gần đây'),
        const SizedBox(height: 8),
        txs.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Lỗi: $e'),
          data: (list) {
            if (list.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      const Text('Chưa có giao dịch nào'),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => openTxEditor(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Ghi khoản đầu tiên'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final shown = list.take(8).toList();
            return Card(
              child: Column(
                children: [
                  for (var i = 0; i < shown.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 68),
                    TxTile(
                      view: shown[i],
                      onTap: () => openTxEditor(context, editing: shown[i]),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Bốn nút ghi nhanh, hiện trong bottom sheet khi bấm nút cộng. Có mẫu chi
/// tiêu thì các mẫu đứng trên cùng.
class QuickActionSheet extends ConsumerWidget {
  const QuickActionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).valueOrNull ?? const [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            if (templates.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TemplateChips(
                  templates: templates,
                  onTap: (t) {
                    // Sheet đóng ngay nên phải mượn context của Navigator để
                    // còn hiện thông báo hoàn tác và mở màn ghi.
                    final host = Navigator.of(context).context;
                    Navigator.pop(context);
                    useTemplate(host, ref, t);
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],
            for (final kind in [
              TxKind.expense,
              TxKind.income,
              TxKind.transfer,
            ])
              ListTile(
                leading: IconAvatar(icon: kind.icon),
                title: Text(kind.label),
                subtitle: Text(kind.hint),
                onTap: () {
                  Navigator.pop(context);
                  openTxEditor(context, initialKind: kind);
                },
              ),
            const Divider(),
            ListTile(
              leading: const IconAvatar(icon: Icons.handshake_outlined),
              title: const Text('Vay mượn'),
              subtitle: const Text('Cho mượn, thu nợ, vay, trả nợ'),
              onTap: () {
                Navigator.pop(context);
                openTxEditor(context, initialKind: TxKind.lend);
              },
            ),
          ],
        ),
      ),
    );
  }
}
