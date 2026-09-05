import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'adjust_balance_sheet.dart';
import 'wallet_detail_screen.dart';
import 'wallet_edit_screen.dart';

class WalletListScreen extends ConsumerWidget {
  const WalletListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(allWalletsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ví của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WalletEditScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ví'),
      ),
      body: wallets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Chưa có ví nào',
              message: 'Thêm ví cho từng nguồn tiền: tiền mặt, MoMo, '
                  'MB Bank, Techcombank...',
            );
          }

          final active = list.where((w) => !w.wallet.isArchived).toList();
          final archived = list.where((w) => w.wallet.isArchived).toList();
          final total = active.fold<int>(0, (sum, w) => sum + w.balance);

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Tổng cộng',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    MoneyText(
                      total,
                      colored: false,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
              for (final item in active) _WalletTile(item: item),
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Đã lưu trữ',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final item in archived) _WalletTile(item: item),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _WalletTile extends ConsumerWidget {
  const _WalletTile({required this.item});

  final WalletWithBalance item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = item.wallet;
    final color = wallet.colorValue == null ? null : Color(wallet.colorValue!);

    return ListTile(
      leading: IconAvatar(
        icon: iconFor(wallet.iconKey, fallback: Icons.wallet),
        color: color,
      ),
      title: Text(
        wallet.name,
        style: TextStyle(
          decoration: wallet.isArchived ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(walletTypeLabel(wallet.type)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoneyText(item.balance, colored: false),
          PopupMenuButton<String>(
            onSelected: (value) => _onMenu(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Sửa'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'adjust',
                child: ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('Điều chỉnh số dư'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: ListTile(
                  leading: Icon(
                    wallet.isArchived ? Icons.unarchive : Icons.archive_outlined,
                  ),
                  title: Text(wallet.isArchived ? 'Bỏ lưu trữ' : 'Lưu trữ'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Xoá'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WalletDetailScreen(walletId: item.id),
        ),
      ),
    );
  }

  Future<void> _onMenu(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final repo = ref.read(repositoryProvider);

    switch (action) {
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WalletEditScreen(editing: item.wallet),
          ),
        );

      case 'adjust':
        await showAdjustBalanceSheet(context, item);

      case 'archive':
        await repo.archiveWallet(item.id, archived: !item.wallet.isArchived);
        if (!context.mounted) return;
        showSnack(
          context,
          item.wallet.isArchived
              ? 'Đã đưa "${item.name}" trở lại'
              : 'Đã lưu trữ "${item.name}"',
        );

      case 'delete':
        // Ví đã có giao dịch mà xoá đi thì lịch sử sẽ thủng một lỗ, nên chỉ
        // cho lưu trữ.
        final count = await repo.countTransactionsOfWallet(item.id);
        if (!context.mounted) return;

        if (count > 0) {
          final archive = await confirmDialog(
            context,
            title: 'Không xoá được ví này',
            message: '"${item.name}" đang có $count giao dịch. Xoá ví sẽ làm '
                'mất lịch sử và sai số liệu thống kê.\n\n'
                'Bạn có muốn lưu trữ thay thế không? Ví sẽ bị ẩn khỏi các ô '
                'chọn nhưng lịch sử vẫn còn nguyên.',
            confirmLabel: 'Lưu trữ',
            destructive: false,
          );
          if (archive && context.mounted) {
            await repo.archiveWallet(item.id, archived: true);
            if (context.mounted) {
              showSnack(context, 'Đã lưu trữ "${item.name}"');
            }
          }
          return;
        }

        final ok = await confirmDialog(
          context,
          title: 'Xoá ví?',
          message: 'Xoá "${item.name}". Ví này chưa có giao dịch nào.',
        );
        if (ok) {
          await repo.deleteWallet(item.id);
          if (context.mounted) showSnack(context, 'Đã xoá ví');
        }
    }
  }
}
