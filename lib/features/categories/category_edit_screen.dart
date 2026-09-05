import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Thêm hoặc sửa một loại giao dịch.
///
/// Trả về id của danh mục qua Navigator.pop, để nơi gọi (màn ghi giao dịch)
/// chọn luôn danh mục vừa tạo.
class CategoryEditScreen extends ConsumerStatefulWidget {
  const CategoryEditScreen({super.key, required this.flow, this.editing});

  /// 'expense' hoặc 'income'.
  final String flow;
  final Category? editing;

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  late String _flow;
  String? _iconKey;
  int? _colorValue;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _flow = editing?.flow ?? widget.flow;
    if (editing != null) {
      _nameController.text = editing.name;
      _iconKey = editing.iconKey;
      _colorValue = editing.colorValue;
    } else {
      _iconKey = widget.flow == 'income' ? 'salary' : 'food';
      _colorValue = kPickerColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = ref.read(repositoryProvider);
    final name = _nameController.text.trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    int id;
    if (_isEditing) {
      final updated = widget.editing!.copyWith(
        name: name,
        flow: _flow,
        iconKey: Value(_iconKey),
        colorValue: Value(_colorValue),
        updatedAt: now,
      );
      await repo.updateCategory(updated);
      id = updated.id;
    } else {
      id = await repo.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          flow: _flow,
          iconKey: Value(_iconKey),
          colorValue: Value(_colorValue),
          sortOrder: Value(await repo.nextCategorySortOrder(_flow)),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorValue == null ? null : Color(_colorValue!);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa danh mục' : 'Danh mục mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Center(
              child: IconAvatar(
                icon: iconFor(_iconKey, fallback: Icons.label_outline),
                color: color,
                size: 72,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tên danh mục',
                hintText: 'Ăn uống, Xăng xe, Tiền trọ...',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tên danh mục' : null,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'expense',
                  label: Text('Chi tiêu'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text('Thu nhập'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_flow},
              onSelectionChanged: (s) => setState(() => _flow = s.first),
            ),
            const SizedBox(height: 24),
            Text('Màu', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            ColorPickerRow(
              selected: _colorValue,
              onSelected: (v) => setState(() => _colorValue = v),
            ),
            const SizedBox(height: 24),
            Text('Biểu tượng', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            IconPickerGrid(
              keys: kCategoryIconKeys,
              selected: _iconKey,
              color: color,
              onSelected: (v) => setState(() => _iconKey = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Lưu'),
          ),
        ),
      ),
    );
  }
}
