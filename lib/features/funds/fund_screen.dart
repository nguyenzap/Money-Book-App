import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/db/repository.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Quỹ: tiền đã dành sẵn cho những khoản biết trước.
///
/// Màn hình trả lời ba câu: mình có quỹ gì, mỗi quỹ được bao nhiêu, và tiền
/// đang nằm ở ví nào.
class FundScreen extends ConsumerWidget {
  const FundScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funds = ref.watch(fundsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quỹ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showFundEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Lập quỹ'),
      ),
      body: funds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              title: 'Chưa có quỹ nào',
              message: 'Quỹ là tiền để dành cho khoản đã biết trước: tiền nhà '
                  'tháng sau, tiền điện, trả nợ ví trả sau. Tiền quỹ không '
                  'tính vào phần tiêu hằng ngày.',
              action: FilledButton.icon(
                onPressed: () => showFundEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Lập quỹ'),
              ),
            );
          }

          final total = list.fold<int>(0, (sum, f) => sum + f.saved);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _TotalCard(total: total, count: list.length),
              const SizedBox(height: 20),
              for (final f in list) ...[
                _FundCard(progress: f),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              Text(
                'Tiền quỹ vẫn nằm trong ví của bạn, chỉ là đã có chỗ đến nên '
                'không được tính vào phần tiêu được. Bấm vào thẻ tổng tài sản '
                'ở màn Tổng quan để xem cả hai con số.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.count});

  final int total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              'Đang để dành',
              style: TextStyle(color: scheme.outline, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              formatVnd(total),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count == 1 ? 'Trong 1 quỹ' : 'Trong $count quỹ',
              style: TextStyle(color: scheme.outline, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundCard extends ConsumerWidget {
  const _FundCard({required this.progress});

  final FundProgress progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final fund = progress.fund;
    final color = fund.colorValue == null ? null : Color(fund.colorValue!);
    final due = fund.dueDayKey;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showFundEditor(context, editing: progress),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconAvatar(
                    icon: iconFor(fund.iconKey, fallback: Icons.savings),
                    color: color,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fund.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Icon(
                              iconFor(
                                progress.walletIconKey,
                                fallback: Icons.wallet,
                              ),
                              size: 13,
                              color: scheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                progress.walletName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.outline,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (progress.isComplete)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: incomeColor(context),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (progress.hasTarget) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.ratio,
                    minHeight: 8,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.8),
                    valueColor: AlwaysStoppedAnimation(
                      progress.isComplete
                          ? incomeColor(context)
                          : (color ?? scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Text(
                    formatVnd(progress.saved),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (progress.hasTarget)
                    Text(
                      ' / ${formatVnd(progress.target!)}',
                      style: TextStyle(fontSize: 13, color: scheme.outline),
                    ),
                  const Spacer(),
                  if (progress.isComplete)
                    Text(
                      'Đủ rồi',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: incomeColor(context),
                      ),
                    )
                  else if (progress.missing != null)
                    Text(
                      'Còn thiếu ${formatVndShort(progress.missing!)}',
                      style: TextStyle(fontSize: 12.5, color: scheme.outline),
                    ),
                ],
              ),
              if (due != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: scheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cần dùng ${formatDate(dayKeyToDate(due))}',
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          showFundTransferSheet(context, progress: progress),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nạp thêm'),
                    ),
                  ),
                  if (progress.saved > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showFundTransferSheet(
                          context,
                          progress: progress,
                          withdraw: true,
                        ),
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Rút ra'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----- Nạp / rút quỹ -------------------------------------------------------

/// Nạp tiền vào quỹ hoặc rút ngược lại.
///
/// Cả hai đều là chuyển ví thật: nạp thì tiền đi từ ví chi tiêu sang ví giữ
/// quỹ, rút thì ngược lại.
Future<void> showFundTransferSheet(
  BuildContext context, {
  required FundProgress progress,
  bool withdraw = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _FundTransferSheet(progress: progress, withdraw: withdraw),
    ),
  );
}

class _FundTransferSheet extends ConsumerStatefulWidget {
  const _FundTransferSheet({required this.progress, required this.withdraw});

  final FundProgress progress;
  final bool withdraw;

  @override
  ConsumerState<_FundTransferSheet> createState() => _FundTransferSheetState();
}

class _FundTransferSheetState extends ConsumerState<_FundTransferSheet> {
  late final TextEditingController _controller;
  int _amount = 0;
  int? _otherWalletId;

  @override
  void initState() {
    super.initState();
    // Nạp thì gợi ý sẵn phần còn thiếu, đỡ phải tính.
    final suggested =
        widget.withdraw ? widget.progress.saved : widget.progress.missing;
    _amount = suggested ?? 0;
    _controller = TextEditingController(
      text: _amount > 0 ? groupDigits(_amount) : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Chọn sẵn một ví chi tiêu để chỉ còn bấm xác nhận.
  ///
  /// Ưu tiên ví khác ví giữ quỹ như trước; chỉ có mỗi ví giữ quỹ thì chọn
  /// luôn nó — nạp / rút tại chỗ là trường hợp hợp lệ.
  void _pickDefaultWallet(List<WalletWithBalance> wallets) {
    if (_otherWalletId != null) return;
    final fundWallet = widget.progress.fund.walletId;
    final candidates = wallets.where((w) => w.id != fundWallet).toList();
    if (candidates.isEmpty) {
      if (wallets.any((w) => w.id == fundWallet)) _otherWalletId = fundWallet;
      return;
    }
    // Nạp thì lấy ví nhiều tiền nhất cho chắc đủ; rút thì trả về ví đầu.
    _otherWalletId = widget.withdraw
        ? candidates.first.id
        : candidates.reduce((a, b) => b.balance > a.balance ? b : a).id;
  }

  Future<void> _submit() async {
    if (_amount <= 0) {
      showSnack(context, 'Nhập số tiền lớn hơn 0');
      return;
    }
    if (_otherWalletId == null) {
      showSnack(context, 'Hãy chọn ví');
      return;
    }
    if (widget.withdraw && _amount > widget.progress.saved) {
      showSnack(context, 'Quỹ chỉ còn ${formatVnd(widget.progress.saved)}');
      return;
    }

    final repo = ref.read(repositoryProvider);
    final fundWallet = widget.progress.fund.walletId;

    if (widget.withdraw) {
      await repo.withdrawFromFund(
        fundId: widget.progress.id,
        walletFromId: fundWallet,
        walletToId: _otherWalletId!,
        amount: _amount,
        occurredAt: DateTime.now(),
        note: 'Rút khỏi quỹ ${widget.progress.name}',
      );
    } else {
      await repo.depositToFund(
        fundId: widget.progress.id,
        walletFromId: _otherWalletId!,
        walletToId: fundWallet,
        amount: _amount,
        occurredAt: DateTime.now(),
        note: 'Nạp quỹ ${widget.progress.name}',
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    showSnack(
      context,
      widget.withdraw
          ? 'Đã rút ${formatVnd(_amount)} khỏi quỹ'
          : 'Đã nạp ${formatVnd(_amount)} vào quỹ',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wallets = ref.watch(walletsProvider);
    final fundWalletName = widget.progress.walletName;

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
            Text(
              widget.withdraw ? 'Rút khỏi quỹ' : 'Nạp vào quỹ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.progress.name} · đang có '
              '${formatVnd(widget.progress.saved)}',
              style: TextStyle(color: scheme.outline),
            ),
            const SizedBox(height: 20),
            AmountField(
              controller: _controller,
              label: 'Số tiền',
              autofocus: true,
              onChanged: (v) => setState(() => _amount = v),
            ),
            const SizedBox(height: 20),
            wallets.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi: $e'),
              data: (list) {
                _pickDefaultWallet(list);
                // Có cả ví giữ quỹ: tiền đã nằm sẵn ở đó thì nạp tại chỗ, quỹ
                // đủ rồi thì rút tại chỗ để tiêu.
                final items = list;

                return DropdownButtonFormField<int>(
                  initialValue: _otherWalletId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: widget.withdraw ? 'Trả về ví' : 'Lấy từ ví',
                    prefixIcon:
                        const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  items: [
                    for (final w in items)
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
                                w.id == widget.progress.fund.walletId
                                    ? '${w.name} (ví giữ quỹ)'
                                    : w.name,
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
                  onChanged: (v) => setState(() => _otherWalletId = v),
                );
              },
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _otherWalletId == widget.progress.fund.walletId
                    // Cùng một ví: không có tiền nào di chuyển, chỉ đổi nhãn.
                    ? (widget.withdraw
                        ? '${formatVnd(_amount)} vẫn nằm ở $fundWalletName, '
                            'chỉ bỏ nhãn quỹ. Số này quay lại phần tiêu được.'
                        : '${formatVnd(_amount)} đang có sẵn ở $fundWalletName '
                            'được dành cho quỹ. Số dư ví không đổi, nhưng số '
                            'này không còn tính vào tiền tiêu được.')
                    : widget.withdraw
                        ? 'Chuyển ${formatVnd(_amount)} từ $fundWalletName về '
                            'ví chi tiêu. Tiền quay lại phần tiêu được.'
                        : 'Chuyển ${formatVnd(_amount)} sang $fundWalletName. '
                            'Số này sẽ không còn tính vào tiền tiêu được.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(widget.withdraw ? 'Rút ra' : 'Nạp vào'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Lập / sửa quỹ -------------------------------------------------------

Future<void> showFundEditor(
  BuildContext context, {
  FundProgress? editing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _FundEditor(editing: editing),
    ),
  );
}

class _FundEditor extends ConsumerStatefulWidget {
  const _FundEditor({this.editing});

  final FundProgress? editing;

  @override
  ConsumerState<_FundEditor> createState() => _FundEditorState();
}

class _FundEditorState extends ConsumerState<_FundEditor> {
  final _nameController = TextEditingController();
  late final TextEditingController _targetController;

  int? _walletId;
  int? _colorValue;
  String? _iconKey;
  DateTime? _due;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing?.fund;
    _targetController = TextEditingController(
      text: editing?.targetAmount == null
          ? ''
          : groupDigits(editing!.targetAmount!),
    );
    if (editing != null) {
      _nameController.text = editing.name;
      _walletId = editing.walletId;
      _colorValue = editing.colorValue;
      _iconKey = editing.iconKey;
      _due = editing.dueDayKey == null
          ? null
          : dayKeyToDate(editing.dueDayKey!);
    } else {
      _colorValue = kPickerColors.first;
      _iconKey = 'savings';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Khi nào cần dùng tới',
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Đặt tên cho quỹ');
      return;
    }
    if (_walletId == null) {
      showSnack(context, 'Chọn ví sẽ giữ tiền quỹ');
      return;
    }

    final repo = ref.read(repositoryProvider);
    final target = parseVnd(_targetController.text);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_isEditing) {
      await repo.updateFund(
        widget.editing!.fund.copyWith(
          name: name,
          walletId: _walletId!,
          targetAmount: Value(target > 0 ? target : null),
          dueDayKey: Value(_due == null ? null : dayKeyOf(_due!)),
          colorValue: Value(_colorValue),
          iconKey: Value(_iconKey),
          updatedAt: now,
        ),
      );
    } else {
      await repo.insertFund(
        FundsCompanion.insert(
          name: name,
          walletId: _walletId!,
          targetAmount: Value(target > 0 ? target : null),
          dueDayKey: Value(_due == null ? null : dayKeyOf(_due!)),
          colorValue: Value(_colorValue),
          iconKey: Value(_iconKey),
          sortOrder: Value(await repo.nextFundSortOrder()),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, _isEditing ? 'Đã lưu' : 'Đã lập quỹ');
  }

  Future<void> _delete() async {
    final progress = widget.editing!;
    final repo = ref.read(repositoryProvider);

    if (progress.saved > 0) {
      final ok = await confirmDialog(
        context,
        title: 'Quỹ vẫn còn tiền',
        message: '${progress.name} đang giữ ${formatVnd(progress.saved)}.\n\n'
            'Xoá quỹ không làm mất tiền — số này sẽ quay lại phần tiêu được. '
            'Các giao dịch cũ vẫn còn nguyên, chỉ mất nhãn quỹ.',
        confirmLabel: 'Xoá quỹ',
      );
      if (!ok || !mounted) return;
    } else {
      final ok = await confirmDialog(
        context,
        title: 'Xoá quỹ?',
        message: 'Xoá "${progress.name}".',
      );
      if (!ok || !mounted) return;
    }

    await repo.deleteFund(progress.id);
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Đã xoá quỹ');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wallets = ref.watch(walletsProvider);
    final color = _colorValue == null ? null : Color(_colorValue!);

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? 'Sửa quỹ' : 'Lập quỹ mới',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Xoá quỹ',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tên quỹ',
                hintText: 'Tiền KTX, tiền điện, trả SPayLater...',
                prefixIcon: Icon(Icons.savings_outlined),
              ),
            ),
            const SizedBox(height: 16),
            wallets.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Lỗi: $e'),
              data: (list) => DropdownButtonFormField<int>(
                initialValue: _walletId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ví giữ tiền quỹ',
                  helperText: 'Thường là ngân hàng ít dùng, để khỏi tiêu nhầm',
                  helperMaxLines: 2,
                  prefixIcon: Icon(Icons.account_balance_outlined),
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
                            child:
                                Text(w.name, overflow: TextOverflow.ellipsis),
                          ),
                          Text(
                            formatVndShort(w.balance),
                            style:
                                TextStyle(color: scheme.outline, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _walletId = v),
              ),
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _targetController,
              label: 'Cần bao nhiêu',
              showQuickAdd: false,
            ),
            const SizedBox(height: 6),
            Text(
              'Để trống nếu chỉ để dành mà chưa có con số cụ thể.',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Khi nào cần dùng'),
              subtitle: Text(
                _due == null ? 'Chưa đặt' : formatDate(_due!),
              ),
              trailing: _due == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Bỏ hạn',
                      onPressed: () => setState(() => _due = null),
                    ),
              onTap: _pickDue,
            ),
            const SizedBox(height: 12),
            Text('Màu', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            ColorPickerRow(
              selected: _colorValue,
              onSelected: (v) => setState(() => _colorValue = v),
            ),
            const SizedBox(height: 16),
            Text('Biểu tượng', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            IconPickerGrid(
              keys: kFundIconKeys,
              selected: _iconKey,
              color: color,
              onSelected: (v) => setState(() => _iconKey = v),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
