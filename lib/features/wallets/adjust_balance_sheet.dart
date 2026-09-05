import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Sửa số dư ví cho khớp với số tiền thật đang có.
///
/// Không ghi đè số dư mà tạo một giao dịch chênh lệch, để lịch sử vẫn giải
/// thích được vì sao con số nhảy.
Future<void> showAdjustBalanceSheet(
  BuildContext context,
  WalletWithBalance wallet,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _AdjustBalanceSheet(wallet: wallet),
    ),
  );
}

class _AdjustBalanceSheet extends ConsumerStatefulWidget {
  const _AdjustBalanceSheet({required this.wallet});

  final WalletWithBalance wallet;

  @override
  ConsumerState<_AdjustBalanceSheet> createState() =>
      _AdjustBalanceSheetState();
}

class _AdjustBalanceSheetState extends ConsumerState<_AdjustBalanceSheet> {
  late final TextEditingController _controller;
  late int _newBalance;

  @override
  void initState() {
    super.initState();
    _newBalance = widget.wallet.balance;
    _controller = TextEditingController(text: groupDigits(_newBalance));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _delta => _newBalance - widget.wallet.balance;

  Future<void> _apply() async {
    final repo = ref.read(repositoryProvider);
    await repo.adjustWalletBalance(
      walletId: widget.wallet.id,
      newBalance: _newBalance,
    );
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(
      context,
      _delta == 0
          ? 'Số dư không đổi'
          : 'Đã điều chỉnh ${formatVndSigned(_delta)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Điều chỉnh số dư',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              widget.wallet.name,
              style: TextStyle(color: scheme.outline),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Đang ghi nhận', style: TextStyle(color: scheme.outline)),
                const Spacer(),
                MoneyText(widget.wallet.balance, colored: false),
              ],
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _controller,
              label: 'Số dư thực tế',
              autofocus: true,
              showQuickAdd: false,
              onChanged: (v) => setState(() => _newBalance = v),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text('Chênh lệch', style: TextStyle(color: scheme.outline)),
                  const Spacer(),
                  if (_delta == 0)
                    Text(
                      'Không đổi',
                      style: TextStyle(
                        color: scheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    MoneyText(
                      _delta,
                      signed: true,
                      style: const TextStyle(fontSize: 17),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _delta == 0
                  ? 'Không có gì để ghi lại.'
                  : 'Một giao dịch "Điều chỉnh số dư" sẽ được ghi vào lịch sử '
                      'để sổ sách không bị lệch.',
              style: TextStyle(fontSize: 12.5, color: scheme.outline),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _delta == 0 ? null : _apply,
              icon: const Icon(Icons.check),
              label: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }
}
