import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../budgets/budget_screen.dart';
import '../transactions/tx_editor_screen.dart';
import '../transactions/tx_tile.dart';

final _categoryTotalsProvider =
    StreamProvider.family<List<CategoryTotal>, int>((ref, monthKey) {
  return ref.watch(repositoryProvider).watchCategoryTotals(monthKey);
});

final _topExpensesProvider =
    StreamProvider.family<List<TxView>, int>((ref, monthKey) {
  return ref.watch(repositoryProvider).watchTopExpenses(monthKey);
});

/// Thống kê một tháng: thu chi, cơ cấu chi theo danh mục, so với tháng trước,
/// và các khoản chi lớn nhất.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthKey = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          const _MonthSwitcher(),
          const SizedBox(height: 16),
          _SummaryRow(monthKey: monthKey),
          const SizedBox(height: 20),
          _BudgetSummary(monthKey: monthKey),
          _CategoryBreakdown(monthKey: monthKey),
          const SizedBox(height: 20),
          _MonthComparison(monthKey: monthKey),
          const SizedBox(height: 20),
          _TopExpenses(monthKey: monthKey),
          const SizedBox(height: 16),
          Text(
            'Thống kê chỉ tính thu nhập và chi tiêu. Chuyển tiền giữa các ví, '
            'vay mượn và điều chỉnh số dư không được tính vào đây.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSwitcher extends ConsumerWidget {
  const _MonthSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthKey = ref.watch(selectedMonthProvider);
    final isCurrent = monthKey == currentMonthKey();

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Tháng trước',
          onPressed: () => ref.read(selectedMonthProvider.notifier).state =
              previousMonthKey(monthKey),
        ),
        Expanded(
          child: Center(
            child: Text(
              monthKeyLabel(monthKey),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Tháng sau',
          // Không cho xem tương lai — chưa có gì ở đó cả.
          onPressed: isCurrent
              ? null
              : () => ref.read(selectedMonthProvider.notifier).state =
                  nextMonthKey(monthKey),
        ),
      ],
    );
  }
}

class _SummaryRow extends ConsumerWidget {
  const _SummaryRow({required this.monthKey});

  final int monthKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(monthTotalsProvider(monthKey));

    return totals.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Lỗi: $e'),
      data: (t) => Row(
        children: [
          Expanded(
            child: _StatTile(
              label: 'Thu vào',
              value: t.income,
              color: incomeColor(context),
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Chi ra',
              value: t.expense,
              color: expenseColor(context),
              icon: Icons.arrow_upward,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Còn lại',
              value: t.net,
              color: amountColor(context, t.net),
              icon: Icons.savings_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final int value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
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
        ),
      ),
    );
  }
}

/// Những hạn mức đang gần chạm hoặc đã vượt.
///
/// Chỉ hiện khi có gì đáng chú ý — không có thì im lặng, để màn thống kê khỏi
/// dài thêm mà chẳng nói gì.
class _BudgetSummary extends ConsumerWidget {
  const _BudgetSummary({required this.monthKey});

  final int monthKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider(monthKey));
    final list = budgets.valueOrNull ?? const <BudgetProgress>[];
    final alerts =
        list.where((b) => b.isOver || b.isNearLimit).toList();

    if (alerts.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ngân sách cần để ý',
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
                child: const Text('Xem hết'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < alerts.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16),
                  _BudgetAlertRow(progress: alerts[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tiền trả dùm cho người khác không tính vào đây.',
            style: TextStyle(fontSize: 11.5, color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertRow extends StatelessWidget {
  const _BudgetAlertRow({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = progress.isOver;
    final color = over ? expenseColor(context) : const Color(0xFFEF6C00);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                over ? Icons.error_outline : Icons.warning_amber_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  progress.categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                over
                    ? 'Vượt ${formatVndShort(-progress.remaining)}'
                    : 'Còn ${formatVndShort(progress.remaining)}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  scheme.surfaceContainerHighest.withValues(alpha: 0.8),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cơ cấu chi tiêu theo danh mục.
///
/// Dùng thanh ngang xếp hạng thay vì biểu đồ tròn: danh mục do người dùng tự
/// thêm nên số lượng không giới hạn, mà quá 3-4 màu thì các lát bánh không còn
/// phân biệt được với nhau, nhất là với người mù màu. Ở dạng thanh, danh tính
/// đến từ nhãn chữ, còn màu chỉ mã hoá độ lớn (một tông, đậm dần).
class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown({required this.monthKey});

  final int monthKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(_categoryTotalsProvider(monthKey));
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi theo danh mục',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        totals.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Lỗi: $e'),
          data: (list) {
            if (list.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 28,
                  ),
                  child: Center(
                    child: Text(
                      'Tháng này chưa có khoản chi nào',
                      style: TextStyle(color: scheme.outline),
                    ),
                  ),
                ),
              );
            }

            final grand = list.fold<int>(0, (sum, c) => sum + c.total);
            final max = list.first.total;

            return Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    for (final item in list)
                      _CategoryBar(
                        item: item,
                        maxValue: max,
                        grandTotal: grand,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.item,
    required this.maxValue,
    required this.grandTotal,
  });

  final CategoryTotal item;
  final int maxValue;
  final int grandTotal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = maxValue == 0 ? 0.0 : item.total / maxValue;
    final share = grandTotal == 0 ? 0.0 : item.total / grandTotal * 100;

    // Một tông duy nhất, đậm dần theo giá trị: đây là so sánh độ lớn chứ không
    // phải phân biệt danh tính, nên không cần bảng màu nhiều sắc.
    final barColor = Color.lerp(
      scheme.primary.withValues(alpha: 0.35),
      scheme.primary,
      ratio,
    )!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                iconFor(item.iconKey, fallback: Icons.label_outline),
                size: 16,
                color: item.colorValue == null
                    ? scheme.onSurfaceVariant
                    : Color(item.colorValue!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${share.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
              const SizedBox(width: 10),
              Text(
                formatVnd(item.total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor:
                  scheme.surfaceContainerHighest.withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// So sánh tháng này với tháng trước.
class _MonthComparison extends ConsumerWidget {
  const _MonthComparison({required this.monthKey});

  final int monthKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(monthTotalsProvider(monthKey));
    final previous =
        ref.watch(monthTotalsProvider(previousMonthKey(monthKey)));
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'So với tháng trước',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: (current.valueOrNull == null || previous.valueOrNull == null)
                ? const LinearProgressIndicator()
                : Builder(
                    builder: (context) {
                      final now = current.value!;
                      final before = previous.value!;
                      final maxValue = [
                        now.income,
                        now.expense,
                        before.income,
                        before.expense,
                      ].reduce((a, b) => a > b ? a : b);

                      return Column(
                        children: [
                          _ComparisonRow(
                            label: monthKeyLabel(previousMonthKey(monthKey)),
                            income: before.income,
                            expense: before.expense,
                            maxValue: maxValue,
                            muted: true,
                          ),
                          const SizedBox(height: 16),
                          _ComparisonRow(
                            label: monthKeyLabel(monthKey),
                            income: now.income,
                            expense: now.expense,
                            maxValue: maxValue,
                          ),
                          const Divider(height: 28),
                          _DeltaLine(
                            label: 'Chi tiêu',
                            current: now.expense,
                            previous: before.expense,
                            // Chi ít hơn tháng trước là tin tốt.
                            lowerIsBetter: true,
                          ),
                          const SizedBox(height: 8),
                          _DeltaLine(
                            label: 'Thu nhập',
                            current: now.income,
                            previous: before.income,
                            lowerIsBetter: false,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendDot(color: incomeColor(context), label: 'Thu'),
            const SizedBox(width: 16),
            _LegendDot(color: expenseColor(context), label: 'Chi'),
            const Spacer(),
            Text(
              'Cột dài hơn = số tiền lớn hơn',
              style: TextStyle(fontSize: 11.5, color: scheme.outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.income,
    required this.expense,
    required this.maxValue,
    this.muted = false,
  });

  final String label;
  final int income;
  final int expense;
  final int maxValue;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final opacity = muted ? 0.45 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: muted ? FontWeight.normal : FontWeight.w600,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        _Bar(
          value: income,
          maxValue: maxValue,
          color: incomeColor(context).withValues(alpha: opacity),
        ),
        const SizedBox(height: 6),
        _Bar(
          value: expense,
          maxValue: maxValue,
          color: expenseColor(context).withValues(alpha: opacity),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : value / maxValue;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.7),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            formatVndShort(value),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeltaLine extends StatelessWidget {
  const _DeltaLine({
    required this.label,
    required this.current,
    required this.previous,
    required this.lowerIsBetter,
  });

  final String label;
  final int current;
  final int previous;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final delta = current - previous;

    if (previous == 0 && current == 0) {
      return Row(
        children: [
          Text(label, style: TextStyle(color: scheme.outline, fontSize: 13)),
          const Spacer(),
          Text('Không có dữ liệu',
              style: TextStyle(color: scheme.outline, fontSize: 13)),
        ],
      );
    }

    final good = lowerIsBetter ? delta <= 0 : delta >= 0;
    final color = delta == 0
        ? scheme.outline
        : good
            ? incomeColor(context)
            : expenseColor(context);
    final percent = previous == 0
        ? null
        : (delta / previous * 100);

    return Row(
      children: [
        Text(label, style: TextStyle(color: scheme.outline, fontSize: 13)),
        const Spacer(),
        Icon(
          delta == 0
              ? Icons.remove
              : delta > 0
                  ? Icons.trending_up
                  : Icons.trending_down,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          delta == 0
              ? 'không đổi'
              : '${formatVndSigned(delta)}'
                  '${percent == null ? '' : ' (${percent > 0 ? '+' : ''}'
                      '${percent.toStringAsFixed(0)}%)'}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TopExpenses extends ConsumerWidget {
  const _TopExpenses({required this.monthKey});

  final int monthKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = ref.watch(_topExpensesProvider(monthKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi nhiều nhất',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        top.when(
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
                  child: Center(
                    child: Text(
                      'Chưa có khoản chi nào',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
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
                    TxTile(
                      view: list[i],
                      onTap: () => openTxEditor(context, editing: list[i]),
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
