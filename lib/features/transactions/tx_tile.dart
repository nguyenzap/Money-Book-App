import 'package:flutter/material.dart';

import '../../core/db/repository.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Một dòng giao dịch trong danh sách.
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.view, this.onTap});

  final TxView view;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final signed = view.signedAmount;
    final isTransfer = view.kind == TxKind.transfer;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: _leading(context),
      title: Text(
        view.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        [
          if (view.subtitle.isNotEmpty) view.subtitle,
          formatTime(DateTime.fromMillisecondsSinceEpoch(view.tx.occurredAt)),
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: scheme.outline, fontSize: 12.5),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isTransfer)
            Text(
              formatVnd(view.tx.amount),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            MoneyText(signed, signed: true),
          if (view.kind.isDebtKind)
            Text(
              view.kind.label,
              style: TextStyle(fontSize: 11, color: scheme.outline),
            ),
        ],
      ),
    );
  }

  Widget _leading(BuildContext context) {
    if (view.category != null) {
      return IconAvatar(
        icon: iconFor(view.category!.iconKey, fallback: Icons.label_outline),
        color: view.category!.colorValue == null
            ? null
            : Color(view.category!.colorValue!),
      );
    }
    if (view.person != null) {
      return InitialAvatar(
        name: view.person!.name,
        color: view.person!.avatarColor == null
            ? null
            : Color(view.person!.avatarColor!),
      );
    }
    return IconAvatar(
      icon: view.kind.icon,
      color: view.kind == TxKind.transfer ? kNeutralColor : null,
    );
  }
}

/// Tiêu đề nhóm ngày, kèm tổng thu chi trong ngày.
class DayHeader extends StatelessWidget {
  const DayHeader({super.key, required this.dayKey, required this.views});

  final int dayKey;
  final List<TxView> views;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var income = 0;
    var expense = 0;
    for (final v in views) {
      if (v.kind == TxKind.income) income += v.tx.amount;
      if (v.kind == TxKind.expense) expense += v.tx.amount;
    }

    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              dayHeaderLabel(dayKey),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          if (income > 0)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                '+${formatVnd(income)}',
                style: TextStyle(
                  color: incomeColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (expense > 0)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                '-${formatVnd(expense)}',
                style: TextStyle(
                  color: expenseColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
