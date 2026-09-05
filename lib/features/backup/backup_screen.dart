import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format/dates.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import 'backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(dbProvider));
});

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on BackupException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Có lỗi xảy ra: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportJson() => _run(() async {
        final service = ref.read(backupServiceProvider);
        final file = await service.writeJsonFile();
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Sao lưu Quản Lý Chi Tiêu',
            text: 'Bản sao lưu ngày ${formatDate(DateTime.now())}',
          ),
        );
      });

  Future<void> _exportCsv() => _run(() async {
        final service = ref.read(backupServiceProvider);
        final file = await service.writeCsvFile();
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Giao dịch Quản Lý Chi Tiêu',
          ),
        );
      });

  Future<void> _import() => _run(() async {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.any,
          withData: false,
        );
        final path = picked?.files.singleOrNull?.path;
        if (path == null) return;

        final service = ref.read(backupServiceProvider);
        final content = await File(path).readAsString();

        // Đọc thử trước để nói rõ sắp nạp bao nhiêu, và để file hỏng bị chặn
        // ngay chứ không phải sau khi người dùng đã chọn ghi đè.
        final stats = await service.peek(content);
        if (!mounted) return;

        final mode = await _askImportMode(stats);
        if (mode == null || !mounted) return;

        if (mode == ImportMode.replace) {
          final confirmed = await confirmDialog(
            context,
            title: 'Ghi đè toàn bộ dữ liệu?',
            message: 'Mọi ví, giao dịch, danh bạ và ngân sách hiện có sẽ bị '
                'xoá, thay bằng dữ liệu trong file.\n\n'
                'Nếu chưa chắc, hãy xuất một bản sao lưu trước.',
            confirmLabel: 'Ghi đè',
          );
          if (!confirmed || !mounted) return;
        }

        final result = await service.import(content, mode: mode);
        if (!mounted) return;
        showSnack(
          context,
          'Đã nạp ${result.stats.transactions} giao dịch, '
          '${result.stats.wallets} ví, ${result.stats.people} người',
        );
      });

  Future<ImportMode?> _askImportMode(BackupStats stats) {
    return showDialog<ImportMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nạp dữ liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File chứa ${stats.transactions} giao dịch, '
              '${stats.wallets} ví, ${stats.categories} danh mục, '
              '${stats.people} người'
              '${stats.budgets > 0 ? ', ${stats.budgets} hạn mức' : ''}.',
            ),
            const SizedBox(height: 16),
            const Text('Bạn muốn nạp thế nào?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImportMode.merge),
            child: const Text('Gộp thêm'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ImportMode.replace),
            child: const Text('Ghi đè'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Dữ liệu chỉ nằm trong máy này. Mất máy hoặc gỡ app '
                          'là mất hết, nên thỉnh thoảng hãy xuất một bản và '
                          'cất vào Drive hoặc Zalo của chính mình.',
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel('Xuất ra'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.save_alt),
                      title: const Text('Sao lưu đầy đủ'),
                      subtitle: const Text(
                        'File .json chứa mọi thứ, dùng để khôi phục lại sau này',
                      ),
                      onTap: _busy ? null : _exportJson,
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.table_chart_outlined),
                      title: const Text('Bảng giao dịch (CSV)'),
                      subtitle: const Text(
                        'Mở bằng Excel để xem hoặc tự tính toán thêm',
                      ),
                      onTap: _busy ? null : _exportCsv,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SectionLabel('Nạp vào'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Khôi phục từ file'),
                  subtitle: const Text(
                    'Chọn file .json đã sao lưu trước đó',
                  ),
                  onTap: _busy ? null : _import,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Khi nạp, bạn chọn ghi đè toàn bộ hoặc gộp thêm vào dữ liệu '
                'đang có. File hỏng hoặc không đúng định dạng sẽ bị từ chối '
                'mà không đụng gì tới dữ liệu hiện tại.',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ],
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
