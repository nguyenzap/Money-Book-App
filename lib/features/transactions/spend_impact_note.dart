import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/free_money.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

/// Nói trước khi bấm Ghi: khoản chi này lấy tiền từ đâu.
///
/// Nằm gọn trong hạn mức, lấy từ tiền tự do, hay đang lấn vào tiền đã giữ cho
/// ngân sách — cái cuối là lúc nên nhịn, và phải biết TRƯỚC khi tiêu chứ không
/// phải sau khi đã ghi.
class SpendImpactNote extends ConsumerWidget {
  const SpendImpactNote({
    super.key,
    required this.amount,
    required this.categoryId,
    this.outside = 0,
  });

  /// Phần tính vào danh mục [categoryId].
  final int amount;
  final int? categoryId;

  /// Phần nằm ngoài ngân sách, như tiền trả dùm hoặc cho mượn.
  final int outside;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (amount + outside <= 0) return const SizedBox.shrink();
    final money = ref.watch(freeMoneyProvider).valueOrNull;
    final budgets = ref.watch(currentBudgetsProvider).valueOrNull;
    if (money == null || budgets == null) return const SizedBox.shrink();

    final budget = categoryId == null
        ? null
        : budgets.where((b) => b.categoryId == categoryId).firstOrNull;
    final impact = money.preview(
      amount: amount,
      budget: budget,
      outside: outside,
    );

    final scheme = Theme.of(context).colorScheme;
    final warn = const Color(0xFFEF6C00);
    final (icon, color, text) = _describe(context, money, impact, warn);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? scheme.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: color == null ? null : FontWeight.w500,
                color: color ?? scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color?, String) _describe(
    BuildContext context,
    FreeMoney money,
    SpendImpact i,
    Color warn,
  ) {
    final inBudget = i.fromBudget > 0 && i.budgetName != null
        ? '${formatVnd(i.fromBudget)} nằm trong hạn mức ${i.budgetName}. '
        : '';

    if (i.fromReserve > 0) {
      final protected = money.reserves.map((r) => r.name).join(', ');
      return (
        Icons.warning_amber_rounded,
        expenseColor(context),
        '$inBudget${money.isExhausted ? 'Đã hết tiền tự do — ' : ''}'
            'khoản này lấn ${formatVnd(i.fromReserve)} vào tiền đã giữ cho '
            '${protected.isEmpty ? 'khoản nợ phải trả' : protected}. '
            'Nếu không cần gấp thì nên nhịn.',
      );
    }

    if (i.fromFree > 0) {
      final after = 'Còn ${formatVnd(i.freeAfter)} tự do tới hết tháng.';
      final budgetOver = (i.budgetLeftAfter ?? 0) < 0
          ? 'Vượt hạn mức ${i.budgetName} ${formatVnd(-i.budgetLeftAfter!)}, '
                'phần vượt '
          : '';
      final source =
          '$inBudget$budgetOver'
          '${budgetOver.isEmpty ? 'Lấy' : 'lấy'} ${formatVnd(i.fromFree)} từ '
          'tiền tự do. ';
      if (i.overToday) {
        return (
          Icons.trending_up,
          warn,
          '$source$after Quá mốc nên tiêu hôm nay '
              '(${formatVnd(money.leftForToday > 0 ? money.leftForToday : 0)}'
              ' còn lại).',
        );
      }
      return (Icons.bolt, null, '$source$after');
    }

    return (
      Icons.check_circle_outline,
      null,
      'Nằm trong hạn mức ${i.budgetName}, còn '
          '${formatVnd(i.budgetLeftAfter ?? 0)} sau khoản này. Tiền tự do '
          'không đổi.',
    );
  }
}
