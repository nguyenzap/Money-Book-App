import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

final budgetsProvider =
    StreamProvider.family<List<BudgetProgress>, int>((ref, monthKey) {
  return ref.watch(repositoryProvider).watchBudgets(monthKey);
});

/// Hạn mức chi tiêu theo từng danh mục, kèm tiến độ trong tháng.
class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthKey = ref.watch(selectedMonthProvider);
    final budgets = ref.watch(budgetsProvider(monthKey));

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
              _OverallCard(limit: totalLimit, spent: totalSpent),
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
  const _OverallCard({required this.limit, required this.spent});

  final int limit;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = limit - spent;
    final ratio = limit == 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final over = spent > limit;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                valueColor: AlwaysStoppedAnimation(
                  over ? expenseColor(context) : scheme.primary,
                ),
              ),
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
          ],
        ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
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
            ],
          ),
        ),
      ),
    );
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
