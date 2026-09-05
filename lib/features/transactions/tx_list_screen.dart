import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'tx_editor_screen.dart';
import 'tx_tile.dart';

/// Danh sách toàn bộ giao dịch, gom theo ngày.
class TxListScreen extends ConsumerWidget {
  const TxListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Giao dịch')),
      body: txs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Chưa có giao dịch nào',
              message: 'Bấm nút + để ghi khoản đầu tiên.',
              action: FilledButton.icon(
                onPressed: () => openTxEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Ghi giao dịch'),
              ),
            );
          }
          return GroupedTxList(views: list);
        },
      ),
    );
  }
}

/// Danh sách giao dịch có tiêu đề ngày xen giữa.
///
/// Dùng lại ở màn chi tiết ví và chi tiết công nợ với một người.
class GroupedTxList extends StatelessWidget {
  const GroupedTxList({
    super.key,
    required this.views,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<TxView> views;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    // Danh sách đã sắp xếp theo thời gian giảm dần từ truy vấn, nên chỉ cần
    // duyệt một lượt là gom được theo ngày.
    final items = <_ListItem>[];
    int? currentDay;
    var bucket = <TxView>[];

    void flush() {
      if (bucket.isEmpty) return;
      items.add(_HeaderItem(currentDay!, List.of(bucket)));
      items.addAll(bucket.map(_TxItem.new));
      bucket = [];
    }

    for (final view in views) {
      if (view.tx.dayKey != currentDay) {
        flush();
        currentDay = view.tx.dayKey;
      }
      bucket.add(view);
    }
    flush();

    return ListView.builder(
      padding: padding ?? const EdgeInsets.only(bottom: 120),
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is _HeaderItem) {
          return DayHeader(dayKey: item.dayKey, views: item.views);
        }
        final view = (item as _TxItem).view;
        return TxTile(
          view: view,
          onTap: () => openTxEditor(context, editing: view),
        );
      },
    );
  }
}

sealed class _ListItem {
  const _ListItem();
}

class _HeaderItem extends _ListItem {
  const _HeaderItem(this.dayKey, this.views);
  final int dayKey;
  final List<TxView> views;
}

class _TxItem extends _ListItem {
  const _TxItem(this.view);
  final TxView view;
}
