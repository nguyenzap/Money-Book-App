import 'package:flutter/material.dart';

import '../debts/debt_book_screen.dart';
import '../stats/stats_screen.dart';
import '../transactions/tx_list_screen.dart';
import 'dashboard_screen.dart';

/// Khung điều hướng chính: 4 tab và một nút cộng ở giữa.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    DashboardScreen(),
    TxListScreen(),
    DebtBookScreen(),
    StatsScreen(),
  ];

  void _openQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const QuickActionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack giữ nguyên vị trí cuộn và trạng thái của từng tab khi
      // chuyển qua lại.
      body: IndexedStack(index: _index, children: _tabs),
      floatingActionButton: FloatingActionButton(
        onPressed: _openQuickActions,
        tooltip: 'Ghi giao dịch',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Giao dịch',
          ),
          NavigationDestination(
            icon: Icon(Icons.handshake_outlined),
            selectedIcon: Icon(Icons.handshake),
            label: 'Sổ nợ',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
        ],
      ),
    );
  }
}
