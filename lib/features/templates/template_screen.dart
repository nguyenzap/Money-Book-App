import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../transactions/tx_editor_screen.dart';

/// Dùng một mẫu: đủ trường thì ghi luôn tại thời điểm bấm, thiếu thì mở màn
/// ghi đã điền sẵn phần còn lại.
///
/// [context] phải còn sống sau khi bấm — gọi từ trong bottom sheet thì truyền
/// context của Navigator chứ không phải của sheet, vì sheet đóng ngay.
Future<void> useTemplate(
  BuildContext context,
  WidgetRef ref,
  TemplateView template,
) async {
  final repo = ref.read(repositoryProvider);

  if (template.isOneTap) {
    final id = await repo.recordFromTemplate(
      template.id,
      occurredAt: DateTime.now(),
    );
    if (!context.mounted) return;
    if (id != null) {
      showSnack(
        context,
        'Đã ghi ${formatVnd(template.amount!)} · ${template.label}',
        action: SnackBarAction(
          label: 'Hoàn tác',
          onPressed: () => repo.softDeleteTransaction(id),
        ),
      );
      return;
    }
    // Mẫu vừa đổi ở nơi khác (ví bị lưu trữ, danh mục bị xoá): đọc lại rồi
    // để người dùng điền nốt.
    final fresh = await repo.getTemplate(template.id);
    if (!context.mounted || fresh == null) return;
    template = fresh;
  }

  await openTxEditor(context, fromTemplate: template);
}

/// Màn quản lý mẫu chi tiêu: thêm, sửa, xoá, kéo để đổi thứ tự.
class TemplateScreen extends ConsumerWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mẫu chi tiêu')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTemplateEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm mẫu'),
      ),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.bolt_outlined,
              title: 'Chưa có mẫu nào',
              message:
                  'Mẫu là khoản chi hay lặp lại: cà phê sáng, gửi xe, ăn '
                  'trưa. Lưu một lần, sau đó bấm một chạm ở màn Tổng quan là '
                  'ghi xong, thời điểm lấy đúng lúc bấm.',
              action: FilledButton.icon(
                onPressed: () => showTemplateEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('Thêm mẫu'),
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
            itemCount: list.length,
            onReorder: (from, to) {
              final ids = list.map((t) => t.id).toList();
              if (to > from) to -= 1;
              ids.insert(to, ids.removeAt(from));
              ref.read(repositoryProvider).reorderTemplates(ids);
            },
            footer: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Mẫu đủ số tiền, ví và danh mục thì bấm là ghi luôn. Thiếu '
                'trường nào thì bấm vào sẽ mở màn ghi đã điền sẵn phần còn '
                'lại. Giữ và kéo để đổi thứ tự.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            itemBuilder: (context, i) {
              final t = list[i];
              return _TemplateTile(key: ValueKey(t.id), template: t);
            },
          );
        },
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({super.key, required this.template});

  final TemplateView template;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = template;
    final color = t.categoryColorValue == null
        ? null
        : Color(t.categoryColorValue!);

    final details = <String>[
      t.hasWallet ? t.walletName! : 'Chọn ví khi ghi',
      if (t.hasCategory) t.categoryName! else 'Chọn danh mục khi ghi',
    ];

    return ListTile(
      leading: IconAvatar(
        icon: iconFor(t.categoryIconKey, fallback: Icons.bolt_outlined),
        color: color,
      ),
      title: Text(t.label, overflow: TextOverflow.ellipsis),
      subtitle: Text(details.join(' · '), overflow: TextOverflow.ellipsis),
      trailing: t.hasAmount
          ? MoneyText(t.amount!, colored: false)
          : Text(
              'Nhập khi ghi',
              style: TextStyle(fontSize: 12.5, color: scheme.outline),
            ),
      onTap: () => showTemplateEditor(context, editing: t),
    );
  }
}

/// Hàng nút ghi nhanh theo mẫu. Bấm để dùng, giữ để sửa mẫu.
class TemplateChips extends StatelessWidget {
  const TemplateChips({
    super.key,
    required this.templates,
    required this.onTap,
    this.onLongPress,
  });

  final List<TemplateView> templates;
  final ValueChanged<TemplateView> onTap;
  final ValueChanged<TemplateView>? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in templates)
          _TemplateChip(
            template: t,
            onTap: () => onTap(t),
            onLongPress: onLongPress == null ? null : () => onLongPress!(t),
          ),
      ],
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.template,
    required this.onTap,
    this.onLongPress,
  });

  final TemplateView template;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = template;
    final color = t.categoryColorValue == null
        ? scheme.primary
        : Color(t.categoryColorValue!);

    return Material(
      color: scheme.surfaceContainerHigh,
      shape: StadiumBorder(
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconFor(t.categoryIconKey, fallback: Icons.bolt_outlined),
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  t.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 6),
              // Mẫu thiếu trường sẽ mở màn ghi thay vì ghi luôn — phải nhìn
              // ra được trước khi bấm.
              if (t.isOneTap)
                Text(
                  formatVndShort(t.amount!),
                  style: TextStyle(color: scheme.outline, fontSize: 13),
                )
              else
                Icon(Icons.edit_note, size: 18, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// ----- Thêm / sửa mẫu ------------------------------------------------------

/// Thêm hoặc sửa một mẫu.
Future<void> showTemplateEditor(BuildContext context, {TemplateView? editing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _TemplateEditor(editing: editing),
    ),
  );
}

class _TemplateEditor extends ConsumerStatefulWidget {
  const _TemplateEditor({this.editing});

  final TemplateView? editing;

  @override
  ConsumerState<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<_TemplateEditor> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  int? _walletId;
  int? _categoryId;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.editing?.template;
    if (t != null) {
      _noteController.text = t.note ?? '';
      _amountController.text = t.amount == null ? '' : groupDigits(t.amount!);
      _walletId = t.walletId;
      _categoryId = t.categoryId;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    final amount = parseVnd(_amountController.text);
    if (note.isEmpty && _categoryId == null) {
      showSnack(context, 'Đặt ghi chú hoặc chọn danh mục để đặt tên cho mẫu');
      return;
    }

    final repo = ref.read(repositoryProvider);
    if (_isEditing) {
      await repo.updateTemplate(
        id: widget.editing!.id,
        note: note.isEmpty ? null : note,
        amount: amount > 0 ? amount : null,
        walletId: _walletId,
        categoryId: _categoryId,
      );
    } else {
      await repo.insertTemplate(
        note: note.isEmpty ? null : note,
        amount: amount > 0 ? amount : null,
        walletId: _walletId,
        categoryId: _categoryId,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, _isEditing ? 'Đã lưu mẫu' : 'Đã thêm mẫu');
  }

  Future<void> _delete() async {
    final t = widget.editing!;
    final ok = await confirmDialog(
      context,
      title: 'Xoá mẫu?',
      message:
          'Xoá mẫu "${t.label}". Các khoản đã ghi từ mẫu này vẫn còn '
          'nguyên.',
    );
    if (!ok || !mounted) return;
    await ref.read(repositoryProvider).deleteTemplate(t.id);
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, 'Đã xoá mẫu');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const [];
    final categories =
        ref.watch(expenseCategoriesProvider).valueOrNull ?? const [];

    // Ví đã lưu trữ hay danh mục đã xoá không còn trong danh sách chọn; để
    // nguyên id cũ thì DropdownButton ném lỗi, nên coi như chưa chọn.
    final walletValue = wallets.any((w) => w.id == _walletId)
        ? _walletId
        : null;
    final categoryValue = categories.any((c) => c.id == _categoryId)
        ? _categoryId
        : null;

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
                    _isEditing ? 'Sửa mẫu chi tiêu' : 'Mẫu chi tiêu mới',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Xoá mẫu',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Cà phê sáng, gửi xe, cơm trưa...',
                helperText: 'Cũng là tên của mẫu',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _amountController,
              label: 'Số tiền',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Text(
              'Để trống nếu mỗi lần một khác, bấm mẫu sẽ hỏi số tiền.',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              // Đổi key khi danh sách ví đổi để giá trị hiển thị khớp lại.
              key: ValueKey('wallet-$walletValue-${wallets.length}'),
              initialValue: walletValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Trừ vào ví',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Chọn khi ghi'),
                ),
                for (final w in wallets)
                  DropdownMenuItem<int?>(
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
                          child: Text(w.name, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _walletId = v),
            ),
            const SizedBox(height: 16),
            Text('Danh mục', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  selected: categoryValue == null,
                  onSelected: (_) => setState(() => _categoryId = null),
                  showCheckmark: false,
                  label: const Text('Chọn khi ghi'),
                ),
                for (final c in categories)
                  ChoiceChip(
                    selected: categoryValue == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                    showCheckmark: false,
                    avatar: Icon(
                      iconFor(c.iconKey, fallback: Icons.label_outline),
                      size: 18,
                      color: c.colorValue == null ? null : Color(c.colorValue!),
                    ),
                    label: Text(c.name),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Lưu mẫu'),
            ),
          ],
        ),
      ),
    );
  }
}
