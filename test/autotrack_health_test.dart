import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/autotrack_repository.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/features/autotrack/autotrack_health.dart';
import 'package:moneybook/features/autotrack/autotrack_service.dart';

import 'support/fake_autotrack_platform.dart';

/// Những thứ có thể hỏng mà không ai thấy: lệch số dư, mất quyền, ngân hàng
/// đổi mẫu, im lặng quá lâu.
void main() {
  late AppDatabase db;
  late Repository repo;
  late AutoTrackRepository auto;
  late FakePlatform platform;
  late AutoTrackService service;
  late int bidv;
  var now = DateTime(2026, 11, 23, 12);
  var ref = 0;

  String bidvText({
    required String amount,
    required String balance,
    String time = '10:00 23/11/2026',
  }) {
    ref++;
    return 'Thời gian giao dịch: $time\n'
        'Số tiền GD: $amount\n'
        'Số dư cuối: $balance\n'
        'Nội dung giao dịch: NGUYEN VAN B\n'
        'Mã giao dịch: FT$ref';
  }

  Future<void> receive(String text, DateTime at) async {
    platform.post(text, at, title: 'Thông báo BIDV');
    await service.sync();
  }

  Future<AutoTrackHealth> check() => checkAutoTrackHealth(
    repo: repo,
    auto: auto,
    platform: platform,
    now: now,
  );

  setUp(() async {
    now = DateTime(2026, 11, 23, 12);
    ref = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    auto = AutoTrackRepository(db);
    platform = FakePlatform();
    bidv = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'BIDV',
        initialBalance: const Value(3000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    await auto.setEnabled(true);
    await auto.bindParser(parserId: 'bidv', packageName: bidvPkg);
    await auto.setDefaultWallet(bidvPkg, bidv);
    service = AutoTrackService(
      repo: repo,
      auto: auto,
      platform: platform,
      clock: () => now,
    );
  });

  tearDown(() => db.close());

  test('tắt tính năng thì không cảnh báo gì', () async {
    await auto.setEnabled(false);
    platform.listenerEnabled = false;
    final h = await check();
    expect(h.enabled, isFalse);
    expect(h.isHealthy, isTrue);
  });

  group('số dư', () {
    test('khớp thì không cảnh báo', () async {
      await receive(
        bidvText(amount: '-80,000 VND', balance: '2,920,000 VND'),
        DateTime(2026, 11, 23, 10),
      );
      expect((await check()).mismatches, isEmpty);
    });

    test('lệch thì báo đúng chênh lệch', () async {
      // App nghĩ còn 2.920.000, ngân hàng nói 2.900.000: có khoản 20k bị lọt.
      await receive(
        bidvText(amount: '-80,000 VND', balance: '2,900,000 VND'),
        DateTime(2026, 11, 23, 10),
      );
      final m = (await check()).mismatches.single;
      expect(m.walletName, 'BIDV');
      expect(m.bankBalance, 2900000);
      expect(m.appBalance, 2920000);
      expect(m.diff, -20000);
    });

    test('khoản ghi tay SAU thông báo không làm lệch giả', () async {
      await receive(
        bidvText(amount: '-80,000 VND', balance: '2,920,000 VND'),
        DateTime(2026, 11, 23, 10),
      );
      await repo.addTransaction(
        kind: TxKind.expense,
        amount: 15000,
        occurredAt: DateTime(2026, 11, 23, 11),
        walletFromId: bidv,
      );
      expect((await check()).mismatches, isEmpty);
    });

    test('chỉ so với thông báo mới nhất', () async {
      await receive(
        bidvText(amount: '-80,000 VND', balance: '9,999,999 VND'),
        DateTime(2026, 11, 23, 9),
      );
      await receive(
        bidvText(
          amount: '-20,000 VND',
          balance: '2,900,000 VND',
          time: '10:00 23/11/2026',
        ),
        DateTime(2026, 11, 23, 10),
      );
      expect((await check()).mismatches, isEmpty,
          reason: 'tin cũ lệch nhưng tin mới khớp');
    });

    test('ẩn đi thì thôi, có thông báo mới lệch thì báo lại', () async {
      await receive(
        bidvText(amount: '-80,000 VND', balance: '2,900,000 VND'),
        DateTime(2026, 11, 23, 10),
      );
      await dismissBalanceMismatch(auto, (await check()).mismatches.single);
      expect((await check()).mismatches, isEmpty);

      await receive(
        bidvText(
          amount: '-10,000 VND',
          balance: '2,000,000 VND',
          time: '11:00 23/11/2026',
        ),
        DateTime(2026, 11, 23, 11),
      );
      expect((await check()).mismatches, hasLength(1));
    });

    test('xoá giao dịch tự ghi thì không lấy tin đó để so', () async {
      await receive(
        bidvText(amount: '-80,000 VND', balance: '2,900,000 VND'),
        DateTime(2026, 11, 23, 10),
      );
      final tx = (await (db.select(db.transactions)
                ..where((t) => t.autoEventId.isNotNull()))
              .get())
          .single;
      await repo.softDeleteTransaction(tx.id);
      expect((await check()).mismatches, isEmpty);
    });
  });

  test('mất quyền đọc thông báo', () async {
    platform.listenerEnabled = false;
    final h = await check();
    expect(h.permissionGranted, isFalse);
    expect(h.isHealthy, isFalse);
  });

  test('tin có số tiền mà không đọc được: nghi ngân hàng đổi mẫu', () async {
    // BIDV đổi nhãn "Số tiền GD" thành "Số tiền giao dịch".
    await receive(
      'Thời gian giao dịch: 10:00 23/11/2026\n'
      'Số tiền giao dịch: -80,000 VND\n'
      'Số dư cuối: 2,920,000 VND',
      DateTime(2026, 11, 23, 10),
    );
    // OTP thì không tính.
    platform.post(
      'Ma OTP cua Quy khach la 123456',
      DateTime(2026, 11, 23, 10, 5),
      title: 'BIDV',
    );
    await service.sync();

    final f = (await check()).formatChanges.single;
    expect(f.bankName, 'BIDV SmartBanking');
    expect(f.count, 1);
  });

  test('im lặng quá 3 ngày thì nhắc, ẩn được', () async {
    await receive(
      bidvText(amount: '-80,000 VND', balance: '2,920,000 VND'),
      DateTime(2026, 11, 23, 10),
    );
    expect((await check()).silentSince, isNull);

    now = DateTime(2026, 11, 27, 12);
    final h = await check();
    expect(h.silentSince, DateTime(2026, 11, 23, 10));

    await dismissSilence(auto, h.silentSince!);
    expect((await check()).silentSince, isNull);
  });

  test('mất quyền thì không nhắc im lặng (đã có cảnh báo mất quyền)', () async {
    await receive(
      bidvText(amount: '-80,000 VND', balance: '2,920,000 VND'),
      DateTime(2026, 11, 23, 10),
    );
    now = DateTime(2026, 11, 27, 12);
    platform.listenerEnabled = false;
    expect((await check()).silentSince, isNull);
  });
}
