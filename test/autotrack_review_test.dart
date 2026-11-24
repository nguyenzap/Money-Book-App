import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/autotrack_repository.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/providers.dart';
import 'package:moneybook/features/autotrack/autotrack_providers.dart';
import 'package:moneybook/features/autotrack/autotrack_service.dart';
import 'package:moneybook/features/autotrack/review_screen.dart';
import 'package:moneybook/features/transactions/tx_editor_screen.dart';

import 'support/fake_autotrack_platform.dart';

/// Chạy thật hàng chờ phân loại và màn sửa giao dịch tự ghi.
void main() {
  late AppDatabase db;
  late Repository repo;
  late AutoTrackRepository auto;
  late FakePlatform platform;
  var minute = 0;

  setUp(() {
    minute = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    auto = AutoTrackRepository(db);
    platform = FakePlatform();
  });

  tearDown(() async => db.close());

  /// Ghi sẵn vài giao dịch tự ghi, chạy ngoài vòng giả lập thời gian.
  Future<void> seed(WidgetTester tester, List<String> contents) async {
    await tester.runAsync(() async {
      final wallet = await repo.insertWallet(
        WalletsCompanion.insert(name: 'BIDV', createdAt: 0, updatedAt: 0),
      );
      await auto.setEnabled(true);
      await auto.bindParser(parserId: 'bidv', packageName: bidvPkg);
      await auto.setDefaultWallet(bidvPkg, wallet);
      for (final c in contents) {
        minute++;
        platform.post(
          'Thời gian giao dịch: 10:${minute.toString().padLeft(2, '0')} 23/11/2026\n'
          'Số tiền GD: -45,000 VND\n'
          'Nội dung giao dịch: $c\n'
          'Mã giao dịch: FT$minute',
          DateTime(2026, 11, 23, 10, minute),
          title: 'Thông báo BIDV',
        );
      }
      await AutoTrackService(repo: repo, auto: auto, platform: platform).sync();
    });
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Widget app(Widget home) => ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      autoTrackPlatformProvider.overrideWithValue(platform),
    ],
    child: MaterialApp(home: home),
  );

  Future<List<Transaction>> autoTxs(WidgetTester tester) async =>
      (await tester.runAsync(
        () => (db.select(db.transactions)
              ..where((t) => t.autoEventId.isNotNull())
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get(),
      ))!;

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('phân loại cả nhóm người nhận bằng một lần chọn', (tester) async {
    await seed(tester, ['NGUYEN VAN B', 'NGUYEN VAN B', 'TRAN THI C']);
    await tester.pumpWidget(app(const ReviewScreen()));
    await settle(tester);

    expect(find.text('Chưa phân loại (3)'), findsOneWidget);
    expect(find.text('NGUYEN VAN B'), findsOneWidget, reason: 'gom một nhóm');

    await tester.tap(find.text('Phân loại cả 2'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Giải trí'));
    await settle(tester);

    expect(find.textContaining('Đã phân loại thêm 1 giao dịch'), findsOneWidget);
    expect(find.text('Chưa phân loại (1)'), findsOneWidget);
    final txs = await autoTxs(tester);
    expect(txs.where((t) => t.categoryId != null), hasLength(2));

    // Hoàn tác.
    await tester.tap(find.text('Hoàn tác'));
    await settle(tester);
    expect(find.text('Chưa phân loại (3)'), findsOneWidget);

    await close(tester);
  });

  testWidgets('đổi danh mục của khoản theo quy tắc: hỏi, "chỉ lần này" giữ '
      'nguyên quy tắc', (tester) async {
    await seed(tester, ['NGUYEN VAN B']);
    final first = (await autoTxs(tester)).single;
    final giaiTri = (await tester.runAsync(
      () => (db.select(db.categories)..where((c) => c.name.equals('Giải trí')))
          .getSingle(),
    ))!;
    await tester.runAsync(
      () => auto.learn(transactionId: first.id, categoryId: giaiTri.id),
    );

    final view = await tester.runAsync(
      () => repo.watchTransactionById(first.id).first,
    );
    await tester.pumpWidget(app(TxEditorScreen(editing: view)));
    await settle(tester);

    final chip = find.widgetWithText(ChoiceChip, 'Mua sắm');
    // Kéo lên đầu màn: để dưới đáy thì nút "Lưu thay đổi" nằm đè lên.
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await settle(tester);
    await tester.tap(find.text('Lưu thay đổi'));
    await settle(tester);

    expect(find.text('Đổi danh mục cho người nhận này?'), findsOneWidget);
    await tester.tap(find.text('Chỉ giao dịch này'));
    await settle(tester);

    final rules = (await tester.runAsync(() => auto.watchRules().first))!;
    expect(rules.single.categoryName, 'Giải trí', reason: 'quy tắc giữ nguyên');
    final tx = (await autoTxs(tester)).single;
    expect(tx.categoryId, isNot(giaiTri.id));
    expect(tx.needsReview, isFalse);

    await close(tester);
  });
}
