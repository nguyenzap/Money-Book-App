import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Thêm hoặc sửa một người trong danh bạ.
///
/// Trả về id qua Navigator.pop để nơi gọi chọn luôn người vừa thêm.
class PersonEditScreen extends ConsumerStatefulWidget {
  const PersonEditScreen({super.key, this.editing});

  final Person? editing;

  @override
  ConsumerState<PersonEditScreen> createState() => _PersonEditScreenState();
}

class _PersonEditScreenState extends ConsumerState<PersonEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  int? _colorValue;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _nameController.text = editing.name;
      _phoneController.text = editing.phone ?? '';
      _noteController.text = editing.note ?? '';
      _colorValue = editing.avatarColor;
    } else {
      _colorValue = kPickerColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = ref.read(repositoryProvider);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final note = _noteController.text.trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    int id;
    if (_isEditing) {
      final updated = widget.editing!.copyWith(
        name: name,
        phone: Value(phone.isEmpty ? null : phone),
        note: Value(note.isEmpty ? null : note),
        avatarColor: Value(_colorValue),
        updatedAt: now,
      );
      await repo.updatePerson(updated);
      id = updated.id;
    } else {
      id = await repo.insertPerson(
        PeopleCompanion.insert(
          name: name,
          phone: Value(phone.isEmpty ? null : phone),
          note: Value(note.isEmpty ? null : note),
          avatarColor: Value(_colorValue),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa thông tin' : 'Thêm người'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Center(
              child: ListenableBuilder(
                listenable: _nameController,
                builder: (context, _) => InitialAvatar(
                  name: _nameController.text,
                  color: _colorValue == null ? null : Color(_colorValue!),
                  size: 76,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tên',
                hintText: 'Nam, Hùng, chị Lan...',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                hintText: 'Không bắt buộc',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                hintText: 'Bạn cùng phòng, đồng nghiệp...',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 24),
            Text('Màu', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            ColorPickerRow(
              selected: _colorValue,
              onSelected: (v) => setState(() => _colorValue = v),
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
