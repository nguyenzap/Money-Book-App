import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/format/money.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../people/person_edit_screen.dart';

/// Cách chia tiền một hoá đơn.
enum SplitMode {
  /// Chia đều cho mình và tất cả những người được chọn.
  equal,

  /// Tự gõ phần của từng người.
  custom,
}

/// Trạng thái chia tiền của một hoá đơn.
///
/// Sống bên trong màn ghi chi tiêu: người dùng nhập tổng hoá đơn ở ô số tiền
/// như bình thường, bật công tắc chia tiền, rồi chọn ai cùng ăn.
class SplitState {
  SplitState();

  bool enabled = false;
  SplitMode mode = SplitMode.equal;

  /// Những người cùng chia, theo thứ tự được chọn.
  final List<int> personIds = [];

  /// Phần của từng người khi chia tay (mode == custom).
  final Map<int, TextEditingController> controllers = {};

  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
  }

  void toggle(int personId) {
    if (personIds.remove(personId)) {
      controllers.remove(personId)?.dispose();
    } else {
      personIds.add(personId);
      controllers[personId] = TextEditingController();
    }
  }

  /// Số người cùng chia hoá đơn, tính cả mình.
  int get headcount => personIds.length + 1;

  /// Phần của từng người khi chia đều.
  ///
  /// Chia không hết thì phần lẻ dồn vào mình, để tổng luôn khớp hoá đơn và
  /// mình không đòi bạn bè thêm mấy đồng lẻ.
  Map<int, int> equalShares(int total) {
    if (personIds.isEmpty || total <= 0) return const {};
    final each = total ~/ headcount;
    return {for (final id in personIds) id: each};
  }

  Map<int, int> customShares() {
    final result = <int, int>{};
    for (final id in personIds) {
      final value = parseVnd(controllers[id]?.text ?? '');
      if (value > 0) result[id] = value;
    }
    return result;
  }

  Map<int, int> sharesFor(int total) =>
      mode == SplitMode.equal ? equalShares(total) : customShares();

  /// Phần còn lại là của mình.
  int myShareFor(int total) {
    final theirs =
        sharesFor(total).values.fold<int>(0, (sum, v) => sum + v);
    return total - theirs;
  }

  /// Lý do không ghi được, hoặc null nếu hợp lệ.
  String? validate(int total) {
    if (!enabled) return null;
    if (personIds.isEmpty) return 'Hãy chọn người cùng chia tiền';
    final shares = sharesFor(total);
    if (shares.isEmpty) return 'Hãy nhập phần của từng người';
    if (shares.length != personIds.length) {
      return 'Hãy nhập phần của từng người';
    }
    final theirs = shares.values.fold<int>(0, (sum, v) => sum + v);
    if (theirs > total) {
      return 'Phần của mọi người (${formatVnd(theirs)}) vượt quá hoá đơn';
    }
    return null;
  }
}

/// Phần giao diện chia tiền, hiện bên dưới ô số tiền ở màn ghi chi tiêu.
class SplitBillSection extends ConsumerWidget {
  const SplitBillSection({
    super.key,
    required this.state,
    required this.total,
    required this.onChanged,
  });

  final SplitState state;
  final int total;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: state.enabled,
          onChanged: (v) {
            state.enabled = v;
            onChanged();
          },
          title: const Text('Trả dùm, chia tiền với người khác'),
          subtitle: const Text(
            'Bạn trả trước cả hoá đơn, những người kia nợ lại phần của họ',
          ),
        ),
        if (state.enabled) ...[
          const SizedBox(height: 8),
          _PeoplePicker(state: state, onChanged: onChanged),
          if (state.personIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            SegmentedButton<SplitMode>(
              segments: const [
                ButtonSegment(
                  value: SplitMode.equal,
                  label: Text('Chia đều'),
                  icon: Icon(Icons.balance),
                ),
                ButtonSegment(
                  value: SplitMode.custom,
                  label: Text('Nhập tay'),
                  icon: Icon(Icons.edit_outlined),
                ),
              ],
              selected: {state.mode},
              onSelectionChanged: (s) {
                state.mode = s.first;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            if (state.mode == SplitMode.custom)
              _CustomShares(state: state, onChanged: onChanged),
            _SplitSummary(state: state, total: total),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Chọn những người cùng ăn để chia hoá đơn.',
              style: TextStyle(color: scheme.outline, fontSize: 12.5),
            ),
          ],
        ],
      ],
    );
  }
}

class _PeoplePicker extends ConsumerWidget {
  const _PeoplePicker({required this.state, required this.onChanged});

  final SplitState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider);

    return people.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Lỗi: $e'),
      data: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ai cùng ăn',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in list)
                FilterChip(
                  selected: state.personIds.contains(p.id),
                  onSelected: (_) {
                    state.toggle(p.id);
                    onChanged();
                  },
                  avatar: state.personIds.contains(p.id)
                      ? null
                      : InitialAvatar(
                          name: p.name,
                          size: 24,
                          color: p.avatarColor == null
                              ? null
                              : Color(p.avatarColor!),
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
                  if (id != null) {
                    state.toggle(id);
                    onChanged();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomShares extends ConsumerWidget {
  const _CustomShares({required this.state, required this.onChanged});

  final SplitState state;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleProvider).valueOrNull ?? const <Person>[];
    final byId = {for (final p in people) p.id: p};

    return Column(
      children: [
        for (final id in state.personIds)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                InitialAvatar(
                  name: byId[id]?.name ?? '?',
                  size: 34,
                  color: byId[id]?.avatarColor == null
                      ? null
                      : Color(byId[id]!.avatarColor!),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    byId[id]?.name ?? 'Người đã xoá',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: state.controllers[id],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: const [ThousandsFormatter()],
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '0',
                      suffixText: '₫',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bảng tổng kết: mỗi người bao nhiêu, mình bao nhiêu, và câu giải thích vì
/// sao thống kê chỉ tính phần của mình.
class _SplitSummary extends ConsumerWidget {
  const _SplitSummary({required this.state, required this.total});

  final SplitState state;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final shares = state.sharesFor(total);
    final theirs = shares.values.fold<int>(0, (sum, v) => sum + v);
    final mine = total - theirs;
    final over = theirs > total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            label: 'Hoá đơn',
            value: total,
            bold: true,
          ),
          const Divider(height: 18),
          _SummaryRow(
            label: 'Phần của bạn — tính vào chi tiêu',
            value: mine,
            highlight: !over,
            danger: over,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: shares.length == 1
                ? '1 người nợ lại'
                : '${shares.length} người nợ lại',
            value: theirs,
          ),
          if (state.mode == SplitMode.equal && shares.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Chia đều ${state.headcount} phần, mỗi người '
              '${formatVnd(shares.values.first)}',
              style: TextStyle(fontSize: 11.5, color: scheme.outline),
            ),
          ],
          if (over) ...[
            const SizedBox(height: 10),
            Text(
              'Phần của mọi người đang vượt quá hoá đơn.',
              style: TextStyle(color: scheme.error, fontSize: 12.5),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              mine == 0
                  ? 'Bạn không ăn phần nào nên khoản này không tính vào chi tiêu, '
                      'chỉ ghi vào sổ nợ.'
                  : 'Thống kê và ngân sách chỉ tính ${formatVnd(mine)} — '
                      'phần bạn thực sự ăn. ${formatVnd(theirs)} còn lại vào sổ nợ.',
              style: TextStyle(color: scheme.outline, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.highlight = false,
    this.danger = false,
  });

  final String label;
  final int value;
  final bool bold;
  final bool highlight;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger
        ? scheme.error
        : highlight
            ? scheme.primary
            : null;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color ?? scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatVnd(value),
          style: TextStyle(
            fontWeight: bold || highlight ? FontWeight.bold : FontWeight.w600,
            fontSize: bold || highlight ? 15 : 13.5,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
