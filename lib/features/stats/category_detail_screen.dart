import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/repository.dart';
import '../../core/domain/tx_kind.dart';
import '../../core/format/dates.dart';
import '../../core/format/money.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../transactions/tx_editor_screen.dart';
import '../transactions/tx_tile.dart';

/// Khoá của một danh mục trong một tháng. `categoryId` null là "Chưa phân loại".
typedef _CategoryMonth = ({int? categoryId, int monthKey});

final _categoryExpensesProvider =
    StreamProvider.family<List<TxView>, _CategoryMonth>((ref, key) {
      return ref
          .watch(repositoryProvider)
          .watchTransactions(
            categoryId: key.categoryId,
            uncategorized: key.categoryId == null,
            monthKey: key.monthKey,
            kind: TxKind.expense,
          );
    });

/// Tổng chi từng ngày của tháng, phần tử `i` là ngày `i + 1`.
///
/// Trả về đủ [days] phần tử kể cả những ngày không tiêu gì, để biểu đồ không
/// nhảy cóc qua ngày trống — ngày không tiêu cũng là thông tin.
List<int> dailyTotals(Iterable<TxView> txs, int monthKey, int days) {
  final totals = List<int>.filled(days, 0);
  for (final v in txs) {
    if (v.tx.monthKey != monthKey) continue;
    final day = v.tx.dayKey % 100;
    if (day >= 1 && day <= days) totals[day - 1] += v.tx.amount;
  }
  return totals;
}

/// Toàn bộ khoản chi của một danh mục trong tháng, kèm biểu đồ theo ngày.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.name,
    required this.monthKey,
    this.iconKey,
    this.colorValue,
  });

  final int? categoryId;
  final String name;
  final int monthKey;
  final String? iconKey;
  final int? colorValue;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  bool _cumulative = false;

  /// Ngày đang chọn trên biểu đồ (1-based), null là ngày cuối cùng.
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final key = (categoryId: widget.categoryId, monthKey: widget.monthKey);
    final txs = ref.watch(_categoryExpensesProvider(key));
    final today = ref.watch(todayProvider);
    final budgets =
        ref.watch(budgetsProvider(widget.monthKey)).valueOrNull ?? const [];
    final budget = widget.categoryId == null
        ? null
        : budgets.where((b) => b.categoryId == widget.categoryId).firstOrNull;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              iconFor(widget.iconKey, fallback: Icons.label_outline),
              size: 20,
              color: widget.colorValue == null
                  ? scheme.onSurfaceVariant
                  : Color(widget.colorValue!),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: txs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (list) {
          final monthDays = daysInMonth(widget.monthKey);
          final elapsed = daysElapsedIn(widget.monthKey, now: today);
          // Khoản ghi trước cho ngày sau hôm nay vẫn phải hiện ra được.
          final lastDataDay = list.fold<int>(
            0,
            (m, v) => math.max(m, v.tx.dayKey % 100),
          );
          final shownDays = math.max(
            1,
            math.min(monthDays, math.max(elapsed, lastDataDay)),
          );
          final daily = dailyTotals(list, widget.monthKey, shownDays);
          final total = daily.fold<int>(0, (s, v) => s + v);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                monthKeyLabel(widget.monthKey),
                style: TextStyle(color: scheme.outline, fontSize: 13),
              ),
              const SizedBox(height: 4),
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
                _summaryLine(list.length, total, elapsed, budget),
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _ChartCard(
                daily: daily,
                monthDays: monthDays,
                budget: budget,
                cumulative: _cumulative,
                selectedDay: _selectedDay,
                onModeChanged: (v) => setState(() => _cumulative = v),
                onSelectDay: (d) => setState(() => _selectedDay = d),
              ),
              const SizedBox(height: 20),
              Text(
                'Các khoản chi',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'Tháng này chưa có khoản chi nào',
                        style: TextStyle(color: scheme.outline),
                      ),
                    ),
                  ),
                )
              else
                ..._dayGroups(context, list),
            ],
          );
        },
      ),
    );
  }

  String _summaryLine(
    int count,
    int total,
    int elapsed,
    BudgetProgress? budget,
  ) {
    final parts = <String>['$count khoản'];
    if (elapsed > 0) {
      parts.add('trung bình ${formatVndShort(total ~/ elapsed)}/ngày');
    }
    if (budget != null) {
      parts.add(
        budget.isOver
            ? 'vượt hạn mức ${formatVndShort(-budget.remaining)}'
            : 'còn ${formatVndShort(budget.remaining)} / '
                  '${formatVndShort(budget.limitAmount)}',
      );
    }
    return parts.join(' · ');
  }

  /// Danh sách gom theo ngày, mới nhất lên đầu, mỗi nhóm có tổng của ngày.
  List<Widget> _dayGroups(BuildContext context, List<TxView> list) {
    final scheme = Theme.of(context).colorScheme;
    final groups = <int, List<TxView>>{};
    for (final v in list) {
      groups.putIfAbsent(v.tx.dayKey, () => []).add(v);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final day in days) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dayHeaderLabel(day),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                formatVnd(groups[day]!.fold<int>(0, (s, v) => s + v.tx.amount)),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < groups[day]!.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 68),
                TxTile(
                  view: groups[day]![i],
                  onTap: () => openTxEditor(context, editing: groups[day]![i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}

/// Biểu đồ chi theo ngày, chuyển được giữa "mỗi ngày" và "cộng dồn".
///
/// Có hạn mức thì vẽ thêm đường tham chiếu trên CÙNG trục: ở chế độ mỗi ngày là
/// mức trung bình được tiêu một ngày, ở chế độ cộng dồn là nhịp đều của hạn
/// mức — đường thực tế nằm trên nó nghĩa là đang tiêu nhanh hơn nhịp.
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.daily,
    required this.monthDays,
    required this.budget,
    required this.cumulative,
    required this.selectedDay,
    required this.onModeChanged,
    required this.onSelectDay,
  });

  final List<int> daily;
  final int monthDays;
  final BudgetProgress? budget;
  final bool cumulative;
  final int? selectedDay;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<int> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = daily.length;
    final selected = (selectedDay ?? days).clamp(1, days);

    final values = <int>[];
    var running = 0;
    for (final v in daily) {
      running += v;
      values.add(cumulative ? running : v);
    }

    // Đường tham chiếu, null nếu không có hạn mức.
    double? reference(int day) {
      final b = budget;
      if (b == null || monthDays == 0) return null;
      return cumulative
          ? b.limitAmount * day / monthDays
          : b.limitAmount / monthDays;
    }

    final selectedValue = values[selected - 1];
    final ref = reference(selected);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Mỗi ngày')),
                ButtonSegment(value: true, label: Text('Cộng dồn')),
              ],
              selected: {cumulative},
              showSelectedIcon: false,
              onSelectionChanged: (s) => onModeChanged(s.first),
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
            const SizedBox(height: 14),
            // Dòng đọc số của ngày đang chọn — chạm hoặc kéo trên biểu đồ để
            // đổi ngày.
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Ngày $selected: ',
                  style: TextStyle(fontSize: 13, color: scheme.outline),
                ),
                Text(
                  formatVnd(selectedValue),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (cumulative) ...[
                  Text(
                    ' đã chi',
                    style: TextStyle(fontSize: 13, color: scheme.outline),
                  ),
                ],
                const Spacer(),
                if (ref != null)
                  Text(
                    cumulative
                        ? 'nhịp đều ${formatVndShort(ref.round())}'
                        : 'mức ${formatVndShort(ref.round())}/ngày',
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  void pick(Offset p) {
                    final plotLeft = _DailyChartPainter.leftGutter;
                    final w = constraints.maxWidth - plotLeft;
                    if (w <= 0) return;
                    final slot = w / days;
                    final day = ((p.dx - plotLeft) / slot).floor() + 1;
                    onSelectDay(day.clamp(1, days));
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => pick(d.localPosition),
                    onHorizontalDragUpdate: (d) => pick(d.localPosition),
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _DailyChartPainter(
                        values: values,
                        cumulative: cumulative,
                        reference: budget == null ? null : reference,
                        selectedDay: selected,
                        barColor: scheme.primary,
                        referenceColor: scheme.onSurfaceVariant,
                        gridColor: scheme.outlineVariant.withValues(alpha: 0.5),
                        labelColor: scheme.outline,
                        highlightColor: scheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (budget != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  _LegendSwatch(color: scheme.primary, dashed: false),
                  const SizedBox(width: 6),
                  Text(
                    cumulative ? 'Đã chi cộng dồn' : 'Chi trong ngày',
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
                  const SizedBox(width: 16),
                  _LegendSwatch(color: scheme.onSurfaceVariant, dashed: true),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      cumulative ? 'Nhịp đều của hạn mức' : 'Mức mỗi ngày',
                      style: TextStyle(fontSize: 12, color: scheme.outline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 10),
      painter: _SwatchPainter(color: color, dashed: dashed),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 3, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SwatchPainter old) =>
      old.color != color || old.dashed != dashed;
}

class _DailyChartPainter extends CustomPainter {
  _DailyChartPainter({
    required this.values,
    required this.cumulative,
    required this.reference,
    required this.selectedDay,
    required this.barColor,
    required this.referenceColor,
    required this.gridColor,
    required this.labelColor,
    required this.highlightColor,
  });

  static const leftGutter = 40.0;
  static const bottomGutter = 20.0;

  final List<int> values;
  final bool cumulative;
  final double? Function(int day)? reference;
  final int selectedDay;
  final Color barColor;
  final Color referenceColor;
  final Color gridColor;
  final Color labelColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final days = values.length;
    if (days == 0) return;

    final plot = Rect.fromLTRB(
      leftGutter,
      6,
      size.width,
      size.height - bottomGutter,
    );
    final slot = plot.width / days;

    // Trục y phải chứa cả đường tham chiếu, nếu không nó có thể bị cắt mất.
    var maxValue = values.fold<int>(0, math.max).toDouble();
    if (reference != null) {
      maxValue = math.max(maxValue, reference!(days) ?? 0);
    }
    // Bước vạch là số tròn, trần là bội của bước, nên mọi nhãn đều gọn.
    final tick = _niceStep(maxValue / 3);
    final ticks = math.max(1, (maxValue / tick).ceil());
    final top = tick * ticks;
    double yOf(num v) => plot.bottom - (v / top) * plot.height;
    double xCenter(int day) => plot.left + slot * (day - 0.5);

    // Lưới ngang mờ, nhãn bên trái.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= ticks; i++) {
      final v = tick * i;
      final y = yOf(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(
        canvas,
        formatVndShort(v.round()),
        Offset(leftGutter - 6, y),
        align: TextAlign.right,
        anchorRight: true,
      );
    }

    // Nhãn trục x: ngày 1, vài mốc ở giữa, và ngày cuối.
    final step = days <= 10 ? 2 : (days <= 20 ? 5 : 7);
    for (var d = 1; d <= days; d++) {
      final show = d == 1 || d == days || (d % step == 0 && days - d >= 2);
      if (!show) continue;
      _text(
        canvas,
        '$d',
        Offset(xCenter(d), plot.bottom + 4),
        align: TextAlign.center,
        centered: true,
      );
    }

    if (cumulative) {
      _paintLine(canvas, plot, xCenter, yOf);
    } else {
      _paintBars(canvas, slot, xCenter, yOf, plot);
    }

    if (reference != null) {
      _paintReference(canvas, plot, xCenter, yOf);
    }
  }

  void _paintBars(
    Canvas canvas,
    double slot,
    double Function(int) xCenter,
    double Function(num) yOf,
    Rect plot,
  ) {
    // Cột mảnh, cách nhau ít nhất 2px, đầu bo tròn và chân bám đường đáy.
    final width = math.max(2.0, math.min(14.0, slot - 2));
    for (var d = 1; d <= values.length; d++) {
      final v = values[d - 1];
      final isSelected = d == selectedDay;
      if (v <= 0) {
        if (isSelected) {
          canvas.drawLine(
            Offset(xCenter(d) - width / 2, plot.bottom),
            Offset(xCenter(d) + width / 2, plot.bottom),
            Paint()
              ..color = highlightColor
              ..strokeWidth = 2,
          );
        }
        continue;
      }
      final rect = Rect.fromLTRB(
        xCenter(d) - width / 2,
        math.min(yOf(v), plot.bottom - 2),
        xCenter(d) + width / 2,
        plot.bottom,
      );
      final radius = Radius.circular(math.min(4, width / 2));
      canvas.drawRRect(
        RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius),
        Paint()
          ..color = isSelected ? barColor : barColor.withValues(alpha: 0.5),
      );
    }
  }

  void _paintLine(
    Canvas canvas,
    Rect plot,
    double Function(int) xCenter,
    double Function(num) yOf,
  ) {
    final path = Path()..moveTo(xCenter(1), yOf(values.first));
    for (var d = 2; d <= values.length; d++) {
      path.lineTo(xCenter(d), yOf(values[d - 1]));
    }
    final area = Path.from(path)
      ..lineTo(xCenter(values.length), plot.bottom)
      ..lineTo(xCenter(1), plot.bottom)
      ..close();
    canvas.drawPath(area, Paint()..color = barColor.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = barColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    // Đánh dấu ngày đang chọn, viền màu nền để tách khỏi đường.
    final c = Offset(xCenter(selectedDay), yOf(values[selectedDay - 1]));
    canvas.drawLine(
      Offset(c.dx, plot.top),
      Offset(c.dx, plot.bottom),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );
    canvas.drawCircle(c, 5, Paint()..color = barColor);
  }

  void _paintReference(
    Canvas canvas,
    Rect plot,
    double Function(int) xCenter,
    double Function(num) yOf,
  ) {
    final paint = Paint()
      ..color = referenceColor
      ..strokeWidth = 1.5;
    // Cộng dồn: đường chéo từ gốc. Mỗi ngày: đường ngang.
    final start = cumulative
        ? Offset(plot.left, plot.bottom)
        : Offset(plot.left, yOf(reference!(1)!));
    final end = Offset(plot.right, yOf(reference!(values.length)!));
    _dashed(canvas, start, end, paint);
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    for (double t = 0; t < total; t += 8) {
      canvas.drawLine(a + dir * t, a + dir * math.min(t + 4, total), paint);
    }
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    TextAlign align = TextAlign.left,
    bool anchorRight = false,
    bool centered = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: 10, color: labelColor),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = anchorRight
        ? at.dx - tp.width
        : centered
        ? at.dx - tp.width / 2
        : at.dx;
    final dy = anchorRight ? at.dy - tp.height / 2 : at.dy;
    tp.paint(canvas, Offset(dx, dy));
  }

  /// Làm tròn lên một bước dễ đọc: 1, 2, 2.5, 5 nhân luỹ thừa của 10.
  static double _niceStep(double v) {
    if (v <= 1000) return 1000;
    final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (v <= m * exp) return m * exp;
    }
    return 10 * exp;
  }

  @override
  bool shouldRepaint(_DailyChartPainter old) =>
      old.values != values ||
      old.cumulative != cumulative ||
      old.selectedDay != selectedDay ||
      old.barColor != barColor ||
      (old.reference == null) != (reference == null);
}
