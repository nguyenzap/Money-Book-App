import 'package:flutter/material.dart';

import 'format/money.dart';
import 'format/names.dart';
import 'icons.dart';
import 'theme.dart';

/// Số tiền, tự tô màu theo dấu.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.signed = false,
    this.style,
    this.colored = true,
  });

  final int amount;
  final bool signed;
  final TextStyle? style;
  final bool colored;

  @override
  Widget build(BuildContext context) {
    return Text(
      signed ? formatVndSigned(amount) : formatVnd(amount),
      style: (style ?? const TextStyle()).copyWith(
        color: colored ? amountColor(context, amount) : null,
        fontWeight: style?.fontWeight ?? FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Ô nhập tiền: bàn phím số, tự chèn dấu chấm ngăn cách, kèm nút cộng nhanh.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Số tiền',
    this.autofocus = false,
    this.showQuickAdd = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool showQuickAdd;
  final ValueChanged<int>? onChanged;

  void _setValue(int next) {
    controller.text = next == 0 ? '' : groupDigits(next);
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    onChanged?.call(next);
  }

  void _add(int delta) => _setValue(parseVnd(controller.text) + delta);

  /// Nhân số đang gõ với 1000.
  ///
  /// Tiền Việt hầu như luôn tròn nghìn nên gõ "35" rồi bấm là ra 35.000, đỡ
  /// phải bấm ba số 0. Khác với các nút cộng nhanh ở chỗ nó thay đổi độ lớn
  /// của số đang có chứ không cộng thêm một khoản cố định.
  void _appendThousand() {
    final current = parseVnd(controller.text);
    if (current == 0) return;
    _setValue(current * 1000);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: const [ThousandsFormatter()],
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            labelText: label,
            suffixText: '₫',
            suffixStyle: const TextStyle(fontSize: 20),
            hintText: '0',
          ),
          validator: (value) {
            if (parseVnd(value ?? '') <= 0) return 'Nhập số tiền lớn hơn 0';
            return null;
          },
          onChanged: (v) => onChanged?.call(parseVnd(v)),
        ),
        if (showQuickAdd) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, value) in const [
                ('+1k', 1000),
                ('+10k', 10000),
                ('+50k', 50000),
                ('+100k', 100000),
                ('+500k', 500000),
              ])
                ActionChip(
                  label: Text(label),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _add(value),
                ),
              ActionChip(
                label: const Text('.000'),
                visualDensity: VisualDensity.compact,
                tooltip: 'Nhân với 1000',
                onPressed: _appendThousand,
              ),
              ActionChip(
                label: const Text('Xoá'),
                visualDensity: VisualDensity.compact,
                onPressed: () => _setValue(0),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Vòng tròn có icon, dùng cho ví / danh mục / người.
class IconAvatar extends StatelessWidget {
  const IconAvatar({
    super.key,
    required this.icon,
    this.color,
    this.size = 42,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: base, size: size * 0.52),
    );
  }
}

/// Chữ cái đầu của tên, dùng làm ảnh đại diện cho người trong danh bạ.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar({
    super.key,
    required this.name,
    this.color,
    this.size = 42,
  });

  final String name;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    final initial = initialOf(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: base,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// Màn hình trống, kèm gợi ý việc nên làm tiếp.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.outline),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Hộp thoại xác nhận. Trả về true nếu người dùng đồng ý.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xoá',
  String cancelLabel = 'Huỷ',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Thông báo ngắn ở đáy màn hình.
void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
}

/// Bảng chọn màu.
class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final value in kPickerColors)
          GestureDetector(
            onTap: () => onSelected(value),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Color(value),
                shape: BoxShape.circle,
                border: selected == value
                    ? Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 3,
                      )
                    : null,
              ),
              child: selected == value
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Bảng chọn icon.
class IconPickerGrid extends StatelessWidget {
  const IconPickerGrid({
    super.key,
    required this.keys,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final List<String> keys;
  final String? selected;
  final ValueChanged<String> onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final key in keys)
          GestureDetector(
            onTap: () => onSelected(key),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected == key
                    ? base.withValues(alpha: 0.2)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: selected == key
                    ? Border.all(color: base, width: 2)
                    : null,
              ),
              child: Icon(
                iconFor(key),
                color: selected == key
                    ? base
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
