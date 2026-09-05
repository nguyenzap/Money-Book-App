import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../debts/debt_person_screen.dart';
import 'person_edit_screen.dart';

/// Danh bạ. Thêm một người một lần, những lần ghi nợ sau chỉ việc chọn tên.
class PersonListScreen extends ConsumerWidget {
  const PersonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dùng sổ nợ thay vì danh sách người thuần, để mỗi dòng hiện luôn dư nợ.
    final debts = ref.watch(
      _peopleWithDebtProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Danh bạ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PersonEditScreen()),
        ),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Thêm người'),
      ),
      body: debts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'Danh bạ đang trống',
              message: 'Thêm những người bạn hay vay mượn hoặc đi ăn chung. '
                  'Thêm một lần, sau đó chỉ cần chọn tên.',
              action: FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PersonEditScreen()),
                ),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Thêm người'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
            itemBuilder: (context, index) => _PersonTile(summary: list[index]),
          );
        },
      ),
    );
  }
}

/// Mọi người trong danh bạ, kể cả người đã sạch nợ.
final _peopleWithDebtProvider = StreamProvider<List<DebtSummary>>((ref) {
  return ref.watch(repositoryProvider).watchDebts(includeSettled: true);
});

class _PersonTile extends ConsumerWidget {
  const _PersonTile({required this.summary});

  final DebtSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = summary.person;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: InitialAvatar(
        name: person.name,
        color: person.avatarColor == null ? null : Color(person.avatarColor!),
      ),
      title: Text(person.name),
      subtitle: Text(
        summary.net == 0
            ? 'Không nợ nần gì'
            : summary.theyOweMe
                ? 'Nợ bạn ${formatVnd(summary.absAmount)}'
                : 'Bạn nợ ${formatVnd(summary.absAmount)}',
        style: TextStyle(
          color: summary.net == 0
              ? scheme.outline
              : summary.theyOweMe
                  ? incomeColor(context)
                  : expenseColor(context),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xoá',
            onPressed: () => _confirmDelete(context, ref),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final person = summary.person;

    // Xoá người còn dư nợ thì khoản nợ đó biến mất luôn — phải chặn lại.
    if (summary.net != 0) {
      await confirmDialog(
        context,
        title: 'Chưa xoá được',
        message: summary.theyOweMe
            ? '${person.name} còn nợ bạn ${formatVnd(summary.absAmount)}.\n\n'
                'Hãy tất toán khoản nợ này trước khi xoá.'
            : 'Bạn còn nợ ${person.name} ${formatVnd(summary.absAmount)}.\n\n'
                'Hãy tất toán khoản nợ này trước khi xoá.',
        confirmLabel: 'Đã hiểu',
        cancelLabel: 'Đóng',
        destructive: false,
      );
      return;
    }

    final count = await repo.countTransactionsOfPerson(person.id);
    if (!context.mounted) return;

    if (count > 0) {
      await confirmDialog(
        context,
        title: 'Chưa xoá được',
        message: '${person.name} đã sạch nợ nhưng vẫn còn $count giao dịch '
            'trong lịch sử. Xoá đi sẽ làm hỏng các giao dịch đó.\n\n'
            'Bạn có thể để nguyên — người đã sạch nợ không hiện trong sổ nợ.',
        confirmLabel: 'Đã hiểu',
        cancelLabel: 'Đóng',
        destructive: false,
      );
      return;
    }

    final ok = await confirmDialog(
      context,
      title: 'Xoá khỏi danh bạ?',
      message: 'Xoá "${person.name}".',
    );
    if (!ok) return;

    await repo.deletePerson(person.id);
    if (context.mounted) showSnack(context, 'Đã xoá "${person.name}"');
  }
}
