import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/database.dart';
import 'db/repository.dart';
import 'domain/free_money.dart';
import 'format/dates.dart';

/// Database dùng chung cho cả app. Được ghi đè ở main() bằng một thể hiện đã
/// mở sẵn, nên ở đây chỉ cần khai báo.
final dbProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('dbProvider phải được override trong main()');
});

final repositoryProvider = Provider<Repository>((ref) {
  return Repository(ref.watch(dbProvider));
});

/// Ngày hôm nay (0 giờ, giờ địa phương), tự đổi khi qua nửa đêm.
///
/// Mọi thứ phụ thuộc "hôm nay" phải xem provider này thay vì gọi thẳng
/// `DateTime.now()` lúc dựng provider: app để chạy nền qua đêm thì provider
/// không bị dựng lại, và sáng hôm sau vẫn tính ngân sách theo ngày hôm qua.
class TodayNotifier extends StateNotifier<DateTime> {
  TodayNotifier() : super(_today()) {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }

  late final Timer _timer;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Gọi khi app quay lại từ nền — đồng hồ của Timer có thể đứng khi máy ngủ.
  void refresh() {
    final today = _today();
    if (today != state) state = today;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

final todayProvider = StateNotifierProvider<TodayNotifier, DateTime>(
  (ref) => TodayNotifier(),
);

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
  final month = monthKeyOf(ref.watch(todayProvider));
  return ref.watch(repositoryProvider).watchMonthTotals(month);
});

/// Sổ nợ: chỉ những người còn dư nợ khác 0.
final debtsProvider = StreamProvider<List<DebtSummary>>((ref) {
  return ref.watch(repositoryProvider).watchDebts();
});

/// Giao dịch của một ví cụ thể.
final walletTransactionsProvider = StreamProvider.family<List<TxView>, int>((
  ref,
  walletId,
) {
  return ref.watch(repositoryProvider).watchTransactions(walletId: walletId);
});

/// Giao dịch nợ với một người cụ thể.
final personTransactionsProvider = StreamProvider.family<List<TxView>, int>((
  ref,
  personId,
) {
  return ref.watch(repositoryProvider).watchTransactions(personId: personId);
});

final personNetDebtProvider = StreamProvider.family<int, int>((ref, personId) {
  return ref.watch(repositoryProvider).watchNetDebt(personId);
});

final _rawBudgetsProvider = StreamProvider.family<List<BudgetProgress>, int>((
  ref,
  monthKey,
) {
  final today = ref.watch(todayProvider);
  return ref.watch(repositoryProvider).watchBudgets(monthKey, now: today);
});

/// Tiến độ các hạn mức ngân sách của một tháng.
///
/// Với tháng hiện tại, phần còn tiêu được bị chặn bởi tiền thật đang có (xem
/// [capBudgetsByCash]). Tháng đã qua thì không, vì số dư ví bây giờ chẳng nói
/// gì về tháng đó.
final budgetsProvider = Provider.family<AsyncValue<List<BudgetProgress>>, int>((
  ref,
  monthKey,
) {
  final budgets = ref.watch(_rawBudgetsProvider(monthKey));
  if (monthKey != monthKeyOf(ref.watch(todayProvider))) return budgets;

  final cash = ref.watch(spendableAssetsProvider).valueOrNull;
  if (cash == null) return budgets;
  return budgets.whenData((list) => capBudgetsByCash(list, cash));
});

/// Ngân sách tháng hiện tại, dùng ở màn Tổng quan.
final currentBudgetsProvider = Provider<AsyncValue<List<BudgetProgress>>>((
  ref,
) {
  final month = monthKeyOf(ref.watch(todayProvider));
  return ref.watch(budgetsProvider(month));
});

/// Số tiền đã chi hôm nay, gom theo danh mục.
final todaySpendingProvider = StreamProvider<Map<int, int>>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(repositoryProvider)
      .watchSpentByCategoryOnDay(dayKeyOf(today));
});

/// Tổng tiền đang nằm trong các quỹ.
final totalInFundsProvider = StreamProvider<int>((ref) {
  return ref.watch(repositoryProvider).watchTotalInFunds();
});

/// Tổng nợ mình đang phải trả người khác.
final totalOwedProvider = StreamProvider<int>((ref) {
  return ref.watch(repositoryProvider).watchTotalOwed();
});

/// Tiền thực sự tiêu được: tổng ví trừ đi phần đã hứa cho các quỹ và nợ phải
/// trả.
final spendableAssetsProvider = StreamProvider<int>((ref) {
  return ref.watch(repositoryProvider).watchSpendableAssets();
});

/// Danh sách quỹ kèm số đã để dành.
final fundsProvider = StreamProvider<List<FundProgress>>((ref) {
  return ref.watch(repositoryProvider).watchFunds();
});

/// Mẫu chi tiêu để ghi một chạm.
final templatesProvider = StreamProvider<List<TemplateView>>((ref) {
  return ref.watch(repositoryProvider).watchTemplates();
});

/// Người dùng có đang cho hiện tiền quỹ trong tổng tài sản không.
///
/// Mặc định là không: tiền quỹ đã có chỗ đến rồi, gộp vào tổng dễ làm mình
/// tưởng còn nhiều tiền hơn thực tế.
final showFundsInTotalProvider = StateProvider<bool>((ref) => false);

/// Hôm nay đã tiêu bao nhiêu ngoài các ngân sách.
final spentOutsideBudgetsTodayProvider = StreamProvider<int>((ref) {
  final today = ref.watch(todayProvider);
  return ref
      .watch(repositoryProvider)
      .watchSpentOutsideBudgetsOnDay(dayKeyOf(today), monthKeyOf(today));
});

/// Tiền tự do: tiêu được bao nhiêu mà không đụng tới tiền đã giữ cho ngân sách.
final freeMoneyProvider = Provider<AsyncValue<FreeMoney>>((ref) {
  final today = ref.watch(todayProvider);
  final spendable = ref.watch(spendableAssetsProvider);
  final budgets = ref.watch(currentBudgetsProvider);
  final debts = ref.watch(debtsProvider);
  final spentToday = ref.watch(spentOutsideBudgetsTodayProvider);

  if (spendable.hasError) {
    return AsyncError(spendable.error!, spendable.stackTrace!);
  }
  if (!spendable.hasValue || !budgets.hasValue || !debts.hasValue) {
    return const AsyncLoading();
  }
  return AsyncData(
    FreeMoney.from(
      spendable: spendable.value!,
      budgets: budgets.value!,
      debts: debts.value!,
      daysRemaining: daysRemainingIn(monthKeyOf(today), now: today),
      spentToday: spentToday.valueOrNull ?? 0,
    ),
  );
});
