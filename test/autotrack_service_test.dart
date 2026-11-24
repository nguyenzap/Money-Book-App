import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/autotrack_repository.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/autotrack/parsed_txn.dart';
import 'package:moneybook/core/domain/autotrack/parsers/bidv_parser.dart';
import 'package:moneybook/core/domain/autotrack/parsers/notification_parser.dart';
import 'package:moneybook/core/domain/autotrack/parsers/registry.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/features/autotrack/autotrack_service.dart';

import 'support/fake_autotrack_platform.dart';

String bidv({
  String amount = '-80,000 VND',
  String time = '18:57 21/11/2026',
  String balance = '2,702,202 VND',
  String content = 'HIGHLANDS COFFEE',
  String account = '1234567890',
  String ref = 'FT001',
}) =>
    'BIDV xin thông báo tới Quý khách\n'
    'Thời gian giao dịch: $time\n'
    'Tài khoản thanh toán: $account\n'
    'Số tiền GD: $amount\n'
    'Số dư cuối: $balance\n'
    'Nội dung giao dịch: $content\n'
    'Mã giao dịch: $ref';

/// Parser giả không đọc được gì, để thử việc đọc lại sau khi cập nhật.
class BlindBidv extends BidvParser {
  const BlindBidv();
  @override
  ParseResult parse(String title, String text) =>
      const ParseIgnored('bản cũ chưa biết mẫu này');
}

/// Cùng parser BIDV nhưng phiên bản mới hơn.
class BidvV2 extends BidvParser {
  const BidvV2();
  @override
  int get version => super.version + 1;
}

void main() {
  late AppDatabase db;
  late Repository repo;
  late AutoTrackRepository auto;
  late FakePlatform platform;
  late AutoTrackService service;
  late int bidvWallet;
  final at = DateTime(2026, 11, 21, 18, 58);

  AutoTrackService makeService(List<NotificationParser> parsers) =>
      AutoTrackService(
        repo: repo,
        auto: auto,
        platform: platform,
        parsers: parsers,
        clock: () => DateTime(2026, 11, 22),
      );

  Future<List<Transaction>> autoTxs() =>
      (db.select(db.transactions)..where((t) => t.autoEventId.isNotNull()))
          .get();

  Future<List<NotificationEvent>> events() =>
      db.select(db.notificationEvents).get();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    auto = AutoTrackRepository(db);
    platform = FakePlatform();
    await db.customStatement('PRAGMA foreign_keys = ON');
    await db.delete(db.wallets).go();
    bidvWallet = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'BIDV',
        initialBalance: const Value(3000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    await auto.setEnabled(true);
    await auto.bindParser(parserId: 'bidv', packageName: bidvPkg);
    await auto.setDefaultWallet(bidvPkg, bidvWallet);
    service = makeService(kParsers);
  });

  tearDown(() => db.close());

  test('khoản chi BIDV thành giao dịch chi, trừ đúng ví', () async {
    platform.post(bidv(), at);
    final report = await service.sync();

    expect(report.created, 1);
    final txs = await autoTxs();
    expect(txs, hasLength(1));
    final tx = txs.single;
    expect(tx.kind, TxKind.expense);
    expect(tx.amount, 80000);
    expect(tx.walletFromId, bidvWallet);
    expect(tx.walletToId, isNull);
    final cat = await (db.select(db.categories)
          ..where((c) => c.id.equals(tx.categoryId!)))
        .getSingle();
    expect(cat.name, 'Ăn uống', reason: 'đoán từ khoá HIGHLANDS / COFFEE');
    expect(tx.note, 'HIGHLANDS COFFEE');
    expect(tx.needsReview, isTrue);
    expect(
      DateTime.fromMillisecondsSinceEpoch(tx.occurredAt),
      DateTime(2026, 11, 21, 18, 57),
      reason: 'lấy giờ in trong tin, không phải giờ tin đến',
    );
    expect(tx.dayKey, 20261121);

    final wallets = await repo.watchWalletsWithBalance().first;
    expect(wallets.single.balance, 3000000 - 80000);
    expect((await repo.watchMonthTotals(202611).first).expense, 80000,
        reason: 'thống kê đếm như khoản chi thường');
  });

  test('khoản nhận thành thu nhập vào ví', () async {
    platform.post(bidv(amount: '+500,000 VND', ref: 'FT002'), at);
    await service.sync();
    final tx = (await autoTxs()).single;
    expect(tx.kind, TxKind.income);
    expect(tx.walletToId, bidvWallet);
    expect(tx.walletFromId, isNull);
  });

  test('hộp thư Android chỉ được xoá sau khi lưu xong', () async {
    platform.post(bidv(), at);
    await service.sync();
    expect(platform.inbox, isEmpty);
    expect(await events(), hasLength(1));
  });

  test('cùng một tin đến hai lần chỉ ghi một lần', () async {
    platform.post(bidv(), at);
    platform.post(bidv(), at);
    await service.sync();
    platform.post(bidv(), at); // lần sync sau lại thấy
    await service.sync();
    expect(await events(), hasLength(1));
    expect(await autoTxs(), hasLength(1));
  });

  test('cùng giao dịch nhưng tin đăng lại khác chữ: không ghi kép', () async {
    platform.post(bidv(), at);
    platform.post(
      bidv().replaceFirst('Số dư cuối', 'Kênh: Mobile\nSố dư cuối'),
      at.add(const Duration(minutes: 1)),
    );
    final report = await service.sync();
    expect(report.created, 1);
    expect(report.duplicates, 1);
    expect(await autoTxs(), hasLength(1));
  });

  test('hai khoản khác nhau cùng số tiền đều được ghi', () async {
    platform.post(bidv(ref: 'FT001'), at);
    platform.post(
      bidv(ref: 'FT009', balance: '2,622,202 VND', time: '19:10 21/11/2026'),
      at.add(const Duration(minutes: 12)),
    );
    await service.sync();
    expect(await autoTxs(), hasLength(2));
  });

  test('OTP không sinh giao dịch, giữ lại dạng unmatched', () async {
    platform.post('Ma OTP cua Quy khach la 123456', at, title: 'BIDV');
    final report = await service.sync();
    expect(report.unmatched, 1);
    expect(await autoTxs(), isEmpty);
    expect((await events()).single.status, EventStatus.unmatched.name);
  });

  test('chưa chọn ví thì chờ; chọn ví xong lần sau tự ghi', () async {
    await auto.setDefaultWallet(bidvPkg, null);
    platform.post(bidv(), at);
    expect((await service.sync()).unmapped, 1);
    expect(await autoTxs(), isEmpty);

    await auto.setDefaultWallet(bidvPkg, bidvWallet);
    expect((await service.sync()).created, 1);
    expect(await autoTxs(), hasLength(1));
  });

  test('ví đã lưu trữ coi như chưa chọn ví', () async {
    await (db.update(db.wallets)..where((w) => w.id.equals(bidvWallet)))
        .write(const WalletsCompanion(isArchived: Value(true)));
    platform.post(bidv(), at);
    expect((await service.sync()).unmapped, 1);
  });

  test('số tài khoản có ví riêng thì vào ví đó', () async {
    final second = await repo.insertWallet(
      WalletsCompanion.insert(name: 'BIDV phụ', createdAt: 0, updatedAt: 0),
    );
    await auto.setAccountWallet(bidvPkg, '7890', second);
    platform.post(bidv(account: '1234567890'), at);
    platform.post(bidv(account: '5555', ref: 'FT003'), at);
    await service.sync();
    expect((await autoTxs()).map((t) => t.walletFromId),
        unorderedEquals([second, bidvWallet]),
        reason: '…7890 vào ví riêng, tài khoản khác vào ví mặc định');
  });

  test('app đang ghi mẫu chỉ lưu chữ, không ghi giao dịch', () async {
    const pkg = 'vn.newbank';
    await auto.startCapture(
      packageName: pkg,
      until: DateTime(2026, 11, 29),
    );
    platform.post('Tai khoan -50,000 VND', at, pkg: pkg);
    await service.sync();
    expect(await autoTxs(), isEmpty);
    expect(
      (await events()).single.status,
      EventStatus.captured.name,
    );
  });

  test('tin ghi mẫu của BIDV được đọc thật khi gắn parser', () async {
    await auto.removeTrackedApp(bidvPkg);
    await auto.startCapture(packageName: bidvPkg, until: DateTime(2026, 11, 29));
    platform.post(bidv(), at);
    await service.sync();
    expect(await autoTxs(), isEmpty);

    await auto.bindParser(parserId: 'bidv', packageName: bidvPkg);
    await auto.setDefaultWallet(bidvPkg, bidvWallet);
    await service.sync();
    expect(await autoTxs(), hasLength(1));
  });

  test('cập nhật parser thì tin chưa đọc được trước đó được đọc lại', () async {
    final old = makeService(const [BlindBidv()]);
    platform.post(bidv(), at);
    expect((await old.sync()).unmatched, 1);
    expect((await old.sync()).unmatched, 0,
        reason: 'cùng phiên bản thì không đọc lại mãi');

    final updated = makeService(const [BidvV2()]);
    expect((await updated.sync()).created, 1);
    final tx = (await autoTxs()).single;
    expect(
      DateTime.fromMillisecondsSinceEpoch(tx.occurredAt),
      DateTime(2026, 11, 21, 18, 57),
      reason: 'ghi theo thời gian gốc, không phải lúc đọc lại',
    );
  });

  test('ngày in trong tin lệch quá xa thì dùng lúc tin đến', () async {
    platform.post(bidv(time: '18:57 21/11/2025'), at);
    await service.sync();
    final tx = (await autoTxs()).single;
    expect(DateTime.fromMillisecondsSinceEpoch(tx.occurredAt), at);
  });

  test('gửi đúng danh sách gói sang Android', () async {
    await auto.startCapture(packageName: 'vn.newbank', until: DateTime(2026, 11, 29));
    await auto.startCapture(packageName: 'vn.expired', until: DateTime(2026, 11, 1));
    await service.sync();
    expect(platform.watched, unorderedEquals([bidvPkg, 'vn.newbank']));

    await auto.setAppEnabled(bidvPkg, false);
    await service.pushWatchedPackages();
    expect(platform.watched, ['vn.newbank']);

    await auto.setEnabled(false);
    await service.pushWatchedPackages();
    expect(platform.watched, isEmpty, reason: 'tắt tính năng là không nghe gì');
  });

  test('dọn tin cũ không thành giao dịch, giữ tin đã ghi', () async {
    platform.post(bidv(), DateTime(2026, 9, 1));
    platform.post('Ma OTP 123456', DateTime(2026, 9, 1), title: 'BIDV');
    platform.post('Ma OTP 654321', DateTime(2026, 11, 20), title: 'BIDV');
    await service.sync();
    final left = await events();
    expect(left.map((e) => e.status), unorderedEquals(['parsed', 'unmatched']));
    expect(left.firstWhere((e) => e.status == 'unmatched').body,
        contains('654321'));
  });

  test('sửa và lưu giao dịch tự ghi thì hết chờ xem lại', () async {
    platform.post(bidv(), at);
    await service.sync();
    expect(await auto.watchReviewCount().first, 1);
    final tx = (await autoTxs()).single;
    await repo.updateTransaction(
      id: tx.id,
      kind: tx.kind,
      amount: tx.amount,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(tx.occurredAt),
      walletFromId: tx.walletFromId,
      note: tx.note,
    );
    expect(await auto.watchReviewCount().first, 0);
  });

  group('khoá giao dịch', () {
    test('có mã giao dịch thì dùng mã', () {
      expect(
        txnKeyOf(
          'bidv',
          const ParsedTxn(
            direction: TxDirection.expense,
            amount: 1,
            reference: 'FT1',
          ),
          at,
        ),
        'bidv|ref:FT1',
      );
    });

    test('không có mã, không có số dư thì không đủ chắc để chống trùng', () {
      expect(
        txnKeyOf(
          'bidv',
          ParsedTxn(
            direction: TxDirection.expense,
            amount: 1,
            occurredAt: at,
          ),
          at,
        ),
        isNull,
      );
    });
  });

  test('dedupe hash ổn định và phân biệt phút', () {
    final a = eventDedupeHash('p', 't', 'x', DateTime(2026, 1, 1, 10, 0, 5));
    final b = eventDedupeHash('p', 't', 'x', DateTime(2026, 1, 1, 10, 0, 50));
    final c = eventDedupeHash('p', 't', 'x', DateTime(2026, 1, 1, 10, 1, 0));
    expect(a, b);
    expect(a, isNot(c));
    expect(a, hasLength(16));
  });
}
