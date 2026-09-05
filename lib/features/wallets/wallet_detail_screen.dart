import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../transactions/tx_editor_screen.dart';
import '../transactions/tx_list_screen.dart';
import 'adjust_balance_sheet.dart';
import 'wallet_edit_screen.dart';

/// Số dư hiện tại và toàn bộ lịch sử của một ví.
class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({super.key, required this.walletId});

  final int walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(allWalletsProvider);
    final txs = ref.watch(walletTransactionsProvider(walletId));

    return wallets.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
      data: (list) {
        final item = list.where((w) => w.id == walletId).firstOrNull;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.error_outline,
              title: 'Ví không còn tồn tại',
            ),
          );
        }

        final wallet = item.wallet;
        final color =
            wallet.colorValue == null ? null : Color(wallet.colorValue!);

        return Scaffold(
          appBar: AppBar(
            title: Text(wallet.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Sửa ví',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WalletEditScreen(editing: wallet),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => openTxEditor(context, presetWalletId: walletId),
            icon: const Icon(Icons.add),
            label: const Text('Ghi giao dịch'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        IconAvatar(
                          icon: iconFor(wallet.iconKey, fallback: Icons.wallet),
                          color: color,
                          size: 56,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Số dư hiện tại',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatVnd(item.balance),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () =>
                              showAdjustBalanceSheet(context, item),
                          icon: const Icon(Icons.tune),
                          label: const Text('Điều chỉnh số dư'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: txs.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Lỗi: $e')),
                  data: (views) {
                    if (views.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Ví này chưa có giao dịch',
                      );
                    }
                    return GroupedTxList(views: views);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
