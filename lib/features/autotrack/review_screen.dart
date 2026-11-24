import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/autotrack_repository.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/dates.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../transactions/tx_editor_screen.dart';
import 'autotrack_providers.dart';
import 'categorize_actions.dart';

/// Hàng chờ phân loại của giao dịch tự ghi.
///
/// "Chưa phân loại" gom theo người nhận: chọn danh mục một lần cho cả nhóm,
/// app nhớ và lần sau tự phân loại. "Cần xem lại" là những khoản app đã đoán
/// (tên gần giống, từ khoá), chỉ cần bấm ✓ nếu đúng.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(reviewItemsProvider);
    final list = items.value ?? const <ReviewItem>[];
    final uncategorized = list.where((i) => i.isUncategorized).toList();
    final guessed = list.where((i) => !i.isUncategorized).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phân loại giao dịch'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Chưa phân loại (${uncategorized.length})'),
              Tab(text: 'Cần xem lại (${guessed.length})'),
            ],
          ),
        ),
        body: items.isLoading && !items.hasValue
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _UncategorizedTab(items: uncategorized),
                  _GuessedTab(items: guessed),
                ],
              ),
      ),
    );
  }
}

/// Một người nhận và các giao dịch của họ trong hàng chờ.
class _Group {
  _Group(this.items);
  final List<ReviewItem> items;

  ReviewItem get latest => items.first;
  bool get canLearn => latest.receiverKey.isNotEmpty;
  String get title {
    final note = latest.note?.trim();
    if (note != null && note.isNotEmpty) return note;
    return 'Không có nội dung';
  }

  int get signedTotal => items.fold(
    0,
    (sum, i) => sum + (i.kind == TxKind.income ? i.amount : -i.amount),
  );
}

List<_Group> _groupByReceiver(List<ReviewItem> items) {
  final groups = <String, List<ReviewItem>>{};
  for (final i in items) {
    // Không có người nhận thì không gom được: mỗi giao dịch một nhóm.
    final key = i.receiverKey.isEmpty
        ? 'tx:${i.transactionId}'
        : '${i.flow}|${i.receiverKey}';
    (groups[key] ??= []).add(i);
  }
  return [for (final g in groups.values) _Group(g)];
}

class _UncategorizedTab extends ConsumerWidget {
  const _UncategorizedTab({required this.items});
  final List<ReviewItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt,
        title: 'Không còn gì chưa phân loại',
        message:
            'Giao dịch tự ghi từ người nhận mới sẽ hiện ở đây. Phân loại một '
            'lần, những lần sau app tự làm.',
      );
    }
    final groups = _groupByReceiver(items);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _GroupTile(group: groups[i]),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile({required this.group});
  final _Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final n = group.items.length;
    final latest = group.latest;

    final subtitle = [
      if (n > 1) '$n giao dịch' else formatDateTime(latest.occurredAt),
      if (latest.walletName != null) latest.walletName!,
      if (!group.canLearn) 'không nhớ được',
    ].join(' · ');

    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: scheme.outline, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        MoneyText(group.signedTotal, signed: true),
      ],
    );

    final action = Align(
      alignment: Alignment.centerRight,
      child: FilledButton.tonalIcon(
        icon: const Icon(Icons.label_outline, size: 18),
        label: Text(n > 1 ? 'Phân loại cả $n' : 'Phân loại'),
        onPressed: () async {
          final id = await pickCategory(
            context,
            flow: latest.flow,
            title: group.canLearn
                ? 'Danh mục cho "${group.title}"\nLần sau app tự phân loại'
                : 'Danh mục cho giao dịch này',
          );
          if (id == null || !context.mounted) return;
          await categorizeAndLearn(
            context,
            ref,
            transactionId: latest.transactionId,
            categoryId: id,
          );
        },
      ),
    );

    if (n == 1) {
      return InkWell(
        onTap: () => _openEditor(context, ref, latest.transactionId),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(children: [header, action]),
        ),
      );
    }

    return ExpansionTile(
      tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 0),
      title: header,
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: action,
      ),
      children: [
        for (final item in group.items)
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.fromLTRB(32, 0, 16, 0),
            title: Text(formatDateTime(item.occurredAt)),
            subtitle: item.note == group.title ? null : Text(item.note ?? ''),
            trailing: MoneyText(
              item.kind == TxKind.income ? item.amount : -item.amount,
              signed: true,
            ),
            onTap: () => _openEditor(context, ref, item.transactionId),
          ),
      ],
    );
  }
}

class _GuessedTab extends ConsumerWidget {
  const _GuessedTab({required this.items});
  final List<ReviewItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt,
        title: 'Không có gì cần xem lại',
        message:
            'Khi app đoán danh mục theo tên gần giống hoặc từ khoá, khoản đó '
            'hiện ở đây để bạn xác nhận.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) => _GuessTile(item: items[i]),
    );
  }
}

class _GuessTile extends ConsumerWidget {
  const _GuessTile({required this.item});
  final ReviewItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => _openEditor(context, ref, item.transactionId),
      title: Text(
        item.note ?? 'Không có nội dung',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.edit_outlined, size: 16),
              label: Text(item.categoryName ?? '?'),
              onPressed: () async {
                final id = await pickCategory(
                  context,
                  flow: item.flow,
                  selected: item.categoryId,
                  title: 'Danh mục cho "${item.note ?? ''}"',
                );
                if (id == null || !context.mounted) return;
                await categorizeAndLearn(
                  context,
                  ref,
                  transactionId: item.transactionId,
                  categoryId: id,
                );
              },
            ),
            Text(
              [
                if (item.reason != null) item.reason!,
                formatDateTime(item.occurredAt),
              ].join(' · '),
              style: TextStyle(color: scheme.outline, fontSize: 12),
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(
            item.kind == TxKind.income ? item.amount : -item.amount,
            signed: true,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Đúng rồi',
            icon: Icon(Icons.check_circle_outline, color: scheme.primary),
            onPressed: () => categorizeAndLearn(
              context,
              ref,
              transactionId: item.transactionId,
              categoryId: item.categoryId!,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openEditor(BuildContext context, WidgetRef ref, int txId) async {
  final view = await ref
      .read(repositoryProvider)
      .watchTransactionById(txId)
      .first;
  if (view == null || !context.mounted) return;
  await openTxEditor(context, editing: view);
}

/// Thẻ trên màn Tổng quan: còn bao nhiêu giao dịch tự ghi chờ phân loại.
/// Không còn gì thì ẩn hẳn.
class ReviewQueueCard extends ConsumerWidget {
  const ReviewQueueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(reviewItemsProvider).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final uncategorized = items.where((i) => i.isUncategorized).length;
    final guessed = items.length - uncategorized;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: scheme.secondaryContainer,
        child: ListTile(
          leading: Icon(
            Icons.label_important_outline,
            color: scheme.onSecondaryContainer,
          ),
          title: Text(
            uncategorized > 0
                ? '$uncategorized giao dịch chưa phân loại'
                : '$guessed giao dịch cần xem lại',
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: uncategorized > 0 && guessed > 0
              ? Text(
                  '$guessed khoản app đã đoán, cần xác nhận',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: scheme.onSecondaryContainer,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReviewScreen()),
          ),
        ),
      ),
    );
  }
}
