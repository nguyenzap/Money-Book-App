import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/autotrack_repository.dart';
import '../../core/db/repository.dart';
import '../../core/domain/bill.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../autotrack/autotrack_providers.dart';
import '../autotrack/categorize_actions.dart';
import 'bill_section.dart';
import 'split_bill_section.dart';
import 'split_state.dart';
import 'tx_editor_actions.dart';
import 'tx_form_rules.dart';
import 'widgets/fund_picker.dart';
import 'widgets/impact_note_section.dart';
import 'widgets/kind_selector.dart';
import 'widgets/occurred_at_tile.dart';
import 'widgets/tx_kind_fields.dart';

/// Mở màn hình ghi giao dịch. Gom một chỗ để mọi nơi trong app gọi giống nhau.
Future<void> openTxEditor(
  BuildContext context, {
  TxKind initialKind = TxKind.expense,
  TxView? editing,
  int? presetWalletId,
  int? presetPersonId,
  TemplateView? fromTemplate,
  bool initialPaidByOther = false,
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
        initialPaidByOther: initialPaidByOther,
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
    this.initialPaidByOther = false,
  });

  final TxKind initialKind;
  final TxView? editing;
  final int? presetWalletId;
  final int? presetPersonId;

  /// Mẫu chưa đủ trường để ghi một chạm: điền sẵn phần đã có, người dùng chỉ
  /// việc điền nốt.
  final TemplateView? fromTemplate;

  /// Mở sẵn ở chế độ "Ghi nợ" (người khác trả dùm, mình nợ lại).
  final bool initialPaidByOther;

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

  /// Hoá đơn chi tiết. Bật lên thì số tiền là tổng hoá đơn.
  final _bill = BillState();

  /// Đang sửa một khoản có hoá đơn mà hoá đơn chưa đọc xong. Lúc này lưu thì
  /// phải giữ nguyên hoá đơn cũ, không được hiểu "chưa bật" là "bỏ hoá đơn".
  bool _billLoading = false;

  /// Người khác trả dùm: không chọn ví, chọn người mình nợ.
  bool _paidByOther = false;

  bool get _isEditing => widget.editing != null;

  /// Ảnh chụp các lựa chọn hiện tại. Mọi quy tắc (công tắc nào được bật, đổi
  /// loại thì dọn gì, chọn thiếu gì) nằm ở [TxForm]; màn hình chỉ giữ trạng
  /// thái.
  TxForm get _form => TxForm(
    kind: _kind,
    walletFromId: _walletFromId,
    walletToId: _walletToId,
    categoryId: _categoryId,
    personId: _personId,
    fundId: _fundId,
    paidByOther: _paidByOther,
    splitEnabled: _split.enabled,
    billEnabled: _bill.enabled,
    isEditing: _isEditing,
  );

  bool get _canSplit => _form.canSplit;

  bool get _canBill => _form.canBill;

  bool get _usesBill => _form.usesBill;

  /// Số tiền sẽ ghi: tổng hoá đơn nếu đang dùng hoá đơn, không thì số gõ tay.
  int get _amount =>
      _usesBill ? _bill.total : parseVnd(_amountController.text);

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
      _paidByOther = editing.isPaidByOther;
      _occurredAt =
          DateTime.fromMillisecondsSinceEpoch(editing.tx.occurredAt);
      if (editing.hasBill) {
        _billLoading = true;
        _loadBill(editing.tx.id);
      }
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
      _paidByOther = widget.initialPaidByOther;
      _occurredAt = DateTime.now();
      _personId = widget.presetPersonId;
      _applyPresetWallet();
    }
  }

  Future<void> _loadBill(int txId) async {
    final items = await ref.read(repositoryProvider).watchBill(txId).first;
    if (!mounted) return;
    setState(() {
      _bill.load(items);
      _billLoading = false;
    });
  }

  /// Việc với dữ liệu (ghi, xoá, lưu mẫu) nằm ở [TxEditorActions]; màn hình
  /// chỉ lo thông báo, đóng màn và hộp thoại.
  TxEditorActions get _actions => TxEditorActions(ref.read(repositoryProvider));

  /// Hiện câu báo của một thao tác, kèm nút Hoàn tác nếu thao tác có.
  void _showResult(TxActionResult result) {
    final undo = result.undo;
    showSnack(
      context,
      result.message,
      action: undo == null
          ? null
          : SnackBarAction(label: 'Hoàn tác', onPressed: undo),
    );
  }

  /// Lưu các trường đang nhập thành một mẫu, để lần sau ghi một chạm. Không
  /// đóng màn hình — người dùng vẫn ghi khoản này như thường.
  Future<void> _saveAsTemplate() async {
    final result = await _actions.saveAsTemplate(
      note: _noteController.text.trim(),
      amount: parseVnd(_amountController.text),
      walletId: _walletFromId,
      categoryId: _categoryId,
    );
    if (!mounted) return;
    showSnack(context, result.message);
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
    _bill.dispose();
    super.dispose();
  }

  /// Đổi loại giao dịch: [TxForm.afterKindChange] quyết định dọn trường nào.
  void _changeKind(TxKind next) {
    if (next == _kind) return;
    final f = _form.afterKindChange(next);
    setState(() {
      _kind = f.kind;
      _walletFromId = f.walletFromId;
      _walletToId = f.walletToId;
      _categoryId = f.categoryId;
      _personId = f.personId;
      _fundId = f.fundId;
      _paidByOther = f.paidByOther;
      _split.enabled = f.splitEnabled;
    });
  }

  Future<void> _pickDateTime() async {
    final picked = await pickOccurredAt(context, _occurredAt);
    if (picked == null || !mounted) return;
    setState(() => _occurredAt = picked);
  }


  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final form = _form;
    final error = form.validateSelection();
    if (error != null) {
      showSnack(context, error);
      return;
    }

    if (_usesBill) {
      final billError = validateBill(_bill.lines);
      if (billError != null) {
        showSnack(context, billError);
        return;
      }
    }

    final amount = _amount;
    final note = _noteController.text.trim();

    final TxActionResult result;
    LearnResult? learned;
    if (form.usesSplit) {
      final splitError = _split.validate(amount);
      if (splitError != null) {
        showSnack(context, splitError);
        return;
      }
      result = await _actions.saveSplit(
        form,
        myShare: _split.myShareFor(amount),
        shares: _split.sharesFor(amount),
        occurredAt: _occurredAt,
        note: note,
      );
    } else {
      result = await _actions.save(
        form,
        amount: amount,
        occurredAt: _occurredAt,
        note: note,
        bill: _usesBill ? _bill.lines : const <BillLine>[],
        editingId: widget.editing?.tx.id,
        keepExistingBill: _billLoading,
      );
      // Giao dịch tự ghi đổi danh mục: nhớ người nhận này cho lần sau.
      final before = widget.editing?.tx;
      if (before != null &&
          before.autoEventId != null &&
          form.categoryId != null &&
          form.categoryId != before.categoryId &&
          mounted) {
        learned = await learnFromEdit(
          context,
          ref,
          transactionId: before.id,
          categoryId: form.categoryId!,
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
    if (learned != null && learned.appliedToOthers > 0) {
      final auto = ref.read(autoTrackRepositoryProvider);
      final applied = learned;
      showSnack(
        context,
        'Đã cập nhật, phân loại thêm ${applied.appliedToOthers} giao dịch của '
        '${applied.receiverName}',
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => auto.undoLearn(applied),
        ),
      );
      return;
    }
    _showResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_form.title),
        actions: [
          if (_form.canSaveAsTemplate)
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
                if (_form.showsKindSelector) ...[
                  KindSelector(selected: _kind, onChanged: _changeKind),
                  const SizedBox(height: 20),
                ],
                // Có hoá đơn thì số tiền là tổng hoá đơn, hiện ở cuối phần
                // hoá đơn bên dưới, nên không cho gõ tay nữa.
                if (!_usesBill) ...[
                  AmountField(
                    controller: _amountController,
                    autofocus: !_isEditing,
                    label: _form.usesSplit
                        ? 'Tổng hoá đơn'
                        : 'Số tiền',
                    // Bảng chia tiền và dòng "khoản này lấy tiền từ đâu" đều
                    // phụ thuộc vào số tiền nên phải vẽ lại theo từng phím.
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                ],
                ...txKindFields(
                  form: _form,
                  wallets: walletList,
                  onWalletFrom: (v) => setState(() => _walletFromId = v),
                  onWalletTo: (v) => setState(() => _walletToId = v),
                  onCategory: (v) => setState(() => _categoryId = v),
                  onPerson: (v) => setState(() => _personId = v),
                ),
                if (_form.showsFundPicker) ...[
                  const SizedBox(height: 12),
                  FundPicker(
                    value: _fundId,
                    onChanged: (v) => setState(() => _fundId = v),
                  ),
                ],
                if (_canBill) ...[
                  const SizedBox(height: 8),
                  BillSection(
                    state: _bill,
                    onChanged: () => setState(() {}),
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
                ImpactNoteSection(
                  form: _form,
                  occurredAt: _occurredAt,
                  total: _amount,
                  myShareFor: _split.myShareFor,
                ),
                OccurredAtTile(
                  occurredAt: _occurredAt,
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
                  : _form.usesSplit
                      ? 'Ghi và chia tiền'
                      : 'Ghi lại',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final editing = widget.editing!;

    // Giao dịch trả dùm được ghi thành một cặp; xoá lẻ một nửa sẽ để lại khoản
    // nợ mồ côi, nên phải hỏi rõ.
    final groupCount = await _actions.groupSize(editing);
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

    final result = await _actions.delete(editing, groupCount: groupCount);
    if (!mounted) return;
    Navigator.pop(context);
    _showResult(result);
  }
}
