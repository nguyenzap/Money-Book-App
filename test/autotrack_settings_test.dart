import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/autotrack_repository.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/providers.dart';
import 'package:moneybook/features/autotrack/autotrack_providers.dart';
import 'package:moneybook/features/autotrack/autotrack_settings_screen.dart';

import 'support/fake_autotrack_platform.dart';

/// Chạy thật màn cài đặt: bật tính năng, gắn BIDV với app trên máy, và danh
/// sách gói gửi sang Android phải đổi theo.
void main() {
  late AppDatabase db;
  late FakePlatform platform;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    platform = FakePlatform();
  });

  tearDown(() async => db.close());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bật tính năng rồi dùng app BIDV có sẵn trên máy', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          autoTrackPlatformProvider.overrideWithValue(platform),
        ],
        child: const MaterialApp(home: AutoTrackSettingsScreen()),
      ),
    );
    await settle(tester);

    expect(find.text('BIDV SmartBanking'), findsNothing,
        reason: 'tắt thì chưa hiện ngân hàng');
    await tester.tap(find.text('Ghi từ thông báo ngân hàng'));
    await settle(tester);

    expect(find.text('BIDV SmartBanking'), findsOneWidget);
    expect(find.text('Eximbank'), findsOneWidget);
    expect(find.text('Đã có quyền đọc thông báo'), findsOneWidget);

    // Máy giả chỉ cài BIDV nên chỉ BIDV có nút dùng app sẵn có.
    expect(find.text('Dùng app trên máy'), findsOneWidget);
    await tester.tap(find.text('Dùng app trên máy'));
    await settle(tester);

    final app = await tester.runAsync(
      () => AutoTrackRepository(db).trackedApp(bidvPkg),
    );
    expect(app?.parserId, 'bidv');
    expect(platform.watched, [bidvPkg]);
    expect(find.text('Ví nhận giao dịch'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('chưa có quyền đọc thông báo thì hiện cảnh báo đỏ có nút Mở', (
    tester,
  ) async {
    platform.listenerEnabled = false;
    await tester.runAsync(() => AutoTrackRepository(db).setEnabled(true));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          autoTrackPlatformProvider.overrideWithValue(platform),
        ],
        child: const MaterialApp(home: AutoTrackSettingsScreen()),
      ),
    );
    await settle(tester);

    expect(find.text('Chưa có quyền đọc thông báo'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Mở'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
