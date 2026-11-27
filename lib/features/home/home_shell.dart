import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../autotrack/autotrack_providers.dart';

import '../debts/debt_book_screen.dart';
import '../stats/stats_screen.dart';
import '../transactions/tx_list_screen.dart';
import 'dashboard_screen.dart';
import 'quick_action_sheet.dart';

/// Khung điều hướng chính: 4 tab và một nút cộng ở giữa.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  // Mở lại app vào sáng hôm sau thì mọi con số "hôm nay" phải sang ngày mới
  // ngay, không đợi Timer — Timer có thể đứng suốt lúc máy ngủ.
  late final _lifecycle = AppLifecycleListener(
    onResume: () {
      ref.read(todayProvider.notifier).refresh();
      _syncAutoTrack();
    },
  );

  StreamSubscription<void>? _newNotifications;

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _syncAutoTrack();
    // Có thông báo ngân hàng mới lúc app đang mở thì ghi ngay.
    _newNotifications = ref
        .read(autoTrackPlatformProvider)
        .newItems
        .listen((_) => _syncAutoTrack(), onError: (_) {});
  }

  @override
  void dispose() {
    _newNotifications?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Lấy thông báo ngân hàng đã nhận lúc app đóng và ghi thành giao dịch.
  Future<void> _syncAutoTrack() async {
    try {
      final service = ref.read(autoTrackServiceProvider);
      final report = await service.sync();
      if (!mounted) return;
      // Kiểm tra lại quyền, số dư, mẫu thông báo sau mỗi lần đồng bộ.
      ref.read(autoTrackHealthTickProvider.notifier).state++;
      if (report.created == 0) return;
      showSnack(context, 'Đã tự ghi ${report.created} giao dịch từ ngân hàng');
    } catch (e) {
      // Không có phần Android (chạy test, máy không hỗ trợ): bỏ qua, app
      // vẫn dùng bình thường.
      debugPrint('autotrack sync: $e');
    }
  }

  static const _tabs = [
    DashboardScreen(),
    TxListScreen(),
    DebtBookScreen(),
    StatsScreen(),
  ];

  void _openQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      // Sheet cao hơn 9/16 màn hình (mặc định) khi có mẫu chi tiêu, nên cho
      // nó tự cao theo nội dung và cuộn được trên máy màn nhỏ.
      isScrollControlled: true,
      useSafeArea: true,
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
