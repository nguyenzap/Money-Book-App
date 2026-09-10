import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/backup_screen.dart';
import '../budgets/budget_screen.dart';
import '../funds/fund_screen.dart';
import '../categories/category_list_screen.dart';
import '../people/person_list_screen.dart';
import '../wallets/wallet_list_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const _SectionLabel('Dữ liệu'),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Ví'),
            subtitle: const Text('Thêm, sửa, lưu trữ nguồn tiền'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletListScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Danh mục'),
            subtitle: const Text('Loại giao dịch do bạn tự đặt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryListScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Danh bạ'),
            subtitle: const Text('Những người bạn hay vay mượn'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PersonListScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('Quỹ'),
            subtitle: const Text('Tiền để dành cho khoản đã biết trước'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FundScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: const Text('Ngân sách'),
            subtitle: const Text('Hạn mức chi tiêu theo danh mục'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
          const Divider(),
          const _SectionLabel('An toàn dữ liệu'),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Sao lưu'),
            subtitle: const Text('Xuất ra file, khôi phục khi cần'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupScreen()),
            ),
          ),
          const Divider(),
          const _SectionLabel('Về ứng dụng'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Quản Lý Chi Tiêu'),
            subtitle: Text(
              'Toàn bộ dữ liệu nằm trong máy bạn. Không tài khoản, '
              'không internet, không ai xem được.',
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
