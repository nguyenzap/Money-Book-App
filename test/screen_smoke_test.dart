import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/core/format/dates.dart';
import 'package:moneybook/core/providers.dart';
import 'package:moneybook/features/budgets/budget_screen.dart';
import 'package:moneybook/features/funds/fund_screen.dart';
import 'package:moneybook/features/home/dashboard_screen.dart';
import 'package:moneybook/features/home/quick_action_sheet.dart';
import 'package:moneybook/features/stats/category_detail_screen.dart';
import 'package:moneybook/features/stats/stats_screen.dart';
import 'package:moneybook/features/templates/template_screen.dart';
import 'package:moneybook/features/budgets/budget_editor_sheet.dart';
import 'package:moneybook/features/funds/fund_transfer_sheet.dart';
import 'package:moneybook/features/funds/fund_editor_sheet.dart';
import 'package:moneybook/features/templates/template_editor_sheet.dart';

/// Lưới an toàn cho việc tách file: mỗi màn hình lớn (và các bảng trượt của
/// nó) dựng được trên dữ liệu thật và hiện đúng vài nội dung then chốt.
///
/// Chỉ kiểm tra "dựng được và có chữ này", không kiểm tra bố cục.
void main() {
  late AppDatabase db;
  late Repository repo;
  late int wallet;
  late int food;
  late int fund;
  final now = DateTime.now();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    wallet = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'Ví thử',
        initialBalance: const Value(5000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    food = (await repo.watchCategories(flow: CategoryFlow.expense).first)
        .firstWhere((c) => c.name == 'Ăn uống')
        .id;
    final nam = await repo.insertPerson(
      PeopleCompanion.insert(name: 'Nam', createdAt: 0, updatedAt: 0),
    );
    await repo.addTransaction(
      kind: TxKind.expense,
      amount: 120000,
      occurredAt: now,
      walletFromId: wallet,
      categoryId: food,
      note: 'Bún chả',
    );
    await repo.addSplitBill(
      walletFromId: wallet,
      myShare: 50000,
      sharesByPerson: {nam: 50000},
      occurredAt: now,
      categoryId: food,
    );
    await repo.setBudget(categoryId: food, limitAmount: 3000000);
    fund = await repo.insertFund(
      FundsCompanion.insert(
        name: 'Quỹ Tết',
        walletId: wallet,
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    await repo.depositToFund(
      fundId: fund,
      walletFromId: wallet,
      walletToId: wallet,
      amount: 1000000,
      occurredAt: now,
    );
    await repo.insertTemplate(
      note: 'Cà phê',
      amount: 25000,
      walletId: wallet,
      categoryId: food,
    );
  });

  tearDown(() async => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: MaterialApp(home: screen),
      ),
    );
    await settle(tester);
  }

  /// Dọn cây widget để Timer của todayProvider bị huỷ trước khi test kết thúc.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  /// Mở một bảng trượt bằng một nút tạm, như người dùng bấm.
  Widget launcher(Future<void> Function(BuildContext, WidgetRef) open) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, _) => Center(
          child: TextButton(
            onPressed: () => open(context, ref),
            child: const Text('Mở'),
          ),
        ),
      ),
    );
  }

  Future<void> tapOpen(WidgetTester tester) async {
    await tester.tap(find.text('Mở'));
    await settle(tester);
  }

  Future<FundProgress> fundProgress() async =>
      (await repo.watchFunds().first).single;

  testWidgets('Tổng quan', (tester) async {
    await pumpScreen(tester, const DashboardScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Cà phê'), findsWidgets);
    expect(find.text(monthKeyLabel(monthKeyOf(now))), findsOneWidget);
    await close(tester);
  });

  testWidgets('Thống kê', (tester) async {
    await pumpScreen(tester, const StatsScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Ăn uống'), findsWidgets);
    await close(tester);
  });

  testWidgets('Ngân sách và bảng sửa hạn mức', (tester) async {
    await pumpScreen(tester, const BudgetScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Ăn uống'), findsWidgets);
    await close(tester);

    await pumpScreen(
      tester,
      launcher((context, ref) async {
        final b = (await repo.watchBudgets(monthKeyOf(now)).first).single;
        if (context.mounted) await showBudgetEditor(context, editing: b);
      }),
    );
    await tapOpen(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Ăn uống'), findsWidgets);
    await close(tester);
  });

  testWidgets('Quỹ, bảng nạp quỹ và bảng sửa quỹ', (tester) async {
    await pumpScreen(tester, const FundScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Quỹ Tết'), findsWidgets);
    await close(tester);

    final progress = await tester.runAsync(fundProgress);
    await pumpScreen(
      tester,
      launcher(
        (context, _) => showFundTransferSheet(context, progress: progress!),
      ),
    );
    await tapOpen(tester);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Quỹ Tết'), findsWidgets);
    await close(tester);

    await pumpScreen(
      tester,
      launcher((context, _) => showFundEditor(context, editing: progress)),
    );
    await tapOpen(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Quỹ Tết'), findsWidgets);
    await close(tester);
  });

  testWidgets('Chi tiết danh mục kèm biểu đồ', (tester) async {
    await pumpScreen(
      tester,
      CategoryDetailScreen(
        categoryId: food,
        name: 'Ăn uống',
        monthKey: monthKeyOf(now),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Bún chả'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    await close(tester);
  });

  testWidgets('Mẫu chi tiêu và bảng sửa mẫu', (tester) async {
    await pumpScreen(tester, const TemplateScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('Cà phê'), findsWidgets);
    await close(tester);

    final template = await tester.runAsync(
      () async => (await repo.watchTemplates().first).single,
    );
    await pumpScreen(
      tester,
      launcher(
        (context, _) => showTemplateEditor(context, editing: template),
      ),
    );
    await tapOpen(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Cà phê'), findsWidgets);
    await close(tester);
  });

  testWidgets('Bảng ghi nhanh có mục Ghi nợ', (tester) async {
    await pumpScreen(
      tester,
      launcher(
        (context, _) => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const QuickActionSheet(),
        ),
      ),
    );
    await tapOpen(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Vay mượn'), findsOneWidget);
    expect(find.text('Ghi nợ'), findsOneWidget);
    expect(find.text('Người khác trả dùm, mình nợ lại'), findsOneWidget);
    await close(tester);
  });
}
