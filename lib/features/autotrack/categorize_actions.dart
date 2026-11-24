import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/autotrack_repository.dart';
import '../../core/db/database.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'autotrack_providers.dart';

/// Bảng chọn danh mục theo chiều tiền. Trả về id, hoặc null nếu bỏ qua.
Future<int?> pickCategory(
  BuildContext context, {
  required String flow,
  int? selected,
  String? title,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _CategorySheet(
      flow: flow,
      selected: selected,
      title: title,
    ),
  );
}

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet({required this.flow, this.selected, this.title});

  final String flow;
  final int? selected;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats =
        ref
            .watch(
              flow == 'income'
                  ? incomeCategoriesProvider
                  : expenseCategoriesProvider,
            )
            .value ??
        const <Category>[];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? 'Chọn danh mục',
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    selected: c.id == selected,
                    showCheckmark: false,
                    avatar: Icon(
                      iconFor(c.iconKey, fallback: Icons.label_outline),
                      size: 18,
                      color: c.colorValue == null ? null : Color(c.colorValue!),
                    ),
                    label: Text(c.name),
                    onSelected: (_) => Navigator.pop(context, c.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Phân loại một giao dịch tự ghi và nhớ người nhận, rồi báo kèm Hoàn tác.
Future<void> categorizeAndLearn(
  BuildContext context,
  WidgetRef ref, {
  required int transactionId,
  required int categoryId,
  bool rememberRule = true,
}) async {
  final auto = ref.read(autoTrackRepositoryProvider);
  final result = await auto.learn(
    transactionId: transactionId,
    categoryId: categoryId,
    rememberRule: rememberRule,
  );
  if (!context.mounted) return;
  final others = result.appliedToOthers;
  showSnack(
    context,
    others == 0
        ? 'Đã phân loại'
        : 'Đã phân loại thêm $others giao dịch của ${result.receiverName}',
    action: SnackBarAction(
      label: 'Hoàn tác',
      onPressed: () => auto.undoLearn(result),
    ),
  );
}

/// Sau khi sửa một giao dịch tự ghi trong màn ghi giao dịch mà đổi danh mục.
///
/// - Trước đó chưa phân loại hoặc app mới đoán: nhớ luôn, không hỏi.
/// - Trước đó theo quy tắc đã học (hoặc chính mình chọn): hỏi "Chỉ giao dịch
///   này" hay "Luôn dùng cho người này", vì đổi một lần thường là ngoại lệ
///   (mua quà ở siêu thị quen) chứ không phải người nhận đổi bản chất.
///
/// Trả về kết quả học để báo và hoàn tác, null nếu không học gì.
Future<LearnResult?> learnFromEdit(
  BuildContext context,
  WidgetRef ref, {
  required int transactionId,
  required int categoryId,
}) async {
  final auto = ref.read(autoTrackRepositoryProvider);
  final info = await auto.autoInfo(transactionId);
  if (info == null) return null; // nhập tay: không học
  if (info.receiverKey.isEmpty) {
    await auto.markUserCategorized(transactionId);
    return null;
  }

  final wasCertain = info.source != null && !info.source!.isGuess;
  var remember = true;
  if (wasCertain) {
    if (!context.mounted) return null;
    final always = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi danh mục cho người nhận này?'),
        content: Text(
          'App đang tự xếp "${info.receiverKey}" vào danh mục cũ. Đổi cho '
          'riêng lần này, hay từ nay luôn dùng danh mục mới?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chỉ giao dịch này'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Luôn dùng'),
          ),
        ],
      ),
    );
    remember = always ?? false;
  }
  return auto.learn(
    transactionId: transactionId,
    categoryId: categoryId,
    rememberRule: remember,
  );
}
