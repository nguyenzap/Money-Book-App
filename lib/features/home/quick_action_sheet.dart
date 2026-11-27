import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/tx_kind.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../templates/template_screen.dart';
import '../transactions/tx_editor_screen.dart';

/// Các nút ghi nhanh, hiện trong bottom sheet khi bấm nút cộng. Có mẫu chi
/// tiêu thì các mẫu đứng trên cùng.
class QuickActionSheet extends ConsumerWidget {
  const QuickActionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider).valueOrNull ?? const [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            if (templates.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TemplateChips(
                  templates: templates,
                  onTap: (t) {
                    // Sheet đóng ngay nên phải mượn context của Navigator để
                    // còn hiện thông báo hoàn tác và mở màn ghi.
                    final host = Navigator.of(context).context;
                    Navigator.pop(context);
                    useTemplate(host, ref, t);
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Divider(),
            ],
            for (final kind in [
              TxKind.expense,
              TxKind.income,
              TxKind.transfer,
            ])
              ListTile(
                leading: IconAvatar(icon: kind.icon),
                title: Text(kind.label),
                subtitle: Text(kind.hint),
                onTap: () {
                  Navigator.pop(context);
                  openTxEditor(context, initialKind: kind);
                },
              ),
            const Divider(),
            ListTile(
              leading: const IconAvatar(icon: Icons.handshake_outlined),
              title: const Text('Vay mượn'),
              subtitle: const Text('Cho mượn, thu nợ, vay, trả nợ'),
              onTap: () {
                Navigator.pop(context);
                openTxEditor(context, initialKind: TxKind.lend);
              },
            ),
            ListTile(
              leading: const IconAvatar(icon: Icons.receipt_long_outlined),
              title: const Text('Ghi nợ'),
              subtitle: const Text('Người khác trả dùm, mình nợ lại'),
              onTap: () {
                Navigator.pop(context);
                openTxEditor(
                  context,
                  initialKind: TxKind.expense,
                  initialPaidByOther: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
