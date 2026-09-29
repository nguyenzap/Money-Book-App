import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../categories/category_edit_screen.dart';
import '../people/person_edit_screen.dart';
import 'spend_impact_note.dart';
import 'split_bill_section.dart';

/// Mở màn hình ghi giao dịch. Gom một chỗ để mọi nơi trong app gọi giống nhau.
Future<void> openTxEditor(
  BuildContext context, {
  TxKind initialKind = TxKind.expense,
  TxView? editing,
  int? presetWalletId,
  int? presetPersonId,
  TemplateView? fromTemplate,
}) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (_) => TxEditorScreen(
        initialKind: initialKind,
        editing: editing,
        presetWalletId: presetWalletId,
        presetPersonId: presetPersonId,
        fromTemplate: fromTemplate,
      ),
    ),
  );
}

/// Màn hình thêm / sửa giao dịch, dùng chung cho cả 8 loại.
///
/// Các ô nhập hiện ra theo [TxKind] thông qua `needsCategory`, `needsPerson`,
/// `needsWalletFrom`, `needsWalletTo`, nên thêm một loại giao dịch mới không
/// phải sửa gì ở đây.
class TxEditorScreen extends ConsumerStatefulWidget {
  const TxEditorScreen({
    super.key,
    this.initialKind = TxKind.expense,
    this.editing,
    this.presetWalletId,
    this.presetPersonId,
    this.fromTemplate,
  });

  final TxKind initialKind;
  final TxView? editing;
  final int? presetWalletId;
  final int? presetPersonId;

  /// Mẫu chưa đủ trường để ghi một chạm: điền sẵn phần đã có, người dùng chỉ
  /// việc điền nốt.
  final TemplateView? fromTemplate;

  @override
  ConsumerState<TxEditorScreen> createState() => _TxEditorScreenState();
}

class _TxEditorScreenState extends ConsumerState<TxEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TxKind _kind;
  int? _walletFromId;
  int? _walletToId;
  int? _categoryId;
  int? _personId;
  int? _fundId;
  late DateTime _occurredAt;

  /// Chia tiền một hoá đơn. Chỉ áp dụng khi ghi mới một khoản chi — sửa một
  /// giao dịch đã có thì không đụng tới cả nhóm.
  final _split = SplitState();

  bool get _isEditing => widget.editing != null;

  /// Có được chia tiền ở trạng thái hiện tại không.
  bool get _canSplit => !_isEditing && _kind == TxKind.expense;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _kind = editing.kind;
      _amountController.text = groupDigits(editing.tx.amount);
      _noteController.text = editing.tx.note ?? '';
      _walletFromId = editing.tx.walletFromId;
      _walletToId = editing.tx.walletToId;
      _categoryId = editing.tx.categoryId;
      _personId = editing.tx.personId;
      _fundId = editing.tx.fundId;
      _occurredAt =
          DateTime.fromMillisecondsSinceEpoch(editing.tx.occurredAt);
    } else if (widget.fromTemplate != null) {
      final t = widget.fromTemplate!;
      _kind = TxKind.expense;
      _occurredAt = DateTime.now();
      if (t.hasAmount) _amountController.text = groupDigits(t.amount!);
      _noteController.text = t.template.note ?? '';
      if (t.hasWallet) _walletFromId = t.template.walletId;
      if (t.hasCategory) _categoryId = t.template.categoryId;
    } else {
      _kind = widget.initialKind;
      _occurredAt = DateTime.now();
      _personId = widget.presetPersonId;
      _applyPresetWallet();
    }
  }

  /// Có lưu được các trường đang nhập thành mẫu chi tiêu không.
  bool get _canSaveAsTemplate =>
      !_isEditing && _kind == TxKind.expense && !_split.enabled;

  /// Lưu các trường đang nhập thành một mẫu, để lần sau ghi một chạm. Không
  /// đóng màn hình — người dùng vẫn ghi khoản này như thường.
  Future<void> _saveAsTemplate() async {
    final note = _noteController.text.trim();
    if (note.isEmpty && _categoryId == null) {
      showSnack(context, 'Nhập ghi chú hoặc chọn danh mục để đặt tên cho mẫu');
      return;
    }
    final amount = parseVnd(_amountController.text);
    await ref.read(repositoryProvider).insertTemplate(
          note: note.isEmpty ? null : note,
          amount: amount > 0 ? amount : null,
          walletId: _walletFromId,
          categoryId: _categoryId,
        );
    if (!mounted) return;
    showSnack(
      context,
      amount > 0 && _walletFromId != null && _categoryId != null
          ? 'Đã lưu mẫu. Lần sau bấm ở màn Tổng quan là ghi xong'
          : 'Đã lưu mẫu. Các trường để trống sẽ được hỏi khi dùng',
    );
  }

  void _applyPresetWallet() {
    final preset = widget.presetWalletId;
    if (preset == null) return;
    if (_kind.needsWalletFrom) {
      _walletFromId = preset;
    } else if (_kind.needsWalletTo) {
      _walletToId = preset;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _split.dispose();
    super.dispose();
  }

  /// Đổi loại giao dịch thì phải dọn những trường không còn ý nghĩa, nếu không
  /// sẽ ghi xuống DB một danh mục hoặc một người chẳng liên quan gì.
  void _changeKind(TxKind next) {
    if (next == _kind) return;
    setState(() {
      final previous = _kind;
      _kind = next;

      if (!next.needsCategory) _categoryId = null;
      if (!next.needsPerson) _personId = null;

      // Chia tiền và lấy từ quỹ chỉ có nghĩa với một khoản chi.
      if (next != TxKind.expense) {
        _split.enabled = false;
        _fundId = null;
      }

      if (next == TxKind.transfer) {
        _walletFromId ??= _walletToId;
        _walletToId = null;
      } else {
        // Giữ lại ví người dùng đang chọn khi đổi giữa các loại một chân ví,
        // để đỡ phải chọn lại.
        final currentWallet = previous.needsWalletFrom
            ? _walletFromId
            : (previous.needsWalletTo ? _walletToId : null);
        _walletFromId = null;
        _walletToId = null;
        if (next.needsWalletFrom) {
          _walletFromId = currentWallet;
        } else if (next.needsWalletTo) {
          _walletToId = currentWallet;
        }
      }
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Chọn ngày giao dịch',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
      helpText: 'Chọn giờ',
    );
    if (!mounted) return;

    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _occurredAt.hour,
        time?.minute ?? _occurredAt.minute,
      );
    });
  }

  String? _validateSelection() {
    if (_kind.needsCategory && _categoryId == null) {
      return 'Hãy chọn danh mục';
    }
    if (_kind.needsPerson && _personId == null) {
      return 'Hãy chọn người';
    }
    if (_kind == TxKind.transfer) {
      if (_walletFromId == null) return 'Hãy chọn ví nguồn';
      if (_walletToId == null) return 'Hãy chọn ví nhận';
      // Nạp / rút quỹ ngay trong ví giữ quỹ thì hai chân trùng nhau là đúng.
      if (_walletFromId == _walletToId && _fundId == null) {
        return 'Ví nguồn và ví nhận phải khác nhau';
      }
      return null;
    }
    if (_kind.needsWalletFrom && _walletFromId == null) {
      return 'Hãy chọn ví';
    }
    if (_kind.needsWalletTo && _walletToId == null) {
      return 'Hãy chọn ví';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = _validateSelection();
    if (error != null) {
      showSnack(context, error);
      return;
    }

    final amount = parseVnd(_amountController.text);
    final note = _noteController.text.trim();
    final repo = ref.read(repositoryProvider);

    if (_canSplit && _split.enabled) {
      final splitError = _split.validate(amount);
      if (splitError != null) {
        showSnack(context, splitError);
        return;
      }
      await _saveSplitBill(repo, amount, note);
      return;
    }

    if (_isEditing) {
      await repo.updateTransaction(
        id: widget.editing!.tx.id,
        kind: _kind,
        amount: amount,
        occurredAt: _occurredAt,
        walletFromId: _walletFromId,
        walletToId: _walletToId,
        categoryId: _categoryId,
        personId: _personId,
        fundId: _fundId,
        note: note.isEmpty ? null : note,
      );
    } else {
      await repo.addTransaction(
        kind: _kind,
        amount: amount,
        occurredAt: _occurredAt,
        walletFromId: _walletFromId,
        walletToId: _walletToId,
        categoryId: _categoryId,
        personId: _personId,
        fundId: _fundId,
        note: note.isEmpty ? null : note,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, _isEditing ? 'Đã cập nhật' : 'Đã ghi giao dịch');
  }

  Future<void> _saveSplitBill(Repository repo, int total, String note) async {
    final shares = _split.sharesFor(total);
    final myShare = _split.myShareFor(total);

    final ids = await repo.addSplitBill(
      walletFromId: _walletFromId!,
      myShare: myShare,
      sharesByPerson: shares,
      occurredAt: _occurredAt,
      categoryId: _categoryId,
      note: note.isEmpty ? null : note,
    );

    if (!mounted) return;
    Navigator.pop(context);

    final theirs = shares.values.fold<int>(0, (sum, v) => sum + v);
    showSnack(
      context,
      myShare > 0
          ? 'Đã ghi ${formatVnd(myShare)} tiền của bạn và '
              '${formatVnd(theirs)} cho ${shares.length} người nợ lại'
          : 'Đã ghi ${formatVnd(theirs)} cho ${shares.length} người nợ lại',
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () async {
          for (final id in ids) {
            await repo.softDeleteTransaction(id);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa giao dịch' : 'Ghi giao dịch'),
        actions: [
          if (_canSaveAsTemplate)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Lưu làm mẫu',
              onPressed: _saveAsTemplate,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xoá',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: wallets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (walletList) {
          if (walletList.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Chưa có ví nào',
              message: 'Hãy tạo ít nhất một ví trước khi ghi giao dịch.',
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                _KindSelector(selected: _kind, onChanged: _changeKind),
                const SizedBox(height: 20),
                AmountField(
                  controller: _amountController,
                  autofocus: !_isEditing,
                  label: _canSplit && _split.enabled
                      ? 'Tổng hoá đơn'
                      : 'Số tiền',
                  // Bảng chia tiền và dòng "khoản này lấy tiền từ đâu" đều phụ
                  // thuộc vào số tiền nên phải vẽ lại theo từng phím.
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                ..._buildFieldsForKind(walletList),
                if (_kind == TxKind.expense) ...[
                  const SizedBox(height: 12),
                  _FundPicker(
                    value: _fundId,
                    onChanged: (v) => setState(() => _fundId = v),
                  ),
                ],
                if (_canSplit) ...[
                  const SizedBox(height: 8),
                  SplitBillSection(
                    state: _split,
                    total: parseVnd(_amountController.text),
                    onChanged: () => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),
                _impactNote(),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  leading: const Icon(Icons.event),
                  title: const Text('Thời điểm'),
                  subtitle: Text(formatDateTime(_occurredAt)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú',
                    hintText: 'Ăn trưa với team, tiền trọ tháng 9...',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(
              _isEditing
                  ? 'Lưu thay đổi'
                  : (_canSplit && _split.enabled)
                      ? 'Ghi và chia tiền'
                      : 'Ghi lại',
            ),
          ),
        ),
      ),
    );
  }

  /// Khoản chi này lấy tiền từ đâu. Chỉ hiện khi ghi mới một khoản làm tiền
  /// ra khỏi ví trong tháng này — sửa khoản cũ thì số tự do đã tính nó rồi, còn
  /// chi từ quỹ thì không đụng tới tiền tự do.
  Widget _impactNote() {
    const none = SizedBox.shrink();
    if (_isEditing) return none;
    final today = ref.watch(todayProvider);
    if (monthKeyOf(_occurredAt) != monthKeyOf(today)) return none;

    final total = parseVnd(_amountController.text);
    final Widget note;
    if (_kind == TxKind.lend) {
      note = SpendImpactNote(amount: 0, categoryId: null, outside: total);
    } else if (_kind != TxKind.expense || _fundId != null) {
      return none;
    } else if (_canSplit && _split.enabled) {
      final mine = _split.myShareFor(total);
      note = SpendImpactNote(
        amount: mine,
        categoryId: _categoryId,
        outside: total - mine,
      );
    } else {
      note = SpendImpactNote(amount: total, categoryId: _categoryId);
    }
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: note);
  }

  List<Widget> _buildFieldsForKind(List<WalletWithBalance> wallets) {
    final widgets = <Widget>[];

    if (_kind == TxKind.transfer) {
      widgets.addAll([
        _WalletDropdown(
          label: 'Từ ví',
          icon: Icons.logout,
          wallets: wallets,
          value: _walletFromId,
          onChanged: (v) => setState(() => _walletFromId = v),
        ),
        const SizedBox(height: 12),
        _WalletDropdown(
          label: 'Đến ví',
          icon: Icons.login,
          wallets: wallets,
          value: _walletToId,
          excludeId: _fundId == null ? _walletFromId : null,
          onChanged: (v) => setState(() => _walletToId = v),
        ),
      ]);
    } else if (_kind.needsWalletFrom) {
      widgets.add(_WalletDropdown(
        label: 'Trừ vào ví',
        icon: Icons.account_balance_wallet_outlined,
        wallets: wallets,
        value: _walletFromId,
        onChanged: (v) => setState(() => _walletFromId = v),
      ));
    } else if (_kind.needsWalletTo) {
      widgets.add(_WalletDropdown(
        label: 'Cộng vào ví',
        icon: Icons.account_balance_wallet_outlined,
        wallets: wallets,
        value: _walletToId,
        onChanged: (v) => setState(() => _walletToId = v),
      ));
    }

    if (_kind.needsCategory) {
      widgets
        ..add(const SizedBox(height: 12))
        ..add(_CategoryPicker(
          flow: _kind == TxKind.income ? 'income' : 'expense',
          value: _categoryId,
          onChanged: (v) => setState(() => _categoryId = v),
        ));
    }

    if (_kind.needsPerson) {
      widgets
        ..add(const SizedBox(height: 12))
        ..add(_PersonPicker(
          value: _personId,
          onChanged: (v) => setState(() => _personId = v),
        ));
    }

    return widgets;
  }

  Future<void> _confirmDelete() async {
    final editing = widget.editing!;
    final groupId = editing.tx.groupId;
    final repo = ref.read(repositoryProvider);

    // Giao dịch trả dùm được ghi thành một cặp; xoá lẻ một nửa sẽ để lại khoản
    // nợ mồ côi, nên phải hỏi rõ.
    final groupCount = groupId == null ? 0 : await repo.countInGroup(groupId);
    if (!mounted) return;

    final ok = await confirmDialog(
      context,
      title: 'Xoá giao dịch?',
      message: groupCount > 1
          ? 'Giao dịch này nằm trong một nhóm $groupCount giao dịch được ghi '
              'cùng lúc. Cả nhóm sẽ bị xoá.'
          : 'Bạn có thể hoàn tác ngay sau khi xoá.',
    );
    if (!ok || !mounted) return;

    if (groupCount > 1) {
      final ids = await repo.softDeleteGroup(groupId!);
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(
        context,
        'Đã xoá $groupCount giao dịch',
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => repo.restoreMany(ids),
        ),
      );
    } else {
      await repo.softDeleteTransaction(editing.tx.id);
      if (!mounted) return;
      Navigator.pop(context);
      showSnack(
        context,
        'Đã xoá giao dịch',
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => repo.restoreTransaction(editing.tx.id),
        ),
      );
    }
  }
}

/// Hàng chip chọn loại giao dịch, tách nhóm thường và nhóm nợ cho dễ nhìn.
class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.selected, required this.onChanged});

  final TxKind selected;
  final ValueChanged<TxKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in kQuickTxKinds)
              _KindChip(
                kind: kind,
                selected: selected == kind,
                onTap: () => onChanged(kind),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Vay mượn',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in kDebtTxKinds)
              _KindChip(
                kind: kind,
                selected: selected == kind,
                onTap: () => onChanged(kind),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selected.hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final TxKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        kind.icon,
        size: 18,
        color: selected ? Theme.of(context).colorScheme.onSecondaryContainer : null,
      ),
      label: Text(kind.label),
      showCheckmark: false,
    );
  }
}

class _WalletDropdown extends StatelessWidget {
  const _WalletDropdown({
    required this.label,
    required this.icon,
    required this.wallets,
    required this.value,
    required this.onChanged,
    this.excludeId,
  });

  final String label;
  final IconData icon;
  final List<WalletWithBalance> wallets;
  final int? value;
  final int? excludeId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items =
        wallets.where((w) => excludeId == null || w.id != excludeId).toList();
    // Nếu ví đang chọn vừa bị loại khỏi danh sách (do trùng với ví bên kia),
    // phải bỏ chọn, nếu không DropdownButton sẽ ném lỗi.
    final safeValue = items.any((w) => w.id == value) ? value : null;

    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
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
                Expanded(child: Text(w.name, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text(
                  formatVndShort(w.balance),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Chọn danh mục bằng lưới chip, kèm nút thêm mới ngay tại chỗ.
class _CategoryPicker extends ConsumerWidget {
  const _CategoryPicker({
    required this.flow,
    required this.value,
    required this.onChanged,
  });

  final String flow;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(
      flow == 'income' ? incomeCategoriesProvider : expenseCategoriesProvider,
    );

    return categories.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Lỗi: $e'),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh mục',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in list)
                ChoiceChip(
                  selected: value == c.id,
                  onSelected: (_) => onChanged(c.id),
                  showCheckmark: false,
                  avatar: Icon(
                    iconFor(c.iconKey, fallback: Icons.label_outline),
                    size: 18,
                    color: c.colorValue == null ? null : Color(c.colorValue!),
                  ),
                  label: Text(c.name),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Thêm'),
                onPressed: () async {
                  final id = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryEditScreen(flow: flow),
                    ),
                  );
                  if (id != null) onChanged(id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chọn quỹ để lấy tiền ra chi.
///
/// Chỉ hiện khi có quỹ. Chọn quỹ nào thì khoản chi vừa trừ ví vừa trừ quỹ đó —
/// đúng như thực tế: tiền quỹ vốn đã nằm trong ví, giờ mới thực sự tiêu.
class _FundPicker extends ConsumerWidget {
  const _FundPicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funds = ref.watch(fundsProvider).valueOrNull ?? const <FundProgress>[];
    if (funds.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final selected = funds.where((f) => f.id == value).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lấy từ quỹ', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              selected: value == null,
              onSelected: (_) => onChanged(null),
              showCheckmark: false,
              label: const Text('Không'),
            ),
            for (final f in funds)
              ChoiceChip(
                selected: value == f.id,
                onSelected: (_) => onChanged(f.id),
                showCheckmark: false,
                avatar: Icon(
                  iconFor(f.fund.iconKey, fallback: Icons.savings),
                  size: 18,
                  color: f.fund.colorValue == null
                      ? null
                      : Color(f.fund.colorValue!),
                ),
                label: Text('${f.name} · ${formatVndShort(f.saved)}'),
              ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Text(
            'Trừ vào quỹ ${selected.name}, đang có '
            '${formatVnd(selected.saved)} ở ${selected.walletName}.',
            style: TextStyle(fontSize: 12, color: scheme.outline),
          ),
        ],
      ],
    );
  }
}

/// Chọn người từ danh bạ. Thêm một lần, những lần sau chỉ việc chọn.
class _PersonPicker extends ConsumerWidget {
  const _PersonPicker({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider);

    return people.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Lỗi: $e'),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Với ai', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (list.isEmpty)
            Text(
              'Danh bạ đang trống. Thêm một người để bắt đầu ghi nợ.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in list)
                ChoiceChip(
                  selected: value == p.id,
                  onSelected: (_) => onChanged(p.id),
                  showCheckmark: false,
                  avatar: InitialAvatar(
                    name: p.name,
                    size: 24,
                    color:
                        p.avatarColor == null ? null : Color(p.avatarColor!),
                  ),
                  label: Text(p.name),
                ),
              ActionChip(
                avatar: const Icon(Icons.person_add_alt, size: 18),
                label: const Text('Thêm người'),
                onPressed: () async {
                  final id = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PersonEditScreen(),
                    ),
                  );
                  if (id != null) onChanged(id);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
