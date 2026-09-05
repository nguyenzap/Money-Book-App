import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../people/person_edit_screen.dart';
import '../transactions/tx_editor_screen.dart';
import 'settle_debt_sheet.dart';

/// Toàn bộ lịch sử vay mượn với một người, kèm số dư nợ chạy theo thời gian.
class DebtPersonScreen extends ConsumerWidget {
  const DebtPersonScreen({super.key, required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider);
    final txs = ref.watch(personTransactionsProvider(personId));
    final net = ref.watch(personNetDebtProvider(personId));

    final person =
        people.valueOrNull?.where((p) => p.id == personId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(person?.name ?? 'Chi tiết nợ'),
        actions: [
          if (person != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Sửa',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PersonEditScreen(editing: person),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTxEditor(
          context,
          initialKind: TxKind.lend,
          presetPersonId: personId,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ghi thêm'),
      ),
      body: Column(
        children: [
          net.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Lỗi: $e'),
            data: (value) => _NetHeader(
              net: value,
              personName: person?.name ?? '',
              onSettle: person == null || value == 0
                  ? null
                  : () => showSettleDebtSheet(
                        context,
                        person: person,
                        net: value,
                      ),
            ),
          ),
          Expanded(
            child: txs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.handshake_outlined,
                    title: 'Chưa có giao dịch nào',
                    message: 'Ghi lại khi cho mượn, trả dùm hoặc vay tiền.',
                  );
                }
                return _DebtTimeline(views: list);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NetHeader extends StatelessWidget {
  const _NetHeader({
    required this.net,
    required this.personName,
    this.onSettle,
  });

  final int net;
  final String personName;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settled = net == 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                settled
                    ? 'Đã sạch nợ'
                    : net > 0
                        ? '$personName nợ bạn'
                        : 'Bạn nợ $personName',
                style: TextStyle(color: scheme.outline, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                settled ? '0 ₫' : formatVnd(net.abs()),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: settled
                      ? scheme.onSurface
                      : net > 0
                          ? incomeColor(context)
                          : expenseColor(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!settled) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onSettle,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Tất toán'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dòng thời gian các giao dịch nợ, kèm số dư nợ sau mỗi lần.
class _DebtTimeline extends StatelessWidget {
  const _DebtTimeline({required this.views});

  final List<TxView> views;

  @override
  Widget build(BuildContext context) {
    // Danh sách đến theo thứ tự mới nhất trước. Số dư chạy phải cộng dồn từ
    // giao dịch cũ nhất, nên tính ngược từ cuối lên.
    final running = List<int>.filled(views.length, 0);
    var acc = 0;
    for (var i = views.length - 1; i >= 0; i--) {
      acc += views[i].tx.debtDelta;
      running[i] = acc;
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: views.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
      itemBuilder: (context, index) {
        final view = views[index];
        final scheme = Theme.of(context).colorScheme;
        final delta = view.tx.debtDelta;
        final balance = running[index];

        return ListTile(
          leading: IconAvatar(
            icon: view.kind.icon,
            color: delta > 0 ? incomeColor(context) : expenseColor(context),
          ),
          title: Text(
            view.tx.note?.trim().isNotEmpty == true
                ? view.tx.note!.trim()
                : view.kind.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${view.kind.label} · '
            '${formatDate(DateTime.fromMillisecondsSinceEpoch(view.tx.occurredAt))}',
            style: TextStyle(color: scheme.outline, fontSize: 12.5),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatVndSigned(delta),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: amountColor(context, delta),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                balance == 0
                    ? 'sạch nợ'
                    : balance > 0
                        ? 'còn nợ bạn ${formatVndShort(balance)}'
                        : 'bạn còn nợ ${formatVndShort(balance.abs())}',
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
            ],
          ),
          onTap: () => openTxEditor(context, editing: view),
        );
      },
    );
  }
}
