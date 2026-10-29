import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/free_money.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../budgets/budget_screen.dart';

/// Tiền tự do: trả lời ba câu hỏi trong một thẻ.
///
/// - Tiêu được bao nhiêu mà không đụng tới tiền ăn? (số lớn)
/// - Nên tiêu bao nhiêu hôm nay? (mốc chia đều tới hết tháng)
/// - Khi nào phải nhịn? (hết tiền tự do thì thẻ chuyển đỏ và nói thẳng)
///
/// Thanh bên dưới chia số tiền đang có thành từng phần — nợ phải trả, giữ cho
/// ngân sách, tự do — để thấy ngay 4 triệu trong ví không phải 4 triệu tiêu
/// thoải mái.
class FreeMoneySection extends ConsumerWidget {
  const FreeMoneySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(freeMoneyProvider).valueOrNull;
    if (money == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final exhausted = money.isExhausted;
    final left = money.leftForToday;
    final target = money.budgetForToday;
    final overToday = !exhausted && left < 0;
    final alert = expenseColor(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showFreeMoneyBreakdown(context, money),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    exhausted ? Icons.do_not_disturb_on_outlined : Icons.bolt,
                    size: 18,
                    color: exhausted ? alert : scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exhausted ? 'Hết tiền tự do' : 'Tiêu tự do hôm nay',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: exhausted ? alert : null,
                      ),
                    ),
                  ),
                  if (!exhausted) ...[
                    Text(
                      overToday ? '-${formatVnd(-left)}' : formatVnd(left),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: overToday ? alert : scheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      ' / ${formatVndShort(target)}',
                      style: TextStyle(fontSize: 13, color: scheme.outline),
                    ),
                  ],
                  Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                ],
              ),
              const SizedBox(height: 10),
              _CompositionBar(money: money),
              const SizedBox(height: 8),
              _Legend(money: money),
              const SizedBox(height: 10),
              Text(
                _message(money),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: exhausted || overToday
                      ? FontWeight.w500
                      : FontWeight.normal,
                  color: exhausted || overToday
                      ? alert
                      : scheme.onSurfaceVariant,
                ),
              ),
              if (money.reserves.isEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Chưa giữ tiền cho mục nào. Đặt hạn mức cho ăn uống để app '
                  'giữ tiền ăn trước, phần còn lại mới là tự do.',
                  style: TextStyle(fontSize: 12, color: scheme.outline),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _message(FreeMoney m) {
    final protected = m.reserves.map((r) => r.name).join(', ');
    if (m.free < 0) {
      return 'Ví đang thiếu ${formatVnd(-m.free)} so với số cần giữ cho '
          '${protected.isEmpty ? 'các khoản nợ' : protected}. Nhịn mọi khoản '
          'ngoài ngân sách cho tới khi có thêm tiền.';
    }
    if (m.free == 0) {
      return 'Vừa hết tiền tự do. Từ giờ mọi khoản ngoài '
          '${protected.isEmpty ? 'số nợ phải trả' : protected} sẽ lấn vào '
          'tiền đã giữ.';
    }
    if (m.leftForToday < 0) {
      return 'Hôm nay tiêu tự do lố ${formatVnd(-m.leftForToday)}. '
          '${m.daysRemaining > 0 ? 'Những ngày sau còn '
                    '${formatVnd(m.perDayAfterToday)}/ngày.' : ''}';
    }
    if (m.daysRemaining <= 0) {
      return 'Hôm nay là ngày cuối tháng. Còn ${formatVnd(m.free)} tự do.';
    }
    return 'Còn ${formatVnd(m.free)} tự do cho ${m.daysRemaining + 1} ngày '
        'tới hết tháng. Tiêu đều dưới mốc mỗi ngày thì không bao giờ phải '
        'đụng vào tiền ${protected.isEmpty ? 'đã giữ' : protected.toLowerCase()}.';
  }
}

/// Thanh chia tiền đang có thành: nợ | giữ cho ngân sách | tự do.
///
/// Một tông màu, đậm nhất là phần tự do vì đó là phần được tiêu; phần đã giữ
/// nhạt hơn, nợ màu xám. Nhãn chữ ở chú thích bên dưới mang danh tính, màu chỉ
/// để phân vùng.
class _CompositionBar extends StatelessWidget {
  const _CompositionBar({required this.money});

  final FreeMoney money;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = _parts(money, scheme);
    final total = parts.fold<int>(0, (s, p) => s + p.amount);

    if (total <= 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              Expanded(
                // Phần quá nhỏ vẫn phải thấy được một vạch.
                flex: (parts[i].amount * 1000 ~/ total).clamp(8, 1000),
                child: ColoredBox(color: parts[i].color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Các phần của thanh, theo thứ tự trái sang phải. Chỉ gồm phần lớn hơn 0.
///
/// Khi ví không đủ, các phần giữ chỗ bị co lại cho vừa số tiền đang có — thanh
/// luôn biểu diễn đúng số tiền thật trong ví. Vì vậy bắt đầu từ tiền trong ví
/// ([FreeMoney.spendable] cộng lại nợ), và nợ được lấy ra trước như cách
/// [FreeMoney.spendable] đã trừ.
List<({String label, int amount, Color color})> _parts(
  FreeMoney m,
  ColorScheme scheme,
) {
  final reserveColor = scheme.primary.withValues(alpha: 0.4);
  final owedColor = scheme.outline;
  final freeColor = scheme.primary;

  final inWallet = m.spendable + m.owed;
  var cash = inWallet > 0 ? inWallet : 0;
  final result = <({String label, int amount, Color color})>[];
  void take(String label, int want, Color color) {
    final got = want < cash ? want : cash;
    if (got > 0) result.add((label: label, amount: got, color: color));
    cash -= got;
  }

  take('Nợ phải trả', m.owed, owedColor);
  take('Giữ cho ngân sách', m.reserved, reserveColor);
  take('Tự do', cash, freeColor);
  return result;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.money});

  final FreeMoney money;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = _parts(money, scheme);
    final shortBy = money.free < 0 ? -money.free : 0;

    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final p in parts)
          _LegendItem(
            color: p.color,
            text: '${p.label} ${formatVndShort(p.amount)}',
          ),
        if (shortBy > 0)
          _LegendItem(
            color: expenseColor(context),
            text: 'Thiếu ${formatVndShort(shortBy)}',
            hollow: true,
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.text,
    this.hollow = false,
  });

  final Color color;
  final String text;
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: hollow ? null : color,
            border: hollow ? Border.all(color: color, width: 1.5) : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Bảng tính ra con số tiền tự do, từng dòng một.
void showFreeMoneyBreakdown(BuildContext context, FreeMoney m) {
  final navigator = Navigator.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;

      Widget row(String label, int value, {bool bold = false, Color? color}) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Text(
                formatVnd(value),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tiền tự do được tính thế nào',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (m.owed > 0) ...[
                row('Tiền trong ví, trừ quỹ', m.spendable + m.owed),
                row('− Nợ phải trả', m.owed),
              ],
              row('Tiền tiêu được', m.spendable, bold: m.owed > 0),
              for (final r in m.reserves)
                row('− Giữ cho ${r.name} tới hết tháng', r.amount),
              const Divider(height: 20),
              row(
                'Tiền tự do',
                m.free,
                bold: true,
                color: m.free < 0 ? expenseColor(context) : scheme.primary,
              ),
              const SizedBox(height: 12),
              if (m.free > 0) ...[
                row('Nên tiêu hôm nay tối đa', m.budgetForToday),
                if (m.spentToday > 0)
                  row('Hôm nay đã tiêu tự do', m.spentToday),
                if (m.daysRemaining > 0)
                  row('Những ngày sau, mỗi ngày', m.perDayAfterToday),
                const SizedBox(height: 12),
              ],
              Text(
                'Tiền quỹ đã được trừ sẵn khỏi tiền tiêu được. Phần giữ cho '
                'ngân sách là số hạn mức còn lại của tháng này — tiêu trong '
                'hạn mức thì tiền tự do không đổi. Chi vào mục không có hạn '
                'mức, cho mượn hay trả dùm thì lấy từ tiền tự do.',
                style: TextStyle(fontSize: 12.5, color: scheme.outline),
              ),
              const SizedBox(height: 4),
              Text(
                'Tiền tự do chỉ tính tới hết tháng. Nếu lương tháng sau về '
                'trễ, hãy chuyển trước một phần vào quỹ để khỏi tiêu mất.',
                style: TextStyle(fontSize: 12.5, color: scheme.outline),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    navigator
                      ..pop()
                      ..push(
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      );
                  },
                  child: const Text('Chỉnh ngân sách'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
