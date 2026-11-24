import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/autotrack_repository.dart';
import '../../core/db/database.dart';
import '../../core/domain/autotrack/mask.dart';
import '../../core/format/dates.dart';
import '../../core/widgets.dart';
import 'autotrack_providers.dart';

/// Nhật ký thông báo đã nhận: để kiểm tra parser, lấy mẫu cho ngân hàng mới
/// và xem vì sao một tin không thành giao dịch.
class EventLogScreen extends ConsumerStatefulWidget {
  const EventLogScreen({super.key});

  @override
  ConsumerState<EventLogScreen> createState() => _EventLogScreenState();
}

class _Filter {
  const _Filter(this.label, this.statuses);
  final String label;
  final Set<EventStatus>? statuses;
}

// Khai báo một lần để khoá của provider.family giữ nguyên giữa các lần dựng.
const _filters = [
  _Filter('Tất cả', null),
  _Filter('Đã ghi', {EventStatus.parsed}),
  _Filter('Không khớp', {EventStatus.unmatched}),
  _Filter('Lỗi', {EventStatus.failed}),
  _Filter('Chưa có ví', {EventStatus.unmapped}),
  _Filter('Mẫu', {EventStatus.captured}),
  _Filter('Trùng', {EventStatus.duplicate}),
];

class _EventLogScreenState extends ConsumerState<EventLogScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(autoTrackEventsProvider(_filters[_filter].statuses));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký thông báo'),
        actions: [
          IconButton(
            tooltip: 'Xử lý ngay',
            icon: const Icon(Icons.refresh),
            onPressed: _sync,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                label: Text(_filters[i].label),
                selected: i == _filter,
                onSelected: (_) => setState(() => _filter = i),
              ),
            ),
          ),
          Expanded(
            child: events.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Lỗi',
                message: '$e',
              ),
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'Chưa có thông báo nào',
                      message:
                          'Thông báo từ các app đang theo dõi sẽ hiện ở đây.',
                    )
                  : RefreshIndicator(
                      onRefresh: _sync,
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, i) => _EventTile(list[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sync() async {
    try {
      final report = await ref.read(autoTrackServiceProvider).sync();
      if (!mounted) return;
      showSnack(
        context,
        report.created == 0
            ? 'Không có giao dịch mới'
            : 'Đã ghi ${report.created} giao dịch',
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Lỗi: $e');
    }
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile(this.event);
  final NotificationEvent event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = EventStatus.parse(event.status);
    final posted = DateTime.fromMillisecondsSinceEpoch(event.postedAt);
    final text = [
      if (event.title.isNotEmpty) event.title,
      event.body,
    ].join('\n');

    return ExpansionTile(
      leading: Icon(_icon(status), color: _color(status, scheme)),
      title: Text(
        event.body.split('\n').first,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          _label(status),
          formatDateTime(posted),
          event.packageName,
        ].join(' · '),
        style: const TextStyle(fontSize: 12),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (event.statusReason != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              event.statusReason!,
              style: TextStyle(color: scheme.outline),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Sao chép'),
              onPressed: () => _copy(context, text, 'Đã chép nguyên văn'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              label: const Text('Sao chép đã che'),
              onPressed: () => _copy(
                context,
                maskDigits(text),
                'Đã chép, số tài khoản đã che',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    showSnack(context, message);
  }

  static String _label(EventStatus s) => switch (s) {
    EventStatus.pending => 'Chờ xử lý',
    EventStatus.parsed => 'Đã ghi',
    EventStatus.unmatched => 'Không khớp',
    EventStatus.failed => 'Lỗi đọc',
    EventStatus.unmapped => 'Chưa có ví',
    EventStatus.captured => 'Mẫu',
    EventStatus.duplicate => 'Trùng',
  };

  static IconData _icon(EventStatus s) => switch (s) {
    EventStatus.parsed => Icons.check_circle_outline,
    EventStatus.failed => Icons.error_outline,
    EventStatus.unmapped => Icons.account_balance_wallet_outlined,
    EventStatus.captured => Icons.science_outlined,
    EventStatus.duplicate => Icons.copy_all_outlined,
    _ => Icons.notifications_none,
  };

  static Color _color(EventStatus s, ColorScheme scheme) => switch (s) {
    EventStatus.parsed => scheme.primary,
    EventStatus.failed => scheme.error,
    EventStatus.unmapped => scheme.tertiary,
    _ => scheme.outline,
  };
}
