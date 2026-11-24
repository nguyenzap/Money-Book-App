import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/autotrack_repository.dart';
import 'package:moneybook/core/db/database.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/domain/autotrack/categorizer.dart';
import 'package:moneybook/features/autotrack/autotrack_service.dart';

import 'support/fake_autotrack_platform.dart';

/// Hàng chờ phân loại: lần đầu gặp người nhận thì chưa phân loại; mình chọn
/// danh mục một lần thì app nhớ và tự phân loại những lần sau.
void main() {
  late AppDatabase db;
  late Repository repo;
  late AutoTrackRepository auto;
  late FakePlatform platform;
  late AutoTrackService service;
  late int wallet;
  late int anUong;
  late int giaiTri;
  late int luong;
  var minute = 0;

  String bidv(String content, {String amount = '-50,000 VND'}) {
    minute++;
    return 'BIDV xin thông báo tới Quý khách\n'
        'Thời gian giao dịch: 10:${minute.toString().padLeft(2, '0')} 23/11/2026\n'
        'Số tiền GD: $amount\n'
        'Nội dung giao dịch: $content\n'
        'Mã giao dịch: FT$minute';
  }

  Future<void> receive(String content, {String amount = '-50,000 VND'}) async {
    platform.post(bidv(content, amount: amount), DateTime(2026, 11, 23, 10, minute));
    await service.sync();
  }

  Future<List<Transaction>> autoTxs() => (db.select(db.transactions)
        ..where((t) => t.autoEventId.isNotNull())
        ..orderBy([(t) => OrderingTerm.asc(t.id)]))
      .get();

  Future<int> categoryId(String name) async =>
      (await (db.select(db.categories)..where((c) => c.name.equals(name)))
              .get())
          .first
          .id;

  setUp(() async {
    minute = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    auto = AutoTrackRepository(db);
    platform = FakePlatform();
    await db.customStatement('PRAGMA foreign_keys = ON');
    wallet = await repo.insertWallet(
      WalletsCompanion.insert(
        name: 'BIDV',
        initialBalance: const Value(5000000),
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    await auto.setEnabled(true);
    await auto.bindParser(parserId: 'bidv', packageName: bidvPkg);
    await auto.setDefaultWallet(bidvPkg, wallet);
    service = AutoTrackService(
      repo: repo,
      auto: auto,
      platform: platform,
      clock: () => DateTime(2026, 11, 23, 12),
    );
    anUong = await categoryId('Ăn uống');
    giaiTri = await categoryId('Giải trí');
    luong = await categoryId('Lương');
  });

  tearDown(() => db.close());

  test('người nhận lạ: chưa phân loại, nằm trong hàng chờ', () async {
    await receive('NGUYEN VAN B chuyen tien');
    final tx = (await autoTxs()).single;
    expect(tx.categoryId, isNull);
    expect(tx.needsReview, isTrue);

    final items = await auto.watchReviewItems().first;
    expect(items.single.receiverKey, 'NGUYEN VAN B');
    expect(items.single.isUncategorized, isTrue);
  });

  test('từ khoá có sẵn: đoán danh mục nhưng vẫn chờ xem lại', () async {
    await receive('CONG CAPHE CAFE Q1');
    final tx = (await autoTxs()).single;
    expect(tx.categoryId, anUong);
    expect(tx.needsReview, isTrue);
    final item = (await auto.watchReviewItems().first).single;
    expect(item.source, CategorySource.keyword);
    expect(item.reason, contains('CAFE'));
  });

  test('phân loại một lần: nhớ, áp cho các lần cũ, và tự phân loại lần sau',
      () async {
    await receive('NGUYEN VAN B chuyen tien');
    await receive('NGUYEN VAN B chuyen tien 2');
    await receive('TRAN THI C');
    final first = (await autoTxs()).first;

    final result = await auto.learn(
      transactionId: first.id,
      categoryId: giaiTri,
    );
    expect(result.appliedToOthers, 1, reason: 'chỉ cùng người nhận');

    final txs = await autoTxs();
    expect(txs.map((t) => t.categoryId), [giaiTri, giaiTri, null]);
    expect(txs.map((t) => t.needsReview), [false, false, true]);

    // Lần sau: theo quy tắc, không cần xem lại.
    final report = await (() async {
      platform.post(bidv('NGUYEN VAN B'), DateTime(2026, 11, 23, 11));
      return service.sync();
    })();
    expect(report.categorized, 1);
    final last = (await autoTxs()).last;
    expect(last.categoryId, giaiTri);
    expect(last.needsReview, isFalse);

    final rules = await auto.watchRules().first;
    expect(rules.single.rule.matchKey, 'NGUYEN VAN B');
    expect(rules.single.rule.hitCount, 1);
  });

  test('hoàn tác trả lại đúng như trước và bỏ quy tắc mới', () async {
    await receive('NGUYEN VAN B');
    await receive('NGUYEN VAN B');
    final first = (await autoTxs()).first;
    final result = await auto.learn(transactionId: first.id, categoryId: anUong);
    await auto.undoLearn(result);

    final txs = await autoTxs();
    expect(txs.every((t) => t.categoryId == null && t.needsReview), isTrue);
    expect(await auto.watchRules().first, isEmpty);
  });

  test('áp quy tắc không đè lên giao dịch đã phân loại chắc chắn', () async {
    await receive('NGUYEN VAN B');
    await receive('NGUYEN VAN B');
    final txs = await autoTxs();
    await auto.learn(
      transactionId: txs[1].id,
      categoryId: anUong,
      rememberRule: false,
    );
    expect(await auto.watchRules().first, isEmpty,
        reason: '"Chỉ giao dịch này" không tạo quy tắc');

    await auto.learn(transactionId: txs[0].id, categoryId: giaiTri);
    final after = await autoTxs();
    expect(after[1].categoryId, anUong, reason: 'mình đã tự chọn, giữ nguyên');
  });

  test('đoán sai thì phân loại lại cũng sửa luôn các lần đoán khác', () async {
    await receive('HIGHLANDS COFFEE');
    await receive('HIGHLANDS COFFEE');
    final txs = await autoTxs();
    expect(txs.every((t) => t.categoryId == anUong && t.needsReview), isTrue);

    final r = await auto.learn(transactionId: txs[0].id, categoryId: giaiTri);
    expect(r.appliedToOthers, 1);
    expect((await autoTxs()).every((t) => t.categoryId == giaiTri), isTrue);
  });

  test('quy tắc tách theo chiều tiền: chi cho B khác nhận từ B', () async {
    await receive('NGUYEN VAN B');
    await receive('NGUYEN VAN B', amount: '+2,000,000 VND');
    final txs = await autoTxs();
    await auto.learn(transactionId: txs[0].id, categoryId: anUong);
    expect((await autoTxs())[1].categoryId, isNull,
        reason: 'khoản nhận không bị gán danh mục chi');

    await auto.learn(transactionId: txs[1].id, categoryId: luong);
    await receive('NGUYEN VAN B', amount: '+1,000,000 VND');
    expect((await autoTxs()).last.categoryId, luong);
  });

  test('người nhận rỗng thì chỉ phân loại giao dịch đó, không học', () async {
    await receive('THANH TOAN');
    await receive('THANH TOAN');
    final txs = await autoTxs();
    final r = await auto.learn(transactionId: txs[0].id, categoryId: anUong);
    expect(r.appliedToOthers, 0);
    expect(await auto.watchRules().first, isEmpty);
  });

  test('xoá danh mục thì quy tắc của nó cũng mất', () async {
    await receive('NGUYEN VAN B');
    final tx = (await autoTxs()).single;
    await auto.learn(transactionId: tx.id, categoryId: giaiTri);
    expect(await auto.watchRules().first, hasLength(1));

    await repo.deleteCategory(giaiTri);
    expect(await auto.watchRules().first, isEmpty);
    expect((await autoTxs()).single.categoryId, isNull,
        reason: 'giao dịch còn đó, thành chưa phân loại như mọi khi');
  });

  test('từ khoá có sẵn chỉ gieo một lần', () async {
    await auto.seedKeywordsOnce();
    final n = (await auto.watchKeywords().first).length;
    expect(n, greaterThan(20));
    final first = (await auto.watchKeywords().first).first;
    await auto.deleteKeyword(first.keyword.id);
    await auto.seedKeywordsOnce();
    expect((await auto.watchKeywords().first).length, n - 1,
        reason: 'đã xoá thì không mọc lại');
  });

  test('tắt đoán theo từ khoá', () async {
    await auto.setFlag(AutoTrackRepository.kKeywordsKey, false);
    await receive('HIGHLANDS COFFEE');
    expect((await autoTxs()).single.categoryId, isNull);
  });
}
