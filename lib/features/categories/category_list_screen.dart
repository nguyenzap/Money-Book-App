import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/icons.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'category_edit_screen.dart';

/// Quản lý loại giao dịch. Người dùng tự thêm, tự xoá — app chỉ gieo sẵn vài
/// cái cho đỡ trống.
class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _currentFlow => _tabController.index == 0 ? 'expense' : 'income';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Chi tiêu'),
            Tab(text: 'Thu nhập'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryEditScreen(flow: _currentFlow),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Thêm'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoryTab(flow: 'expense'),
          _CategoryTab(flow: 'income'),
        ],
      ),
    );
  }
}

class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({required this.flow});

  final String flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(
      flow == 'income' ? incomeCategoriesProvider : expenseCategoriesProvider,
    );

    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.label_outline,
            title: 'Chưa có danh mục nào',
            message: flow == 'income'
                ? 'Thêm danh mục thu nhập: Lương, Thưởng...'
                : 'Thêm danh mục chi tiêu: Ăn uống, Đi lại...',
            action: FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryEditScreen(flow: flow),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Thêm danh mục'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
          itemBuilder: (context, index) =>
              _CategoryTile(category: list[index]),
        );
      },
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        category.colorValue == null ? null : Color(category.colorValue!);

    return ListTile(
      leading: IconAvatar(
        icon: iconFor(category.iconKey, fallback: Icons.label_outline),
        color: color,
      ),
      title: Text(category.name),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Xoá',
        onPressed: () => _confirmDelete(context, ref),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryEditScreen(
            flow: category.flow,
            editing: category,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final count = await repo.countTransactionsOfCategory(category.id);
    if (!context.mounted) return;

    final ok = await confirmDialog(
      context,
      title: 'Xoá danh mục?',
      message: count == 0
          ? 'Xoá "${category.name}".'
          : '"${category.name}" đang được dùng ở $count giao dịch.\n\n'
              'Các giao dịch đó vẫn giữ nguyên số tiền, chỉ chuyển thành '
              '"Chưa phân loại".',
    );
    if (!ok) return;

    await repo.deleteCategory(category.id);
    if (context.mounted) showSnack(context, 'Đã xoá "${category.name}"');
  }
}
