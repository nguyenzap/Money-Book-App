import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/db/database.dart';
import '../../core/domain/bill.dart';
import '../../core/format/money.dart';
import '../../core/theme.dart';

/// Một dòng đang nhập của hoá đơn.
class BillRow {
  BillRow({
    String name = '',
    int quantity = 1,
    int unitPrice = 0,
    this.isDiscount = false,
  }) : name = TextEditingController(text: name),
       quantity = TextEditingController(text: '$quantity'),
       price = TextEditingController(
         text: unitPrice > 0 ? groupDigits(unitPrice) : '',
       );

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController price;
  final bool isDiscount;

  BillLine toLine() => BillLine(
    name: name.text.trim(),
    quantity: isDiscount ? 1 : (int.tryParse(quantity.text) ?? 0),
    unitPrice: parseVnd(price.text),
    isDiscount: isDiscount,
  );

  void dispose() {
    name.dispose();
    quantity.dispose();
    price.dispose();
  }
}

/// Trạng thái hoá đơn chi tiết của một khoản chi.
///
/// Bật hoá đơn thì số tiền của khoản chi không gõ tay nữa mà là tổng hoá đơn,
/// để sổ sách và hoá đơn luôn cùng một số.
class BillState {
  bool enabled = false;
  final List<BillRow> rows = [];

  List<BillLine> get lines => [for (final r in rows) r.toLine()];
  int get total => billTotal(lines);

  void enable() {
    enabled = true;
    if (rows.isEmpty) rows.add(BillRow());
  }

  void load(List<BillItem> items) {
    for (final r in rows) {
      r.dispose();
    }
    rows
      ..clear()
      ..addAll([
        for (final i in items)
          BillRow(
            name: i.name,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
            isDiscount: i.isDiscount,
          ),
      ]);
    enabled = rows.isNotEmpty;
  }

  void removeAt(int index) => rows.removeAt(index).dispose();

  void dispose() {
    for (final r in rows) {
      r.dispose();
    }
  }
}

/// Hoá đơn chi tiết, hiện ở màn ghi chi tiêu: món gì, bao nhiêu, giá bao
/// nhiêu, thành tiền. Bấm vào khoản chi đã ghi là thấy lại đúng hoá đơn này.
class BillSection extends StatelessWidget {
  const BillSection({super.key, required this.state, required this.onChanged});

  final BillState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: state.enabled,
          onChanged: (v) {
            if (v) {
              state.enable();
            } else {
              state.enabled = false;
            }
            onChanged();
          },
          title: const Text('Hoá đơn chi tiết'),
          subtitle: const Text('Ghi từng món đã mua, số tiền là tổng hoá đơn'),
        ),
        if (state.enabled) ...[
          for (var i = 0; i < state.rows.length; i++)
            _BillRowEditor(
              key: ObjectKey(state.rows[i]),
              row: state.rows[i],
              onChanged: onChanged,
              onRemove: () {
                state.removeAt(i);
                onChanged();
              },
            ),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Thêm món'),
                onPressed: () {
                  state.rows.add(BillRow());
                  onChanged();
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.local_offer_outlined, size: 18),
                label: const Text('Giảm giá'),
                onPressed: () {
                  state.rows.add(BillRow(name: 'Giảm giá', isDiscount: true));
                  onChanged();
                },
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Text(
                'Tổng hoá đơn · ${state.rows.length} dòng',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                formatVnd(state.total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BillRowEditor extends StatelessWidget {
  const _BillRowEditor({
    super.key,
    required this.row,
    required this.onChanged,
    required this.onRemove,
  });

  final BillRow row;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = row.toLine();
    const dense = InputDecoration(isDense: true);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.name,
                  decoration: dense.copyWith(
                    hintText: row.isDiscount ? 'Giảm giá' : 'Tên món',
                    prefixIcon: Icon(
                      row.isDiscount
                          ? Icons.local_offer_outlined
                          : Icons.shopping_basket_outlined,
                      size: 20,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => onChanged(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Bỏ dòng này',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (!row.isDiscount) ...[
                SizedBox(
                  width: 64,
                  child: TextField(
                    controller: row.quantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    textAlign: TextAlign.center,
                    decoration: dense.copyWith(labelText: 'SL'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('×', style: TextStyle(color: scheme.outline)),
                ),
              ],
              Expanded(
                child: TextField(
                  controller: row.price,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [ThousandsFormatter()],
                  textAlign: TextAlign.right,
                  decoration: dense.copyWith(
                    labelText: row.isDiscount ? 'Số tiền giảm' : 'Đơn giá',
                    suffixText: '₫',
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: Text(
                  line.total < 0
                      ? '-${formatVnd(-line.total)}'
                      : formatVnd(line.total),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: line.total < 0 ? incomeColor(context) : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
