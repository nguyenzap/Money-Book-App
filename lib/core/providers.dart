import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/database.dart';
import 'db/repository.dart';
import 'format/dates.dart';

/// Database dùng chung cho cả app. Được ghi đè ở main() bằng một thể hiện đã
/// mở sẵn, nên ở đây chỉ cần khai báo.
final dbProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('dbProvider phải được override trong main()');
});

final repositoryProvider = Provider<Repository>((ref) {
  return Repository(ref.watch(dbProvider));
});

/// Tất cả ví đang dùng, kèm số dư.
final walletsProvider = StreamProvider<List<WalletWithBalance>>((ref) {
  return ref.watch(repositoryProvider).watchWalletsWithBalance();
});

/// Ví kể cả những ví đã lưu trữ — dùng ở màn quản lý ví.
final allWalletsProvider = StreamProvider<List<WalletWithBalance>>((ref) {
  return ref
      .watch(repositoryProvider)
      .watchWalletsWithBalance(includeArchived: true);
});

final totalAssetsProvider = StreamProvider<int>((ref) {
  return ref.watch(repositoryProvider).watchTotalAssets();
});

final expenseCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(repositoryProvider).watchCategories(flow: 'expense');
});

final incomeCategoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(repositoryProvider).watchCategories(flow: 'income');
});

final peopleProvider = StreamProvider<List<Person>>((ref) {
  return ref.watch(repositoryProvider).watchPeople();
});

/// Giao dịch gần nhất, hiển thị ở màn Tổng quan.
final recentTransactionsProvider = StreamProvider<List<TxView>>((ref) {
  return ref.watch(repositoryProvider).watchTransactions(limit: 20);
});

/// Toàn bộ giao dịch, cho màn danh sách.
final allTransactionsProvider = StreamProvider<List<TxView>>((ref) {
  return ref.watch(repositoryProvider).watchTransactions();
});

/// Tháng đang xem ở màn Thống kê, dạng yyyymm.
final selectedMonthProvider = StateProvider<int>((ref) => currentMonthKey());

final monthTotalsProvider =
    StreamProvider.family<MonthTotals, int>((ref, monthKey) {
  return ref.watch(repositoryProvider).watchMonthTotals(monthKey);
});

/// Tổng thu chi của tháng hiện tại, dùng ở màn Tổng quan.
final currentMonthTotalsProvider = StreamProvider<MonthTotals>((ref) {
  return ref.watch(repositoryProvider).watchMonthTotals(currentMonthKey());
});

/// Sổ nợ: chỉ những người còn dư nợ khác 0.
final debtsProvider = StreamProvider<List<DebtSummary>>((ref) {
  return ref.watch(repositoryProvider).watchDebts();
});

/// Giao dịch của một ví cụ thể.
final walletTransactionsProvider =
    StreamProvider.family<List<TxView>, int>((ref, walletId) {
  return ref.watch(repositoryProvider).watchTransactions(walletId: walletId);
});

/// Giao dịch nợ với một người cụ thể.
final personTransactionsProvider =
    StreamProvider.family<List<TxView>, int>((ref, personId) {
  return ref.watch(repositoryProvider).watchTransactions(personId: personId);
});

final personNetDebtProvider =
    StreamProvider.family<int, int>((ref, personId) {
  return ref.watch(repositoryProvider).watchNetDebt(personId);
});
