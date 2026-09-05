import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/db/repository.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

/// Tất toán khoản nợ với một người.
///
/// Ghi một giao dịch ngược chiều đúng bằng số dư nợ hiện tại, hoặc xoá nợ nếu
/// hai bên thống nhất bỏ qua.
Future<void> showSettleDebtSheet(
  BuildContext context, {
  required Person person,
  required int net,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SettleDebtSheet(person: person, net: net),
    ),
  );
}

class _SettleDebtSheet extends ConsumerStatefulWidget {
  const _SettleDebtSheet({required this.person, required this.net});

  final Person person;
  final int net;

  @override
  ConsumerState<_SettleDebtSheet> createState() => _SettleDebtSheetState();
}

class _SettleDebtSheetState extends ConsumerState<_SettleDebtSheet> {
  late final TextEditingController _controller;
  late int _amount;
  int? _walletId;
  bool _writeoff = false;

  /// Họ trả tiền cho mình thì mình thu nợ; ngược lại thì mình trả nợ.
  bool get _theyOweMe => widget.net > 0;
  TxKind get _kind => _theyOweMe ? TxKind.collect : TxKind.repay;

  @override
  void initState() {
    super.initState();
    _amount = widget.net.abs();
    _controller = TextEditingController(text: groupDigits(_amount));
  }

  /// Chọn sẵn một ví để người dùng chỉ còn bấm xác nhận.
  ///
  /// Khi trả nợ thì lấy ví nhiều tiền nhất — khả năng cao là ví sẽ dùng, và
  /// chắc chắn đủ số dư. Khi thu nợ thì lấy ví đầu danh sách.
  void _pickDefaultWallet(List<WalletWithBalance> wallets) {
    if (_walletId != null || wallets.isEmpty) return;
    if (_theyOweMe) {
      _walletId = wallets.first.id;
    } else {
      final richest = wallets.reduce(
        (a, b) => b.balance > a.balance ? b : a,
      );
      _walletId = richest.id;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _settle() async {
    if (_amount <= 0) {
      showSnack(context, 'Nhập số tiền lớn hơn 0');
      return;
    }
    if (!_writeoff && _walletId == null) {
      showSnack(context, 'Hãy chọn ví');
      return;
    }

    final repo = ref.read(repositoryProvider);
    await repo.addTransaction(
      kind: _kind,
      amount: _amount,
      occurredAt: DateTime.now(),
      // Xoá nợ thì không có tiền nào chạy đi đâu, nên không gắn ví nào cả.
      walletFromId: _writeoff ? null : (_kind.needsWalletFrom ? _walletId : null),
      walletToId: _writeoff ? null : (_kind.needsWalletTo ? _walletId : null),
      personId: widget.person.id,
      isWriteoff: _writeoff,
      note: _writeoff ? 'Xoá nợ' : 'Tất toán',
    );

    if (!mounted) return;
    Navigator.pop(context);
    showSnack(
      context,
      _writeoff
          ? 'Đã xoá nợ với ${widget.person.name}'
          : 'Đã tất toán ${formatVnd(_amount)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wallets = ref.watch(walletsProvider);
    final isPartial = _amount != widget.net.abs();

    return SafeArea(
      child: SingleChildScrollView(
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
            Text('Tất toán', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              _theyOweMe
                  ? '${widget.person.name} đang nợ bạn '
                      '${formatVnd(widget.net.abs())}'
                  : 'Bạn đang nợ ${widget.person.name} '
                      '${formatVnd(widget.net.abs())}',
              style: TextStyle(color: scheme.outline),
            ),
            const SizedBox(height: 20),
            AmountField(
              controller: _controller,
              label: _theyOweMe ? 'Số tiền nhận lại' : 'Số tiền trả',
              showQuickAdd: false,
              onChanged: (v) => setState(() => _amount = v),
            ),
            if (isPartial && _amount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Trả một phần. Còn lại '
                '${formatVnd((widget.net.abs() - _amount).abs())}.',
                style: TextStyle(fontSize: 12.5, color: scheme.outline),
              ),
            ],
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _writeoff,
              onChanged: (v) => setState(() => _writeoff = v),
              title: const Text('Xoá nợ, không có tiền'),
              subtitle: const Text(
                'Hai bên bỏ qua khoản này. Công nợ về 0 nhưng ví không đổi.',
              ),
            ),
            if (!_writeoff) ...[
              const SizedBox(height: 8),
              wallets.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Lỗi: $e'),
                data: (list) {
                  _pickDefaultWallet(list);
                  return DropdownButtonFormField<int>(
                  initialValue: _walletId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _theyOweMe ? 'Nhận vào ví' : 'Trả từ ví',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: [
                    for (final w in list)
                      DropdownMenuItem(
                        value: w.id,
                        child: Row(
                          children: [
                            Icon(
                              iconFor(w.wallet.iconKey, fallback: Icons.wallet),
                              size: 18,
                              color: w.wallet.colorValue == null
                                  ? null
                                  : Color(w.wallet.colorValue!),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                w.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formatVndShort(w.balance),
                              style: TextStyle(
                                color: scheme.outline,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                    onChanged: (v) => setState(() => _walletId = v),
                  );
                },
              ),
            ],
            const SizedBox(height: 14),
            // Nói trước app sắp ghi gì, để không ai phải đoán.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_kind.icon, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _writeoff
                          ? 'Ghi "${_kind.label}" ${formatVnd(_amount)} với '
                              '${widget.person.name}, không đụng tới ví nào.'
                          : _theyOweMe
                              ? 'Ghi "${_kind.label}" ${formatVnd(_amount)}, '
                                  'cộng vào ví bạn chọn.'
                              : 'Ghi "${_kind.label}" ${formatVnd(_amount)}, '
                                  'trừ vào ví bạn chọn.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _settle,
              icon: const Icon(Icons.check),
              label: Text(_writeoff ? 'Xoá nợ' : 'Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }
}
