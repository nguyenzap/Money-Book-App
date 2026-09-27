import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Hạn mức chi tiêu theo từng danh mục, kèm tiến độ trong tháng.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthKey = ref.watch(selectedMonthProvider);
    final budgets = ref.watch(budgetsProvider(monthKey));
    // Số dư ví hôm nay chỉ có nghĩa với tháng này.
    final isCurrent = monthKey == monthKeyOf(ref.watch(todayProvider));
    final cash = isCurrent
        ? ref.watch(spendableAssetsProvider).valueOrNull
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ngân sách')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBudgetEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Đặt hạn mức'),
      ),
      body: budgets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              title: 'Chưa đặt hạn mức nào',
              message: 'Đặt hạn mức tháng cho từng danh mục để biết khi nào '
                  'mình sắp tiêu quá tay.',
              action: FilledButton.icon(
                onPressed: () => showBudgetEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Đặt hạn mức'),
              ),
            );
          }

          final totalLimit =
              list.fold<int>(0, (sum, b) => sum + b.limitAmount);
          final totalSpent = list.fold<int>(0, (sum, b) => sum + b.spent);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _MonthHeader(monthKey: monthKey),
              const SizedBox(height: 12),
              _OverallCard(
                limit: totalLimit,
                spent: totalSpent,
                monthKey: monthKey,
                cash: cash,
              ),
              const SizedBox(height: 20),
              for (final b in list) ...[
                _BudgetCard(progress: b),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Text(
                'Chỉ những khoản bạn thực sự chi mới tính vào đây. Tiền trả '
                'dùm cho người khác nằm ở sổ nợ nên không làm vượt hạn mức.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MonthHeader extends ConsumerWidget {
  const _MonthHeader({required this.monthKey});

  final int monthKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          onPressed: isCurrent
              ? null
              : () => ref.read(selectedMonthProvider.notifier).state =
                  nextMonthKey(monthKey),
        ),
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({
    required this.limit,
    required this.spent,
    required this.monthKey,
    this.cash,
  });

  final int limit;
  final int spent;
  final int monthKey;

  /// Tiền tiêu được trong ví, null nếu không xét (tháng đã qua).
  final int? cash;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = limit - spent;
    final over = spent > limit;

    // Gộp mọi hạn mức lại thành một tiến độ chung để nói về nhịp tổng thể.
    final overall = BudgetProgress(
      budgetId: -1,
      categoryId: -1,
      categoryName: '',
      limitAmount: limit,
      spent: spent,
      isRecurring: true,
      monthKey: monthKey,
      daysInMonth: daysInMonth(monthKey),
      daysElapsed: daysElapsedIn(monthKey),
    ).withCashCap(cash);

    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              over ? 'Đã vượt tổng hạn mức' : 'Còn lại trong tháng',
              style: TextStyle(color: scheme.outline, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              formatVnd(remaining.abs()),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: over ? expenseColor(context) : scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 14),
            PaceMarkerBar(
              progress: overall,
              color: over ? expenseColor(context) : scheme.primary,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đã tiêu ${formatVnd(spent)}',
                  style: TextStyle(fontSize: 12.5, color: scheme.outline),
                ),
                Text(
                  'Hạn mức ${formatVnd(limit)}',
                  style: TextStyle(fontSize: 12.5, color: scheme.outline),
                ),
              ],
            ),
            if (!overall.isPastMonth && overall.daysRemaining > 0) ...[
              const SizedBox(height: 12),
              Divider(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      overall.spendable > 0
                          ? 'Còn ${overall.daysRemaining} ngày · '
                                '${formatVnd(overall.remainingDailyAllowance)}'
                                '/ngày'
                          : overall.remaining > 0
                          ? 'Còn ${overall.daysRemaining} ngày, ví đã hết '
                                'tiền tiêu được'
                          : 'Còn ${overall.daysRemaining} ngày, đã hết '
                                'hạn mức',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  _PaceBadge(pace: overall.pace),
                ],
              ),
              if (overall.isLimitedByCash) ...[
                const SizedBox(height: 10),
                Text(
                  'Ví chỉ còn ${formatVnd(overall.spendable)} tiêu được, ít '
                  'hơn ${formatVnd(overall.remaining)} còn lại của các hạn '
                  'mức. Mức mỗi ngày ở trên đã tính theo tiền thật.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: paceStyle(context, BudgetPace.fast).color,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Nhãn ngắn cho nhịp độ, dùng ở chỗ chật.
class _PaceBadge extends StatelessWidget {
  const _PaceBadge({required this.pace});

  final BudgetPace pace;

  @override
  Widget build(BuildContext context) {
    final style = paceStyle(context, pace);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        progress.colorValue == null ? null : Color(progress.colorValue!);
    final barColor = progress.isOver
        ? expenseColor(context)
        : progress.isNearLimit
            ? const Color(0xFFEF6C00)
            : (color ?? scheme.primary);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showBudgetEditor(context, editing: progress),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconAvatar(
                    icon: iconFor(
                      progress.iconKey,
                      fallback: Icons.label_outline,
                    ),
                    color: color,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.categoryName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          progress.isRecurring
                              ? 'Mọi tháng'
                              : 'Riêng tháng này',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress.ratio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PaceMarkerBar(progress: progress, color: barColor),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    formatVnd(progress.spent),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    ' / ${formatVnd(progress.limitAmount)}',
                    style: TextStyle(fontSize: 13, color: scheme.outline),
                  ),
                  const Spacer(),
                  if (progress.isOver)
                    _StatusChip(
                      label: 'Vượt ${formatVndShort(-progress.remaining)}',
                      color: expenseColor(context),
                      icon: Icons.error_outline,
                    )
                  else if (progress.isNearLimit)
                    _StatusChip(
                      label: 'Sắp hết',
                      color: const Color(0xFFEF6C00),
                      icon: Icons.warning_amber_outlined,
                    )
                  else
                    Text(
                      'Còn ${formatVndShort(progress.remaining)}',
                      style: TextStyle(fontSize: 12.5, color: scheme.outline),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              BudgetPaceRow(progress: progress),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh tiến độ kèm một vạch đánh dấu vị trí "đáng lẽ đang ở đây".
///
/// Vạch nằm ở chỗ tương ứng với phần tháng đã trôi qua. Phần tô vượt qua vạch
/// nghĩa là đang tiêu nhanh hơn nhịp — nhìn một cái là thấy, không cần đọc số.
class PaceMarkerBar extends StatelessWidget {
  const PaceMarkerBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
  });

  final BudgetProgress progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showMarker = !progress.isPastMonth &&
        progress.daysElapsed > 0 &&
        progress.daysElapsed < progress.daysInMonth;
    final markerAt = progress.daysInMonth == 0
        ? 0.0
        : progress.daysElapsed / progress.daysInMonth;

    return SizedBox(
      height: height + 6,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.ratio.clamp(0.0, 1.0),
              minHeight: height,
              backgroundColor:
                  scheme.surfaceContainerHighest.withValues(alpha: 0.8),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (showMarker)
            LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: (constraints.maxWidth * markerAt)
                        .clamp(0.0, constraints.maxWidth - 2),
                  ),
                  child: Container(
                    width: 2,
                    height: height + 6,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Màu và biểu tượng ứng với từng tình trạng nhịp độ.
///
/// Luôn đi kèm biểu tượng và chữ, không bao giờ chỉ dựa vào màu.
/// Cảnh báo tiền thật trong ví không còn đủ cho phần còn lại của hạn mức.
///
/// Hạn mức chỉ đếm chi tiêu của đúng danh mục đó, nên tiêu lố ở chỗ khác thì
/// hạn mức vẫn báo "còn nhiều" trong khi ví đã cạn. Dòng này nói thẳng ra.
class CashLimitNote extends StatelessWidget {
  const CashLimitNote({super.key, required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    if (!progress.isLimitedByCash) return const SizedBox.shrink();
    final style = paceStyle(context, BudgetPace.fast);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            size: 14,
            color: style.color,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Tiền trong ví chỉ còn đủ ${formatVnd(progress.spendable)} cho '
            'mục này, ít hơn ${formatVnd(progress.remaining)} còn lại của hạn '
            'mức — phần chênh đã tiêu sang khoản khác.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: style.color,
            ),
          ),
        ),
      ],
    );
  }
}

({Color color, IconData icon, String label}) paceStyle(
  BuildContext context,
  BudgetPace pace,
) {
  return switch (pace) {
    BudgetPace.over => (
        color: expenseColor(context),
        icon: Icons.error_outline,
        label: 'Đã vượt',
      ),
    BudgetPace.fast => (
        color: const Color(0xFFEF6C00),
        icon: Icons.trending_up,
        label: 'Tiêu nhanh',
      ),
    BudgetPace.onTrack => (
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.check_circle_outline,
        label: 'Đúng nhịp',
      ),
    BudgetPace.slow => (
        color: incomeColor(context),
        icon: Icons.trending_down,
        label: 'Đang dư dả',
      ),
  };
}

/// Phần nói về nhịp độ tiêu tiền của một hạn mức.
///
/// Trả lời hai câu hỏi mà con số "đã tiêu bao nhiêu" không trả lời được:
/// tiêu như vậy có nhanh quá so với thời điểm này của tháng không, và những
/// ngày còn lại được tiêu bao nhiêu mỗi ngày thì vừa đủ.
class BudgetPaceRow extends StatelessWidget {
  const BudgetPaceRow({super.key, required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    if (progress.isPastMonth) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final style = paceStyle(context, progress.pace);
    final canStillSpend = progress.daysRemaining > 0 && progress.spendable > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 16, color: style.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _headline(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: style.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            canStillSpend
                ? 'Còn ${progress.daysRemaining} ngày, tiêu dưới '
                    '${formatVnd(progress.remainingDailyAllowance)} mỗi ngày '
                    'thì vừa đủ.'
                : _fallbackDetail(),
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          if (progress.isLimitedByCash) ...[
            const SizedBox(height: 6),
            CashLimitNote(progress: progress),
          ],
          if (progress.pace == BudgetPace.fast &&
              progress.daysUntilRunOut != null) ...[
            const SizedBox(height: 4),
            Text(
              // Nói số ngày còn cầm cự được, vì "hết tiền vào ngày 10" nghe
              // như còn xa trong khi thực ra chỉ còn vài hôm nữa.
              progress.daysUntilRunOut == 0
                  ? 'Giữ nhịp này thì hôm nay là hết tiền.'
                  : 'Giữ nhịp này thì khoảng ${progress.daysUntilRunOut} ngày '
                      'nữa là hết, tức ngày ${progress.projectedRunOutDay}.',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
          ],
        ],
      ),
    );
  }

  String _headline() {
    final avg = formatVndShort(progress.dailyAverage);
    final allowance = formatVndShort(progress.dailyAllowance);

    return switch (progress.pace) {
      BudgetPace.over =>
        'Đã vượt hạn mức ${formatVnd(-progress.remaining)}',
      BudgetPace.fast =>
        'Đang tiêu $avg mỗi ngày, cao hơn mức $allowance',
      BudgetPace.onTrack => 'Đúng nhịp — khoảng $avg mỗi ngày',
      BudgetPace.slow => 'Đang tiết kiệm — mới $avg mỗi ngày',
    };
  }

  String _fallbackDetail() {
    if (progress.remaining <= 0) {
      return 'Hạn mức tháng này đã dùng hết.';
    }
    if (progress.daysRemaining > 0) {
      return 'Ví đã hết tiền tiêu được dù hạn mức vẫn còn.';
    }
    return 'Hết tháng rồi, còn dư ${formatVnd(progress.remaining)}.';
  }
}

/// Nhãn trạng thái, luôn kèm biểu tượng để không chỉ dựa vào màu.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showBudgetEditor(
  BuildContext context, {
  BudgetProgress? editing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _BudgetEditor(editing: editing),
    ),
  );
}

class _BudgetEditor extends ConsumerStatefulWidget {
  const _BudgetEditor({this.editing});

  final BudgetProgress? editing;

  @override
  ConsumerState<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends ConsumerState<_BudgetEditor> {
  late final TextEditingController _controller;
  int? _categoryId;
  late bool _everyMonth;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _controller = TextEditingController(
      text: editing == null ? '' : groupDigits(editing.limitAmount),
    );
    _categoryId = editing?.categoryId;
    _everyMonth = editing?.isRecurring ?? true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseVnd(_controller.text);
    if (_categoryId == null) {
      showSnack(context, 'Hãy chọn danh mục');
      return;
    }
    if (amount <= 0) {
      showSnack(context, 'Nhập hạn mức lớn hơn 0');
      return;
    }

    final repo = ref.read(repositoryProvider);
    final monthKey = ref.read(selectedMonthProvider);

    // Đổi phạm vi áp dụng thì bản ghi cũ không còn đúng nữa, phải dọn đi.
    if (_isEditing && widget.editing!.isRecurring != _everyMonth) {
      await repo.deleteBudget(widget.editing!.budgetId);
    }

    await repo.setBudget(
      categoryId: _categoryId!,
      limitAmount: amount,
      monthKey: _everyMonth ? null : monthKey,
    );

    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Đã đặt hạn mức');
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: 'Xoá hạn mức?',
      message: 'Xoá hạn mức của "${widget.editing!.categoryName}". '
          'Các giao dịch vẫn còn nguyên.',
    );
    if (!ok || !mounted) return;

    await ref.read(repositoryProvider).deleteBudget(widget.editing!.budgetId);
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Đã xoá hạn mức');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = ref.watch(expenseCategoriesProvider);
    final monthKey = ref.watch(selectedMonthProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Sửa hạn mức' : 'Đặt hạn mức',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Xoá hạn mức',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _controller,
              label: 'Hạn mức mỗi tháng',
              autofocus: !_isEditing,
              showQuickAdd: false,
            ),
            const SizedBox(height: 20),
            Text('Danh mục', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            categories.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi: $e'),
              data: (list) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in list)
                    ChoiceChip(
                      selected: _categoryId == c.id,
                      showCheckmark: false,
                      onSelected: _isEditing
                          ? null
                          : (_) => setState(() => _categoryId = c.id),
                      avatar: Icon(
                        iconFor(c.iconKey, fallback: Icons.label_outline),
                        size: 18,
                        color:
                            c.colorValue == null ? null : Color(c.colorValue!),
                      ),
                      label: Text(c.name),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _everyMonth,
              onChanged: (v) => setState(() => _everyMonth = v),
              title: const Text('Áp dụng cho mọi tháng'),
              subtitle: Text(
                _everyMonth
                    ? 'Hạn mức này lặp lại hàng tháng'
                    : 'Chỉ áp dụng cho ${monthKeyLabel(monthKey)}',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
