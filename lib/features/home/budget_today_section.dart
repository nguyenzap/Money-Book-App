import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../budgets/budget_screen.dart';

/// Tiến độ ngân sách hôm nay, đặt ngay ở màn Tổng quan.
///
/// Trả lời trong một cái liếc mắt: hôm nay đã tiêu bao nhiêu cho từng hạng mục,
/// so với mức nên tiêu mỗi ngày là bao nhiêu, và từ giờ tới cuối tháng còn được
/// bao nhiêu một ngày. Đây là những con số quyết định bữa trưa hôm nay, nên
/// chúng phải nằm ở chỗ mở app ra là thấy.
class BudgetTodaySection extends ConsumerWidget {
  const BudgetTodaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(currentBudgetsProvider);
    final todaySpending = ref.watch(todaySpendingProvider);

    return budgets.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const _BudgetInvite();

        final spentToday = todaySpending.valueOrNull ?? const <int, int>{};
        // Hạn mức đang căng lên đầu để không bị bỏ sót.
        final sorted = [...list]..sort((a, b) {
            if (a.needsAttention != b.needsAttention) {
              return a.needsAttention ? -1 : 1;
            }
            return b.ratio.compareTo(a.ratio);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Ngân sách hôm nay',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetScreen()),
                  ),
                  child: const Text('Quản lý'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < sorted.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16),
                    _BudgetTodayRow(
                      progress: sorted[i],
                      spentToday: spentToday[sorted[i].categoryId] ?? 0,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Một hạng mục: hôm nay đã tiêu bao nhiêu so với mức nên tiêu.
class _BudgetTodayRow extends StatelessWidget {
  const _BudgetTodayRow({required this.progress, required this.spentToday});

  final BudgetProgress progress;
  final int spentToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        progress.colorValue == null ? null : Color(progress.colorValue!);

    // Mức nên tiêu hôm nay: chia đều số tiền còn lại cho số ngày còn lại, chứ
    // không phải mức trung bình cả tháng. Tiêu lố hôm qua thì hôm nay mức này
    // tự thấp xuống — đúng thứ cần biết để tự điều chỉnh.
    final target = progress.daysRemaining > 0 && progress.remaining > 0
        ? progress.remainingDailyAllowance + spentToday
        : progress.dailyAllowance;
    final overToday = target > 0 && spentToday > target;
    final barValue = target <= 0
        ? 1.0
        : (spentToday / target).clamp(0.0, 1.0).toDouble();
    final barColor = overToday ? expenseColor(context) : scheme.primary;

    return InkWell(
      onTap: () => showBudgetEditor(context, editing: progress),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  iconFor(progress.iconKey, fallback: Icons.label_outline),
                  size: 18,
                  color: color ?? scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    progress.categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatVnd(spentToday),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: overToday ? expenseColor(context) : scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  ' / ${formatVndShort(target)}',
                  style: TextStyle(fontSize: 13, color: scheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: barValue,
                minHeight: 6,
                backgroundColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _detail(context),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _detail(BuildContext context) {
    if (progress.isOver) {
      return 'Đã vượt hạn mức tháng ${formatVnd(-progress.remaining)}';
    }
    if (progress.daysRemaining <= 0) {
      return 'Hết tháng, còn dư ${formatVnd(progress.remaining)}';
    }

    final perDay = formatVnd(progress.remainingDailyAllowance);
    final left = 'Còn ${formatVnd(progress.remaining)} cho '
        '${progress.daysRemaining} ngày · $perDay/ngày';

    return switch (progress.pace) {
      BudgetPace.fast => '$left · đang tiêu nhanh hơn nhịp',
      _ => left,
    };
  }
}

/// Hiện khi chưa đặt hạn mức nào — mời đặt cái đầu tiên.
class _BudgetInvite extends StatelessWidget {
  const _BudgetInvite();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.savings_outlined),
        title: const Text('Đặt hạn mức chi tiêu'),
        subtitle: const Text(
          'Biết mỗi ngày được tiêu bao nhiêu cho từng hạng mục',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgetScreen()),
        ),
      ),
    );
  }
}
