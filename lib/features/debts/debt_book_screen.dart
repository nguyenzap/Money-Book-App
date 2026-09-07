import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../people/person_list_screen.dart';
import '../transactions/tx_editor_screen.dart';
import 'debt_person_screen.dart';
import 'settle_debt_sheet.dart';

/// Sổ nợ tổng hợp: ai nợ mình bao nhiêu, mình nợ ai bao nhiêu.
class DebtBookScreen extends ConsumerWidget {
  const DebtBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = ref.watch(debtsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ nợ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Danh bạ',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonListScreen()),
            ),
          ),
        ],
      ),
      // Không đặt nút nổi ở đây: khung ngoài đã có nút cộng ở giữa thanh dưới,
      // thêm nữa thì hai nút chồng lên nhau.
      body: debts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.handshake_outlined,
              title: 'Không có khoản nợ nào',
              message: 'Ghi lại khi bạn cho mượn tiền, trả dùm bữa ăn, '
                  'hoặc vay của ai đó.',
              action: FilledButton.icon(
                onPressed: () =>
                    openTxEditor(context, initialKind: TxKind.lend),
                icon: const Icon(Icons.add),
                label: const Text('Ghi khoản nợ'),
              ),
            );
          }

          final theyOwe = list.where((d) => d.theyOweMe).toList();
          final iOwe = list.where((d) => d.iOweThem).toList();
          final theyOweTotal =
              theyOwe.fold<int>(0, (sum, d) => sum + d.absAmount);
          final iOweTotal = iOwe.fold<int>(0, (sum, d) => sum + d.absAmount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              _NetCard(theyOweTotal: theyOweTotal, iOweTotal: iOweTotal),
              const SizedBox(height: 20),
              if (theyOwe.isNotEmpty) ...[
                _GroupHeader(
                  title: 'Người khác nợ tôi',
                  total: theyOweTotal,
                  color: incomeColor(context),
                ),
                const SizedBox(height: 8),
                _DebtGroup(items: theyOwe),
                const SizedBox(height: 20),
              ],
              if (iOwe.isNotEmpty) ...[
                _GroupHeader(
                  title: 'Tôi nợ người khác',
                  total: iOweTotal,
                  color: expenseColor(context),
                ),
                const SizedBox(height: 8),
                _DebtGroup(items: iOwe),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Gộp cả hai chiều lại thì cuối cùng mình đang dư hay đang thiếu.
///
/// Nói thẳng bằng câu chữ thay vì hiện một con số có dấu cộng trừ: "Chênh lệch
/// +200.000" là cách nói của sổ kế toán, còn cái người ta muốn biết là rốt cuộc
/// mình đang được nợ hay đang mắc nợ.
class _NetCard extends StatelessWidget {
  const _NetCard({required this.theyOweTotal, required this.iOweTotal});

  final int theyOweTotal;
  final int iOweTotal;

  @override
  Widget build(BuildContext context) {
    final net = theyOweTotal - iOweTotal;
    final scheme = Theme.of(context).colorScheme;
    final settled = net == 0;

    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              settled
                  ? 'Không ai nợ ai'
                  : net > 0
                      ? 'Bạn đang cho nợ'
                      : 'Bạn đang nợ',
              style: TextStyle(color: scheme.outline, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              settled ? '0 ₫' : formatVnd(net.abs()),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: settled
                    ? scheme.onSurface
                    : net > 0
                        ? incomeColor(context)
                        : expenseColor(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (theyOweTotal > 0 && iOweTotal > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Đã trừ ${formatVnd(theyOweTotal)} người khác nợ bạn '
                'với ${formatVnd(iOweTotal)} bạn nợ người khác',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.outline, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.title,
    required this.total,
    required this.color,
  });

  final String title;
  final int total;
  final Color color;

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
        Text(
          formatVnd(total),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _DebtGroup extends StatelessWidget {
  const _DebtGroup({required this.items});

  final List<DebtSummary> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68),
            _DebtTile(summary: items[i]),
          ],
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.summary});

  final DebtSummary summary;

  @override
  Widget build(BuildContext context) {
    final person = summary.person;
    final theyOweMe = summary.theyOweMe;

    return ListTile(
      leading: InitialAvatar(
        name: person.name,
        color: person.avatarColor == null ? null : Color(person.avatarColor!),
      ),
      title: Text(person.name),
      subtitle: Text(
        theyOweMe ? 'Nợ bạn' : 'Bạn nợ',
        style: TextStyle(
          fontSize: 12.5,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatVnd(summary.absAmount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: theyOweMe ? incomeColor(context) : expenseColor(context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 6),
          // Bấm một phát là mở bảng đã điền sẵn số tiền, người và loại giao
          // dịch — chỉ còn xác nhận.
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: theyOweMe ? 'Thu nợ' : 'Trả nợ',
            visualDensity: VisualDensity.compact,
            onPressed: () => showSettleDebtSheet(
              context,
              person: person,
              net: summary.net,
            ),
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DebtPersonScreen(personId: person.id),
        ),
      ),
    );
  }
}
