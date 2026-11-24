import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/autotrack_repository.dart';
import '../../core/domain/autotrack/text_fold.dart';
import '../../core/format/dates.dart';
import '../../core/widgets.dart';
import 'autotrack_providers.dart';
import 'categorize_actions.dart';

/// Những gì app đã học để tự phân loại: người nhận → danh mục, và từ khoá.
class CategorizeRulesScreen extends StatelessWidget {
  const CategorizeRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Phân loại tự động'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Người nhận'), Tab(text: 'Từ khoá')],
          ),
        ),
        body: const TabBarView(children: [_RulesTab(), _KeywordsTab()]),
      ),
    );
  }
}

class _RulesTab extends ConsumerStatefulWidget {
  const _RulesTab();

  @override
  ConsumerState<_RulesTab> createState() => _RulesTabState();
}

class _RulesTabState extends ConsumerState<_RulesTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(receiverRulesProvider);
    final similarOn =
        ref.watch(autoTrackFlagProvider(AutoTrackRepository.kSimilarKey)).value ??
        true;
    final scheme = Theme.of(context).colorScheme;

    return rules.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Lỗi',
        message: '$e',
      ),
      data: (all) {
        final list = all
            .where(
              (r) =>
                  _query.isEmpty ||
                  foldVi(r.rule.displayName).contains(_query) ||
                  foldVi(r.rule.matchKey).contains(_query) ||
                  foldVi(r.categoryName).contains(_query),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SwitchListTile(
              title: const Text('Đoán theo tên gần giống'),
              subtitle: const Text(
                '"Phúc Long CN Q1" theo quy tắc của "Phúc Long CN Q3". '
                'Khoản đoán luôn chờ bạn xác nhận.',
              ),
              value: similarOn,
              onChanged: (v) => ref
                  .read(autoTrackRepositoryProvider)
                  .setFlag(AutoTrackRepository.kSimilarKey, v),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm người nhận hoặc danh mục',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = foldVi(v)),
              ),
            ),
            if (all.isEmpty)
              const EmptyState(
                icon: Icons.school_outlined,
                title: 'Chưa học được người nhận nào',
                message:
                    'Phân loại giao dịch tự ghi ở màn "Phân loại giao dịch", '
                    'app sẽ nhớ người nhận đó ở đây.',
              ),
            for (final r in list)
              Dismissible(
                key: ValueKey(r.rule.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: scheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
                ),
                onDismissed: (_) async {
                  final auto = ref.read(autoTrackRepositoryProvider);
                  final rule = r.rule;
                  await auto.deleteRule(rule.id);
                  if (!context.mounted) return;
                  showSnack(
                    context,
                    'Đã quên "${rule.displayName}"',
                    action: SnackBarAction(
                      label: 'Hoàn tác',
                      onPressed: () => auto.restoreRule(rule),
                    ),
                  );
                },
                child: ListTile(
                  title: Text(
                    r.rule.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      r.rule.flow == 'income' ? 'Tiền vào' : 'Tiền ra',
                      '${r.rule.hitCount} lần tự xếp',
                      if (r.rule.lastUsedAt != null)
                        'gần nhất ${formatDate(DateTime.fromMillisecondsSinceEpoch(r.rule.lastUsedAt!))}',
                    ].join(' · '),
                    style: TextStyle(color: scheme.outline, fontSize: 12.5),
                  ),
                  trailing: Chip(
                    label: Text(r.categoryName),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () async {
                    final id = await pickCategory(
                      context,
                      flow: r.rule.flow,
                      selected: r.rule.categoryId,
                      title: 'Danh mục cho "${r.rule.displayName}"',
                    );
                    if (id == null) return;
                    await ref
                        .read(autoTrackRepositoryProvider)
                        .setRuleCategory(r.rule.id, id);
                  },
                ),
              ),
            if (all.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Bấm để đổi danh mục, vuốt sang trái để quên. Đổi ở đây chỉ '
                  'áp cho giao dịch từ nay về sau.',
                  style: TextStyle(color: scheme.outline, fontSize: 12.5),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _KeywordsTab extends ConsumerWidget {
  const _KeywordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keywords = ref.watch(categoryKeywordsProvider);
    final on =
        ref.watch(autoTrackFlagProvider(AutoTrackRepository.kKeywordsKey)).value ??
        true;
    final scheme = Theme.of(context).colorScheme;
    final auto = ref.read(autoTrackRepositoryProvider);

    return keywords.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Lỗi',
        message: '$e',
      ),
      data: (list) {
        // Gom theo danh mục.
        final byCategory = <String, List<KeywordView>>{};
        for (final k in list) {
          (byCategory[k.categoryName] ??= []).add(k);
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SwitchListTile(
              title: const Text('Đoán theo từ khoá'),
              subtitle: const Text(
                'Người nhận lạ có chữ "CAFE" thì đoán Ăn uống. Khoản đoán luôn '
                'chờ bạn xác nhận.',
              ),
              value: on,
              onChanged: (v) =>
                  auto.setFlag(AutoTrackRepository.kKeywordsKey, v),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Thêm từ khoá'),
              onTap: () => _add(context, ref),
            ),
            for (final entry in byCategory.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final k in entry.value)
                      InputChip(
                        label: Text(k.keyword.keyword),
                        selected: k.keyword.enabled,
                        showCheckmark: false,
                        onSelected: (v) =>
                            auto.setKeywordEnabled(k.keyword.id, v),
                        onDeleted: () => auto.deleteKeyword(k.keyword.id),
                      ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Bấm để tạm tắt một từ khoá, bấm × để xoá. Từ khoá khớp nguyên '
                'chữ: "BE" không khớp trong "BEP".',
                style: TextStyle(color: scheme.outline, fontSize: 12.5),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final word = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ khoá mới'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ví dụ: KATINAT',
            helperText: 'Không phân biệt hoa thường, có dấu hay không',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Tiếp'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (word == null || word.trim().isEmpty || !context.mounted) return;

    final flow = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Danh mục chi'),
              onTap: () => Navigator.pop(context, 'expense'),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Danh mục thu'),
              onTap: () => Navigator.pop(context, 'income'),
            ),
          ],
        ),
      ),
    );
    if (flow == null || !context.mounted) return;
    final categoryId = await pickCategory(
      context,
      flow: flow,
      title: 'Từ khoá "${word.trim()}" thuộc danh mục',
    );
    if (categoryId == null) return;
    final ok = await ref
        .read(autoTrackRepositoryProvider)
        .addKeyword(word, categoryId);
    if (!ok && context.mounted) {
      showSnack(context, 'Từ khoá này toàn chữ ngân hàng tự thêm, không dùng được');
    }
  }
}
