import 'package:drift/drift.dart';

import '../domain/autotrack/categorizer.dart';
import '../domain/autotrack/receiver_normalizer.dart';
import '../domain/autotrack/text_fold.dart';
import '../domain/tx_kind.dart';
import 'database.dart';

/// Trạng thái của một thông báo thô. Lưu bằng [name].
enum EventStatus {
  /// Vừa nhận, chưa xử lý.
  pending,

  /// Đã thành giao dịch.
  parsed,

  /// Không phải thông báo giao dịch (OTP, khuyến mãi, mẫu lạ).
  unmatched,

  /// Trông như giao dịch nhưng đọc không ra.
  failed,

  /// Đọc được nhưng chưa chọn ví cho ngân hàng / tài khoản này.
  unmapped,

  /// App đang ở chế độ ghi mẫu, chỉ lưu chữ.
  captured,

  /// Cùng một giao dịch đã ghi từ một thông báo khác.
  duplicate;

  static EventStatus parse(String s) =>
      values.firstWhere((v) => v.name == s, orElse: () => pending);
}

/// Truy vấn của tính năng tự động ghi.
///
/// Để riêng khỏi `repository.dart` cho dễ gộp với các thay đổi của nhánh
/// chính; quy tắc vẫn như cũ: không viết SQL ở tầng giao diện.
class AutoTrackRepository {
  AutoTrackRepository(this.db);
  final AppDatabase db;

  static const kEnabledKey = 'autotrack.enabled';
  static const kSimilarKey = 'autotrack.similarMatch.enabled';
  static const kKeywordsKey = 'autotrack.keywords.enabled';
  static const kKeywordsSeededKey = 'autotrack.keywords.seeded';

  // ---- Cài đặt ----------------------------------------------------------

  Stream<bool> watchEnabled() => (db.select(db.settingsKv)
        ..where((s) => s.key.equals(kEnabledKey)))
      .watchSingleOrNull()
      .map((r) => r?.value == 'true');

  Future<bool> isEnabled() async =>
      (await (db.select(db.settingsKv)..where((s) => s.key.equals(kEnabledKey)))
              .getSingleOrNull())
          ?.value ==
      'true';

  Future<void> setEnabled(bool on) => setFlag(kEnabledKey, on);

  /// Cờ bật/tắt chung. [fallback] là giá trị khi chưa từng đặt.
  Stream<bool> watchFlag(String key, {bool fallback = false}) =>
      (db.select(db.settingsKv)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((r) => r == null ? fallback : r.value == 'true');

  Future<bool> flag(String key, {bool fallback = false}) async {
    final r = await (db.select(db.settingsKv)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return r == null ? fallback : r.value == 'true';
  }

  Future<void> setFlag(String key, bool on) => db
      .into(db.settingsKv)
      .insertOnConflictUpdate(
        SettingsKvCompanion.insert(key: key, value: on ? 'true' : 'false'),
      );

  // ---- App đang nghe ----------------------------------------------------

  Stream<List<TrackedApp>> watchTrackedApps() => (db.select(db.trackedApps)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch();

  Future<TrackedApp?> trackedApp(String packageName) =>
      (db.select(db.trackedApps)
            ..where((t) => t.packageName.equals(packageName)))
          .getSingleOrNull();

  /// Gắn một ngân hàng được hỗ trợ vào một app trên máy. Mỗi ngân hàng chỉ
  /// đọc từ một app: gắn app mới thì app cũ của ngân hàng đó bị gỡ.
  Future<void> bindParser({
    required String parserId,
    required String packageName,
    String? label,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.transaction(() async {
      final old = await (db.select(db.trackedApps)
            ..where((t) => t.parserId.equals(parserId)))
          .get();
      final keepWallet = old.isEmpty ? null : old.first.defaultWalletId;
      for (final o in old) {
        if (o.packageName != packageName) {
          await (db.delete(db.trackedApps)
                ..where((t) => t.packageName.equals(o.packageName)))
              .go();
        }
      }
      final existing = await trackedApp(packageName);
      if (existing == null) {
        await db.into(db.trackedApps).insert(
          TrackedAppsCompanion.insert(
            packageName: packageName,
            parserId: Value(parserId),
            label: Value(label),
            defaultWalletId: Value(keepWallet),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await (db.update(db.trackedApps)
              ..where((t) => t.packageName.equals(packageName)))
            .write(
          TrackedAppsCompanion(
            parserId: Value(parserId),
            label: Value(label ?? existing.label),
            enabled: const Value(true),
            captureUntil: const Value(null),
            defaultWalletId: Value(existing.defaultWalletId ?? keepWallet),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Ghi mẫu thông báo của một app bất kỳ tới [until], không sinh giao dịch.
  Future<void> startCapture({
    required String packageName,
    String? label,
    required DateTime until,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await trackedApp(packageName);
    if (existing?.parserId != null) return; // đã đọc thật rồi, khỏi ghi mẫu
    await db.into(db.trackedApps).insertOnConflictUpdate(
      TrackedAppsCompanion.insert(
        packageName: packageName,
        label: Value(label),
        captureUntil: Value(until.millisecondsSinceEpoch),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> removeTrackedApp(String packageName) => (db.delete(
    db.trackedApps,
  )..where((t) => t.packageName.equals(packageName))).go();

  Future<void> setAppEnabled(String packageName, bool enabled) =>
      (db.update(db.trackedApps)
            ..where((t) => t.packageName.equals(packageName)))
          .write(TrackedAppsCompanion(enabled: Value(enabled)));

  Future<void> setDefaultWallet(String packageName, int? walletId) =>
      (db.update(db.trackedApps)
            ..where((t) => t.packageName.equals(packageName)))
          .write(TrackedAppsCompanion(defaultWalletId: Value(walletId)));

  /// Các gói phía Android được phép đọc: ngân hàng đang bật, cộng app đang
  /// ghi mẫu còn hạn. Tắt cả tính năng thì rỗng.
  Future<List<String>> watchedPackages(DateTime now) async {
    if (!await isEnabled()) return const [];
    final apps = await db.select(db.trackedApps).get();
    return [
      for (final a in apps)
        if (a.enabled &&
            (a.parserId != null ||
                (a.captureUntil ?? 0) > now.millisecondsSinceEpoch))
          a.packageName,
    ];
  }

  // ---- Ví theo tài khoản ------------------------------------------------

  Stream<List<AccountWallet>> watchAccountWallets(String packageName) =>
      (db.select(db.accountWallets)
            ..where((a) => a.packageName.equals(packageName))
            ..orderBy([(a) => OrderingTerm.asc(a.accountSuffix)]))
          .watch();

  Future<void> setAccountWallet(
    String packageName,
    String accountSuffix,
    int walletId,
  ) => db.into(db.accountWallets).insert(
    AccountWalletsCompanion.insert(
      packageName: packageName,
      accountSuffix: accountSuffix,
      walletId: walletId,
    ),
    onConflict: DoUpdate(
      (_) => AccountWalletsCompanion(walletId: Value(walletId)),
      target: [db.accountWallets.packageName, db.accountWallets.accountSuffix],
    ),
  );

  Future<void> removeAccountWallet(int id) =>
      (db.delete(db.accountWallets)..where((a) => a.id.equals(id))).go();

  /// Ví nhận giao dịch: ví riêng của số tài khoản nếu có, không thì ví mặc
  /// định của app. Ví đã lưu trữ coi như chưa chọn.
  Future<int?> resolveWallet(String packageName, String? accountSuffix) async {
    int? walletId;
    if (accountSuffix != null) {
      final rows = await (db.select(db.accountWallets)
            ..where((a) => a.packageName.equals(packageName)))
          .get();
      for (final r in rows) {
        // Ngân hàng có lúc che bớt số: "345" vẫn khớp với "2345".
        if (r.accountSuffix.endsWith(accountSuffix) ||
            accountSuffix.endsWith(r.accountSuffix)) {
          walletId = r.walletId;
          break;
        }
      }
    }
    walletId ??= (await trackedApp(packageName))?.defaultWalletId;
    if (walletId == null) return null;
    final wallet = await (db.select(db.wallets)
          ..where((w) => w.id.equals(walletId!)))
        .getSingleOrNull();
    if (wallet == null || wallet.isArchived) return null;
    return walletId;
  }

  // ---- Thông báo thô ----------------------------------------------------

  /// Lưu một thông báo. Trả về null nếu đã có (cùng [dedupeHash]).
  Future<int?> insertEvent({
    required String packageName,
    required String title,
    required String body,
    required DateTime postedAt,
    required String dedupeHash,
  }) {
    // Hỏi trước rồi mới chèn, trong cùng một transaction. Không dùng
    // insertOrIgnore: khi bị bỏ qua nó trả về rowid của lần chèn trước, nên
    // một tin đến hai lần liền nhau sẽ trông như tin mới.
    return db.transaction(() async {
      final existing = await (db.select(db.notificationEvents)
            ..where((e) => e.dedupeHash.equals(dedupeHash)))
          .getSingleOrNull();
      if (existing != null) return null;
      return db.into(db.notificationEvents).insert(
        NotificationEventsCompanion.insert(
          packageName: packageName,
          title: Value(title),
          body: body,
          postedAt: postedAt.millisecondsSinceEpoch,
          dedupeHash: dedupeHash,
          status: Value(EventStatus.pending.name),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  Future<void> setEventResult(
    int id, {
    required EventStatus status,
    String? reason,
    String? parserId,
    int? parserVersion,
    String? txnKey,
    String? receiverKey,
    String? categorySource,
  }) => (db.update(db.notificationEvents)..where((e) => e.id.equals(id)))
      .write(
        NotificationEventsCompanion(
          status: Value(status.name),
          statusReason: Value(reason),
          parserId: Value(parserId),
          parserVersion: Value(parserVersion),
          txnKey: Value(txnKey),
          receiverKey: Value(receiverKey),
          categorySource: Value(categorySource),
        ),
      );

  /// Thông báo cần (đọc lại): mới nhận, chưa có ví, hoặc chưa đọc được.
  /// Việc lọc theo phiên bản parser làm ở tầng dịch vụ.
  Future<List<NotificationEvent>> eventsToProcess() =>
      (db.select(db.notificationEvents)
            ..where(
              (e) => e.status.isIn([
                EventStatus.pending.name,
                EventStatus.unmapped.name,
                EventStatus.unmatched.name,
                EventStatus.failed.name,
                EventStatus.captured.name,
              ]),
            )
            ..orderBy([(e) => OrderingTerm.asc(e.postedAt)]))
          .get();

  /// Giao dịch này đã được ghi từ một thông báo khác chưa.
  Future<bool> txnKeyExists(String txnKey) async {
    final row = await (db.select(db.notificationEvents)
          ..where(
            (e) =>
                e.txnKey.equals(txnKey) &
                e.status.equals(EventStatus.parsed.name),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  Stream<List<NotificationEvent>> watchEvents({
    Set<EventStatus>? statuses,
    int limit = 300,
  }) {
    final q = db.select(db.notificationEvents)
      ..orderBy([(e) => OrderingTerm.desc(e.postedAt)])
      ..limit(limit);
    if (statuses != null) {
      q.where((e) => e.status.isIn(statuses.map((s) => s.name)));
    }
    return q.watch();
  }

  /// Dọn tin không thành giao dịch: chúng chứa OTP, số dư, số tài khoản.
  Future<int> purgeOld({
    required DateTime now,
    Duration unmatchedFor = const Duration(days: 30),
    Duration capturedFor = const Duration(days: 7),
  }) async {
    final e = db.notificationEvents;
    final unmatchedBefore = now.subtract(unmatchedFor).millisecondsSinceEpoch;
    final capturedBefore = now.subtract(capturedFor).millisecondsSinceEpoch;
    return (db.delete(e)..where(
          (r) =>
              (r.status.isIn([
                    EventStatus.unmatched.name,
                    EventStatus.failed.name,
                    EventStatus.duplicate.name,
                  ]) &
                  r.postedAt.isSmallerThanValue(unmatchedBefore)) |
              (r.status.equals(EventStatus.captured.name) &
                  r.postedAt.isSmallerThanValue(capturedBefore)),
        ))
        .go();
  }

  // ---- Phân loại ---------------------------------------------------------

  /// Gieo từ khoá có sẵn một lần, theo tên danh mục gieo sẵn. Danh mục đã đổi
  /// tên hay xoá thì bỏ qua. Xoá từ khoá có sẵn rồi thì không gieo lại.
  Future<void> seedKeywordsOnce() async {
    if (await flag(kKeywordsSeededKey)) return;
    await db.transaction(() async {
      final cats = await db.select(db.categories).get();
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final entry in kBuiltInKeywords.entries) {
        final cat = cats
            .where((c) => foldVi(c.name) == foldVi(entry.key) && !c.isArchived)
            .firstOrNull;
        if (cat == null) continue;
        for (final k in entry.value) {
          await db.into(db.categoryKeywords).insert(
            CategoryKeywordsCompanion.insert(
              keyword: normalizeReceiver(k),
              categoryId: cat.id,
              isBuiltIn: const Value(true),
              createdAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
      await setFlag(kKeywordsSeededKey, true);
    });
  }

  /// Mọi thứ bộ phân loại cần, đọc một lần cho cả lượt xử lý.
  Future<CategorizerData> loadCategorizerData() async {
    final rules = await db.select(db.receiverRules).get();
    final cats = {
      for (final c in await db.select(db.categories).get()) c.id: c,
    };
    final kws = await (db.select(db.categoryKeywords)
          ..where((k) => k.enabled.equals(true)))
        .get();
    return CategorizerData(
      rules: [
        for (final r in rules)
          if (r.matchType == 'name')
            RuleEntry(
              key: r.matchKey,
              flow: r.flow,
              categoryId: r.categoryId,
              displayName: r.displayName,
              hitCount: r.hitCount,
            ),
      ],
      keywords: [
        for (final k in kws)
          if (cats[k.categoryId] case final c? when !c.isArchived)
            KeywordEntry(keyword: k.keyword, flow: c.flow, categoryId: c.id),
      ],
      useSimilar: await flag(kSimilarKey, fallback: true),
      useKeywords: await flag(kKeywordsKey, fallback: true),
    );
  }

  Future<void> bumpRuleHit(String key, String flow) async {
    await db.customUpdate(
      'UPDATE receiver_rules SET hit_count = hit_count + 1, last_used_at = ? '
      "WHERE match_type = 'name' AND match_key = ? AND flow = ?",
      variables: [
        Variable.withInt(DateTime.now().millisecondsSinceEpoch),
        Variable.withString(key),
        Variable.withString(flow),
      ],
      updates: {db.receiverRules},
    );
  }

  /// Mình chọn danh mục cho một giao dịch tự ghi: nhớ "người nhận này thuộc
  /// danh mục này", rồi phân loại luôn những giao dịch khác của cùng người
  /// nhận còn chưa phân loại hoặc mới chỉ là đoán. Giao dịch đã phân loại
  /// chắc chắn thì không đụng tới.
  ///
  /// [rememberRule] false: chỉ giao dịch này ("Chỉ giao dịch này").
  /// Trả về [LearnResult] để hoàn tác.
  Future<LearnResult> learn({
    required int transactionId,
    required int categoryId,
    bool rememberRule = true,
  }) {
    return db.transaction(() async {
      final tx = await (db.select(db.transactions)
            ..where((t) => t.id.equals(transactionId)))
          .getSingle();
      final event = tx.autoEventId == null
          ? null
          : await (db.select(db.notificationEvents)
                  ..where((e) => e.id.equals(tx.autoEventId!)))
                .getSingleOrNull();
      final key = event?.receiverKey ?? '';
      final flow = tx.kind == TxKind.income ? 'income' : 'expense';

      final before = <_TxSnapshot>[
        _TxSnapshot(tx.id, tx.categoryId, tx.needsReview, event?.id,
            event?.categorySource),
      ];
      await _setCategory(tx.id, event?.id, categoryId, CategorySource.user);

      ReceiverRule? ruleBefore;
      var ruleCreated = false;
      if (rememberRule && key.isNotEmpty) {
        ruleBefore = await _rule(key, flow);
        final now = DateTime.now().millisecondsSinceEpoch;
        if (ruleBefore == null) {
          ruleCreated = true;
          await db.into(db.receiverRules).insert(
            ReceiverRulesCompanion.insert(
              matchType: 'name',
              matchKey: key,
              flow: flow,
              displayName: tx.note ?? key,
              categoryId: categoryId,
              lastUsedAt: Value(now),
              createdAt: now,
              updatedAt: now,
            ),
          );
        } else {
          await (db.update(db.receiverRules)
                ..where((r) => r.id.equals(ruleBefore!.id)))
              .write(
            ReceiverRulesCompanion(
              categoryId: Value(categoryId),
              displayName: Value(tx.note ?? ruleBefore.displayName),
              updatedAt: Value(now),
            ),
          );
        }

        // Những giao dịch khác của cùng người nhận, cùng chiều.
        final others = await db.customSelect(
          'SELECT t.id, t.category_id, t.needs_review, e.id AS eid, '
          'e.category_source FROM transactions t '
          'JOIN notification_events e ON e.id = t.auto_event_id '
          'WHERE e.receiver_key = ? AND t.kind = ? AND t.id <> ? '
          'AND t.deleted_at IS NULL '
          "AND (t.category_id IS NULL OR e.category_source IN ('similar', 'keyword'))",
          variables: [
            Variable.withString(key),
            Variable.withString(tx.kind.name),
            Variable.withInt(tx.id),
          ],
        ).get();
        for (final o in others) {
          final id = o.read<int>('id');
          final eid = o.read<int>('eid');
          before.add(_TxSnapshot(
            id,
            o.read<int?>('category_id'),
            o.read<bool>('needs_review'),
            eid,
            o.read<String?>('category_source'),
          ));
          await _setCategory(id, eid, categoryId, CategorySource.name);
        }
      }

      return LearnResult._(
        receiverName: tx.note ?? key,
        appliedToOthers: before.length - 1,
        before: before,
        ruleBefore: ruleBefore,
        ruleCreated: ruleCreated,
        ruleKey: key,
        ruleFlow: flow,
      );
    });
  }

  /// Hoàn tác một lần [learn].
  Future<void> undoLearn(LearnResult r) => db.transaction(() async {
    for (final s in r._before) {
      await (db.update(db.transactions)..where((t) => t.id.equals(s.txId)))
          .write(
        TransactionsCompanion(
          categoryId: Value(s.categoryId),
          needsReview: Value(s.needsReview),
        ),
      );
      if (s.eventId != null) {
        await (db.update(db.notificationEvents)
              ..where((e) => e.id.equals(s.eventId!)))
            .write(NotificationEventsCompanion(categorySource: Value(s.source)));
      }
    }
    if (r.ruleCreated) {
      final rule = await _rule(r.ruleKey, r.ruleFlow);
      if (rule != null) {
        await (db.delete(db.receiverRules)..where((x) => x.id.equals(rule.id)))
            .go();
      }
    } else if (r.ruleBefore != null) {
      await db.update(db.receiverRules).replace(r.ruleBefore!);
    }
  });

  /// Đánh dấu một giao dịch tự ghi là mình đã tự chọn danh mục (không học).
  Future<void> markUserCategorized(int transactionId) async {
    final tx = await (db.select(db.transactions)
          ..where((t) => t.id.equals(transactionId)))
        .getSingle();
    if (tx.autoEventId == null) return;
    await (db.update(db.notificationEvents)
          ..where((e) => e.id.equals(tx.autoEventId!)))
        .write(
      NotificationEventsCompanion(
        categorySource: Value(CategorySource.user.name),
      ),
    );
  }

  /// Nguồn danh mục hiện tại của một giao dịch tự ghi, và người nhận đã chuẩn
  /// hoá. Null nếu không phải giao dịch tự ghi.
  Future<({String receiverKey, CategorySource? source})?> autoInfo(
    int transactionId,
  ) async {
    final row = await db.customSelect(
      'SELECT e.receiver_key, e.category_source FROM transactions t '
      'JOIN notification_events e ON e.id = t.auto_event_id WHERE t.id = ?',
      variables: [Variable.withInt(transactionId)],
    ).getSingleOrNull();
    if (row == null) return null;
    return (
      receiverKey: row.read<String?>('receiver_key') ?? '',
      source: CategorySource.parse(row.read<String?>('category_source')),
    );
  }

  Future<ReceiverRule?> _rule(String key, String flow) =>
      (db.select(db.receiverRules)
            ..where(
              (r) =>
                  r.matchType.equals('name') &
                  r.matchKey.equals(key) &
                  r.flow.equals(flow),
            ))
          .getSingleOrNull();

  Future<void> _setCategory(
    int txId,
    int? eventId,
    int categoryId,
    CategorySource source,
  ) async {
    await (db.update(db.transactions)..where((t) => t.id.equals(txId))).write(
      TransactionsCompanion(
        categoryId: Value(categoryId),
        needsReview: const Value(false),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    if (eventId != null) {
      await (db.update(db.notificationEvents)
            ..where((e) => e.id.equals(eventId)))
          .write(
        NotificationEventsCompanion(
          categorySource: Value(source.name),
          statusReason: const Value(null),
        ),
      );
    }
  }

  /// Giao dịch tự ghi còn chờ: chưa phân loại, hoặc phân loại mới chỉ là đoán.
  Stream<List<ReviewItem>> watchReviewItems() {
    return db.customSelect(
      'SELECT t.id, t.kind, t.amount, t.occurred_at, t.note, t.category_id, '
      'c.name AS category_name, e.receiver_key, e.category_source, '
      'e.status_reason, w.name AS wallet_name '
      'FROM transactions t '
      'JOIN notification_events e ON e.id = t.auto_event_id '
      'LEFT JOIN categories c ON c.id = t.category_id '
      'LEFT JOIN wallets w ON w.id = COALESCE(t.wallet_from_id, t.wallet_to_id) '
      'WHERE t.needs_review = 1 AND t.deleted_at IS NULL '
      "AND t.kind IN ('expense', 'income') "
      'ORDER BY t.occurred_at DESC',
      readsFrom: {
        db.transactions,
        db.notificationEvents,
        db.categories,
        db.wallets,
      },
    ).watch().map(
      (rows) => [
        for (final r in rows)
          ReviewItem(
            transactionId: r.read<int>('id'),
            kind: TxKind.values.byName(r.read<String>('kind')),
            amount: r.read<int>('amount'),
            occurredAt: DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('occurred_at'),
            ),
            note: r.read<String?>('note'),
            categoryId: r.read<int?>('category_id'),
            categoryName: r.read<String?>('category_name'),
            receiverKey: r.read<String?>('receiver_key') ?? '',
            source: CategorySource.parse(r.read<String?>('category_source')),
            reason: r.read<String?>('status_reason'),
            walletName: r.read<String?>('wallet_name'),
          ),
      ],
    );
  }

  // ---- Quản lý quy tắc và từ khoá ---------------------------------------

  Stream<List<RuleView>> watchRules() {
    return db.customSelect(
      'SELECT r.*, c.name AS category_name FROM receiver_rules r '
      'JOIN categories c ON c.id = r.category_id '
      'ORDER BY r.last_used_at DESC, r.display_name',
      readsFrom: {db.receiverRules, db.categories},
    ).watch().map(
      (rows) => [
        for (final r in rows)
          RuleView(
            rule: db.receiverRules.map(r.data),
            categoryName: r.read<String>('category_name'),
          ),
      ],
    );
  }

  Future<void> setRuleCategory(int ruleId, int categoryId) =>
      (db.update(db.receiverRules)..where((r) => r.id.equals(ruleId))).write(
        ReceiverRulesCompanion(
          categoryId: Value(categoryId),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Future<void> deleteRule(int ruleId) =>
      (db.delete(db.receiverRules)..where((r) => r.id.equals(ruleId))).go();

  /// Hoàn tác [deleteRule].
  Future<void> restoreRule(ReceiverRule rule) => db
      .into(db.receiverRules)
      .insert(rule, mode: InsertMode.insertOrReplace);

  Stream<List<KeywordView>> watchKeywords() {
    return db.customSelect(
      'SELECT k.*, c.name AS category_name, c.flow AS flow '
      'FROM category_keywords k JOIN categories c ON c.id = k.category_id '
      'ORDER BY c.flow DESC, c.sort_order, k.keyword',
      readsFrom: {db.categoryKeywords, db.categories},
    ).watch().map(
      (rows) => [
        for (final r in rows)
          KeywordView(
            keyword: db.categoryKeywords.map(r.data),
            categoryName: r.read<String>('category_name'),
            flow: r.read<String>('flow'),
          ),
      ],
    );
  }

  /// Thêm từ khoá. Trả về false nếu chuẩn hoá xong không còn gì.
  Future<bool> addKeyword(String raw, int categoryId) async {
    final k = normalizeReceiver(raw);
    if (k.isEmpty) return false;
    await db.into(db.categoryKeywords).insert(
      CategoryKeywordsCompanion.insert(
        keyword: k,
        categoryId: categoryId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrIgnore,
    );
    return true;
  }

  Future<void> setKeywordEnabled(int id, bool enabled) =>
      (db.update(db.categoryKeywords)..where((k) => k.id.equals(id)))
          .write(CategoryKeywordsCompanion(enabled: Value(enabled)));

  Future<void> deleteKeyword(int id) =>
      (db.delete(db.categoryKeywords)..where((k) => k.id.equals(id))).go();

  // ---- Sức khoẻ: số dư, mẫu thông báo, im lặng -----------------------------

  /// Thông báo đã ghi gần nhất của mỗi ví (ví còn dùng), để đối chiếu số dư
  /// ngân hàng báo trong đó với số dư app tính.
  Future<List<LatestBankEvent>> latestParsedPerWallet() async {
    final rows = await db.customSelect(
      'SELECT e.id AS eid, e.parser_id, e.title, e.body, t.occurred_at, '
      'w.id AS wid, w.name AS wname '
      'FROM notification_events e '
      'JOIN transactions t ON t.auto_event_id = e.id '
      'JOIN wallets w ON w.id = COALESCE(t.wallet_from_id, t.wallet_to_id) '
      "WHERE e.status = 'parsed' AND t.deleted_at IS NULL "
      'AND w.is_archived = 0 '
      'ORDER BY t.occurred_at DESC, e.posted_at DESC, e.id DESC '
      'LIMIT 500',
    ).get();
    final seen = <int>{};
    return [
      for (final r in rows)
        if (seen.add(r.read<int>('wid')))
          LatestBankEvent(
            eventId: r.read<int>('eid'),
            parserId: r.read<String?>('parser_id'),
            title: r.read<String>('title'),
            body: r.read<String>('body'),
            occurredAt: DateTime.fromMillisecondsSinceEpoch(
              r.read<int>('occurred_at'),
            ),
            walletId: r.read<int>('wid'),
            walletName: r.read<String>('wname'),
          ),
    ];
  }

  /// Tin không đọc được gần đây của các ngân hàng đang bật.
  Future<List<NotificationEvent>> recentUnparsed(DateTime since) async {
    final apps = await (db.select(db.trackedApps)
          ..where((t) => t.parserId.isNotNull() & t.enabled.equals(true)))
        .get();
    if (apps.isEmpty) return const [];
    return (db.select(db.notificationEvents)
          ..where(
            (e) =>
                e.packageName.isIn(apps.map((a) => a.packageName)) &
                e.status.isIn([
                  EventStatus.unmatched.name,
                  EventStatus.failed.name,
                ]) &
                e.postedAt.isBiggerOrEqualValue(since.millisecondsSinceEpoch),
          ))
        .get();
  }

  /// Lúc nhận thông báo gần nhất từ các ngân hàng đang bật. Null nếu chưa
  /// từng nhận.
  Future<DateTime?> lastBankEventAt() async {
    final row = await db.customSelect(
      'SELECT MAX(e.posted_at) AS at FROM notification_events e '
      'JOIN tracked_apps a ON a.package_name = e.package_name '
      'WHERE a.parser_id IS NOT NULL AND a.enabled = 1',
    ).getSingle();
    final at = row.read<int?>('at');
    return at == null ? null : DateTime.fromMillisecondsSinceEpoch(at);
  }

  Future<String?> setting(String key) async =>
      (await (db.select(db.settingsKv)..where((s) => s.key.equals(key)))
              .getSingleOrNull())
          ?.value;

  Future<void> setSetting(String key, String value) => db
      .into(db.settingsKv)
      .insertOnConflictUpdate(SettingsKvCompanion.insert(key: key, value: value));

  /// Số giao dịch tự ghi còn chờ xem lại.
  Stream<int> watchReviewCount() {
    final t = db.transactions;
    final count = t.id.count();
    final q = db.selectOnly(t)
      ..addColumns([count])
      ..where(t.needsReview.equals(true) & t.deletedAt.isNull());
    return q.watchSingle().map((r) => r.read(count) ?? 0);
  }
}

/// Quy tắc, từ khoá và công tắc, đọc sẵn cho một lượt phân loại.
class CategorizerData {
  const CategorizerData({
    required this.rules,
    required this.keywords,
    this.useSimilar = true,
    this.useKeywords = true,
  });

  final List<RuleEntry> rules;
  final List<KeywordEntry> keywords;
  final bool useSimilar;
  final bool useKeywords;

  CategoryGuess guess(String receiverKey, String flow) => categorize(
    receiverKey: receiverKey,
    flow: flow,
    rules: rules,
    keywords: keywords,
    useSimilar: useSimilar,
    useKeywords: useKeywords,
  );
}

class _TxSnapshot {
  const _TxSnapshot(
    this.txId,
    this.categoryId,
    this.needsReview,
    this.eventId,
    this.source,
  );
  final int txId;
  final int? categoryId;
  final bool needsReview;
  final int? eventId;
  final String? source;
}

/// Kết quả một lần học, đủ để hoàn tác.
class LearnResult {
  const LearnResult._({
    required this.receiverName,
    required this.appliedToOthers,
    required List<_TxSnapshot> before,
    required this.ruleBefore,
    required this.ruleCreated,
    required this.ruleKey,
    required this.ruleFlow,
  }) : _before = before;

  /// Tên người nhận để hiện trong thông báo.
  final String receiverName;

  /// Số giao dịch KHÁC của cùng người nhận được phân loại theo.
  final int appliedToOthers;

  final List<_TxSnapshot> _before;
  final ReceiverRule? ruleBefore;
  final bool ruleCreated;
  final String ruleKey;
  final String ruleFlow;
}

/// Một dòng trong hàng chờ phân loại.
class ReviewItem {
  const ReviewItem({
    required this.transactionId,
    required this.kind,
    required this.amount,
    required this.occurredAt,
    required this.receiverKey,
    this.note,
    this.categoryId,
    this.categoryName,
    this.source,
    this.reason,
    this.walletName,
  });

  final int transactionId;
  final TxKind kind;
  final int amount;
  final DateTime occurredAt;
  final String? note;
  final int? categoryId;
  final String? categoryName;
  final String receiverKey;
  final CategorySource? source;
  final String? reason;
  final String? walletName;

  String get flow => kind == TxKind.income ? 'income' : 'expense';
  bool get isUncategorized => categoryId == null;
}

class RuleView {
  const RuleView({required this.rule, required this.categoryName});
  final ReceiverRule rule;
  final String categoryName;
}

class KeywordView {
  const KeywordView({
    required this.keyword,
    required this.categoryName,
    required this.flow,
  });
  final CategoryKeyword keyword;
  final String categoryName;
  final String flow;
}

/// Thông báo đã ghi gần nhất của một ví.
class LatestBankEvent {
  const LatestBankEvent({
    required this.eventId,
    required this.parserId,
    required this.title,
    required this.body,
    required this.occurredAt,
    required this.walletId,
    required this.walletName,
  });

  final int eventId;
  final String? parserId;
  final String title;
  final String body;
  final DateTime occurredAt;
  final int walletId;
  final String walletName;
}
