import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/autotrack_repository.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/features/autotrack/autotrack_service.dart';
import 'package:moneybook/features/backup/backup_service.dart';

import 'support/fake_autotrack_platform.dart';

/// Sao lưu mang theo cài đặt tự động ghi và những gì app đã học để phân loại,
/// nhưng KHÔNG mang thông báo thô (số tài khoản, số dư).
void main() {
  late AppDatabase source;
  late Repository repo;
  late AutoTrackRepository auto;
  late int bidvWallet;
  late int giaiTri;

  setUp(() async {
    source = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(source);
    auto = AutoTrackRepository(source);

    bidvWallet = await repo.insertWallet(
      WalletsCompanion.insert(name: 'BIDV', createdAt: 0, updatedAt: 0),
    );
    giaiTri = (await (source.select(source.categories)
              ..where((c) => c.name.equals('Giải trí')))
            .getSingle())
        .id;

    await auto.setEnabled(true);
    await auto.bindParser(parserId: 'bidv', packageName: bidvPkg);
    await auto.setDefaultWallet(bidvPkg, bidvWallet);
    await auto.setAccountWallet(bidvPkg, '7890', bidvWallet);
    await auto.startCapture(
      packageName: 'vn.newbank',
      until: DateTime(2026, 12, 1),
    );

    // Hai giao dịch tự ghi: một đã phân loại (sinh quy tắc), một còn chờ.
    final platform = FakePlatform();
    for (final (i, content) in ['NGUYEN VAN B', 'TRAN THI C'].indexed) {
      platform.post(
        'Thời gian giao dịch: 10:0$i 23/11/2026\n'
        'Tài khoản thanh toán: 1234567890\n'
        'Số tiền GD: -45,000 VND\n'
        'Số dư cuối: 1,000,000 VND\n'
        'Nội dung giao dịch: $content\n'
        'Mã giao dịch: FT$i',
        DateTime(2026, 11, 23, 10, i),
        title: 'Thông báo BIDV',
      );
    }
    await AutoTrackService(repo: repo, auto: auto, platform: platform).sync();
    final first = (await (source.select(source.transactions)
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get())
        .first;
    await auto.learn(transactionId: first.id, categoryId: giaiTri);
    await auto.addKeyword('KATINAT', giaiTri);
  });

  tearDown(() => source.close());

  Future<AppDatabase> restore(String json, {ImportMode mode = ImportMode.replace}) async {
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(target.close);
    await BackupService(target).import(json, mode: mode);
    return target;
  }

  test('file không chứa thông báo thô', () async {
    final json = await BackupService(source).buildJson();
    final data = jsonDecode(json) as Map<String, dynamic>;
    expect(data['formatVersion'], kBackupFormatVersion);
    expect(data.containsKey('notificationEvents'), isFalse);
    expect(json, isNot(contains('1234567890')), reason: 'số tài khoản');
    expect(json, isNot(contains('1,000,000')), reason: 'số dư trong tin');
    expect(json, isNot(contains('vn.newbank')),
        reason: 'app đang ghi mẫu chỉ là tạm thời');
  });

  test('ghi đè: khôi phục đủ quy tắc, từ khoá, ví nhận và hàng chờ', () async {
    final target = await restore(await BackupService(source).buildJson());
    final tAuto = AutoTrackRepository(target);

    final newBidv = (await (target.select(target.wallets)
              ..where((w) => w.name.equals('BIDV')))
            .getSingle())
        .id;
    final app = await tAuto.trackedApp(bidvPkg);
    expect(app?.parserId, 'bidv');
    expect(app?.defaultWalletId, newBidv, reason: 'id ví đã ánh xạ lại');
    final accounts = await tAuto.watchAccountWallets(bidvPkg).first;
    expect(accounts.single.accountSuffix, '7890');
    expect(accounts.single.walletId, newBidv);

    final rules = await tAuto.watchRules().first;
    expect(rules.single.rule.matchKey, 'NGUYEN VAN B');
    expect(rules.single.categoryName, 'Giải trí');

    final keywords = await tAuto.watchKeywords().first;
    expect(keywords.map((k) => k.keyword.keyword), contains('KATINAT'));
    expect(
      keywords.where((k) => k.keyword.isBuiltIn),
      isNotEmpty,
      reason: 'từ khoá có sẵn cũng đi theo',
    );

    final txs = await target.select(target.transactions).get();
    expect(txs.where((t) => t.needsReview), hasLength(1),
        reason: 'khoản còn chờ vẫn chờ');
    expect(txs.every((t) => t.autoEventId == null), isTrue,
        reason: 'thông báo thô không đi theo nên không nối được');
    expect(await tAuto.flag(AutoTrackRepository.kKeywordsSeededKey), isTrue,
        reason: 'đã có từ khoá từ file thì không gieo thêm');
  });

  test('học tiếp được ngay sau khi khôi phục', () async {
    final target = await restore(await BackupService(source).buildJson());
    final tRepo = Repository(target);
    final tAuto = AutoTrackRepository(target);
    final platform = FakePlatform();
    platform.post(
      'Thời gian giao dịch: 11:00 24/11/2026\n'
      'Số tiền GD: -30,000 VND\n'
      'Nội dung giao dịch: NGUYEN VAN B\n'
      'Mã giao dịch: FT99',
      DateTime(2026, 11, 24, 11),
      title: 'Thông báo BIDV',
    );
    await AutoTrackService(repo: tRepo, auto: tAuto, platform: platform).sync();
    final tx = (await (target.select(target.transactions)
              ..where((t) => t.autoEventId.isNotNull()))
            .get())
        .single;
    final cat = await (target.select(target.categories)
          ..where((c) => c.id.equals(tx.categoryId!)))
        .getSingle();
    expect(cat.name, 'Giải trí');
    expect(tx.needsReview, isFalse);
  });

  test('file cũ (v5) không có từ khoá: gieo lại từ khoá có sẵn', () async {
    final data = jsonDecode(await BackupService(source).buildJson())
        as Map<String, dynamic>
      ..['formatVersion'] = 5;
    for (final k in [
      'trackedApps',
      'accountWallets',
      'receiverRules',
      'categoryKeywords',
    ]) {
      data.remove(k);
    }
    final target = await restore(jsonEncode(data));
    final tAuto = AutoTrackRepository(target);
    expect(await tAuto.watchRules().first, isEmpty);
    await tAuto.seedKeywordsOnce();
    expect(await tAuto.watchKeywords().first, isNotEmpty);
  });

  test('gộp: cài đặt đang có trên máy được giữ', () async {
    final json = await BackupService(source).buildJson();
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(target.close);
    final tRepo = Repository(target);
    final tAuto = AutoTrackRepository(target);
    final mine = await tRepo.insertWallet(
      WalletsCompanion.insert(name: 'BIDV của máy này', createdAt: 0, updatedAt: 0),
    );
    await tAuto.bindParser(parserId: 'bidv', packageName: bidvPkg);
    await tAuto.setDefaultWallet(bidvPkg, mine);

    await BackupService(target).import(json, mode: ImportMode.merge);
    expect((await tAuto.trackedApp(bidvPkg))?.defaultWalletId, mine);
    expect(await tAuto.watchRules().first, hasLength(1));

    // Gộp lần nữa không nhân đôi quy tắc: mỗi người nhận một quy tắc. (Danh
    // mục thì chế độ gộp vốn luôn thêm bản mới, từ khoá đi theo chúng.)
    await BackupService(target).import(json, mode: ImportMode.merge);
    expect(await tAuto.watchRules().first, hasLength(1));
  });
}
