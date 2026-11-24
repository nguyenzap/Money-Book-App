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
import 'package:moneybook/features/autotrack/health_banners.dart';

import 'support/fake_autotrack_platform.dart';

/// Cảnh báo trên màn Tổng quan.
void main() {
  late AppDatabase db;
  late FakePlatform platform;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    platform = FakePlatform();
  });

  tearDown(() async => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          autoTrackPlatformProvider.overrideWithValue(platform),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: AutoTrackHealthBanners())),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('mọi thứ ổn thì không hiện gì', (tester) async {
    await tester.runAsync(() => AutoTrackRepository(db).setEnabled(true));
    await pump(tester);
    expect(find.byType(Card), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('lệch số dư: hiện số, Bỏ qua thì ẩn', (tester) async {
    await tester.runAsync(() async {
      final repo = Repository(db);
      final auto = AutoTrackRepository(db);
      final wallet = await repo.insertWallet(
        WalletsCompanion.insert(
          name: 'BIDV',
          initialBalance: const Value(3000000),
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      await auto.setEnabled(true);
      await auto.bindParser(parserId: 'bidv', packageName: bidvPkg);
      await auto.setDefaultWallet(bidvPkg, wallet);
      platform.post(
        'Thời gian giao dịch: 10:00 23/11/2026\n'
        'Số tiền GD: -80,000 VND\n'
        'Số dư cuối: 2,900,000 VND\n'
        'Mã giao dịch: FT1',
        DateTime(2026, 11, 23, 10),
        title: 'Thông báo BIDV',
      );
      await AutoTrackService(repo: repo, auto: auto, platform: platform).sync();
    });
    await pump(tester);

    expect(find.textContaining('BIDV lệch'), findsOneWidget);
    expect(find.textContaining('2.900.000'), findsOneWidget);
    expect(find.textContaining('2.920.000'), findsOneWidget);

    await tester.tap(find.text('Bỏ qua'));
    await settle(tester);
    expect(find.textContaining('BIDV lệch'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('mất quyền: cảnh báo đỏ có nút Bật lại', (tester) async {
    platform.listenerEnabled = false;
    await tester.runAsync(() => AutoTrackRepository(db).setEnabled(true));
    await pump(tester);
    expect(find.text('Mất quyền đọc thông báo'), findsOneWidget);
    expect(find.text('Bật lại'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
