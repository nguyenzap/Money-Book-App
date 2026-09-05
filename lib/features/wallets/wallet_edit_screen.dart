import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

const _walletTypes = <String, String>{
  'cash': 'Tiền mặt',
  'bank': 'Ngân hàng',
  'ewallet': 'Ví điện tử',
  'credit': 'Thẻ tín dụng',
  'savings': 'Tiết kiệm',
  'other': 'Khác',
};

const _typeIcons = <String, String>{
  'cash': 'cash',
  'bank': 'bank',
  'ewallet': 'ewallet',
  'credit': 'card',
  'savings': 'savings',
  'other': 'cash',
};

class WalletEditScreen extends ConsumerStatefulWidget {
  const WalletEditScreen({super.key, this.editing});

  final Wallet? editing;

  @override
  ConsumerState<WalletEditScreen> createState() => _WalletEditScreenState();
}

class _WalletEditScreenState extends ConsumerState<WalletEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = 'cash';
  String? _iconKey;
  int? _colorValue;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _nameController.text = editing.name;
      _balanceController.text = groupDigits(editing.initialBalance);
      _noteController.text = editing.note ?? '';
      _type = editing.type;
      _iconKey = editing.iconKey;
      _colorValue = editing.colorValue;
    } else {
      _iconKey = 'cash';
      _colorValue = kPickerColors.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _changeType(String type) {
    setState(() {
      _type = type;
      // Chỉ đổi icon theo loại khi người dùng chưa tự chọn icon riêng.
      if (!_isEditing || _iconKey == null) {
        _iconKey = _typeIcons[type];
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repo = ref.read(repositoryProvider);
    final name = _nameController.text.trim();
    final note = _noteController.text.trim();
    final balance = parseVnd(_balanceController.text);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_isEditing) {
      await repo.updateWallet(
        widget.editing!.copyWith(
          name: name,
          type: _type,
          initialBalance: balance,
          iconKey: Value(_iconKey),
          colorValue: Value(_colorValue),
          note: Value(note.isEmpty ? null : note),
          updatedAt: now,
        ),
      );
    } else {
      await repo.insertWallet(
        WalletsCompanion.insert(
          name: name,
          type: Value(_type),
          initialBalance: Value(balance),
          iconKey: Value(_iconKey),
          colorValue: Value(_colorValue),
          note: Value(note.isEmpty ? null : note),
          sortOrder: Value(await repo.nextWalletSortOrder()),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorValue == null ? null : Color(_colorValue!);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa ví' : 'Ví mới')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Center(
              child: IconAvatar(
                icon: iconFor(_iconKey, fallback: Icons.wallet),
                color: color,
                size: 72,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tên ví',
                hintText: 'Tiền mặt, MoMo, MB Bank, Techcombank...',
                prefixIcon: Icon(Icons.wallet),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nhập tên ví' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(),
              inputFormatters: const [ThousandsFormatter()],
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                labelText: _isEditing ? 'Số dư ban đầu' : 'Số dư hiện có',
                suffixText: '₫',
                hintText: '0',
                helperText: _isEditing
                    ? 'Đây là số dư lúc mới tạo ví, không phải số dư hiện tại. '
                        'Muốn sửa số dư hiện tại thì dùng "Điều chỉnh số dư".'
                    : 'Số tiền đang có trong ví này',
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text('Loại ví', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _walletTypes.entries)
                  ChoiceChip(
                    selected: _type == entry.key,
                    showCheckmark: false,
                    onSelected: (_) => _changeType(entry.key),
                    label: Text(entry.value),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Màu', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            ColorPickerRow(
              selected: _colorValue,
              onSelected: (v) => setState(() => _colorValue = v),
            ),
            const SizedBox(height: 20),
            Text('Biểu tượng', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            IconPickerGrid(
              keys: kWalletIconKeys,
              selected: _iconKey,
              color: color,
              onSelected: (v) => setState(() => _iconKey = v),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                prefixIcon: Icon(Icons.notes),
              ),
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

String walletTypeLabel(String type) => _walletTypes[type] ?? 'Khác';
