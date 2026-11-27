part of 'repository.dart';

// ----- Giao dịch ------------------------------------------------------

extension TransactionQueries on Repository {
  /// Danh sách giao dịch, đã ghép sẵn tên ví / danh mục / người.
  ///
  /// Dùng một câu SQL với các phép join trái, để Drift chỉ phải theo dõi một
  /// truy vấn duy nhất và phát lại đúng một lần khi có thay đổi.
  Stream<List<TxView>> watchTransactions({
    int? limit,
    int? walletId,
    int? personId,
    int? categoryId,
    bool uncategorized = false,
    int? monthKey,
    TxKind? kind,
  }) {
    final where = <String>['t.deleted_at IS NULL'];
    final vars = <Variable>[];

    if (walletId != null) {
      where.add('(t.wallet_from_id = ? OR t.wallet_to_id = ?)');
      vars
        ..add(Variable.withInt(walletId))
        ..add(Variable.withInt(walletId));
    }
    if (personId != null) {
      where.add('t.person_id = ?');
      vars.add(Variable.withInt(personId));
    }
    if (categoryId != null) {
      where.add('t.category_id = ?');
      vars.add(Variable.withInt(categoryId));
    }
    if (uncategorized) {
      where.add('t.category_id IS NULL');
    }
    if (monthKey != null) {
      where.add('t.month_key = ?');
      vars.add(Variable.withInt(monthKey));
    }
    if (kind != null) {
      where.add('t.kind = ?');
      vars.add(Variable.withString(kind.name));
    }

    final sql =
        '''
      ${Repository._txViewSelect}
      WHERE ${where.join(' AND ')}
      ORDER BY t.occurred_at DESC, t.id DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''';

    final query = db.customSelect(
      sql,
      variables: vars,
      readsFrom: _txViewTables,
    );

    // Khi không có bộ lọc cắt bớt lịch sử của một người (toàn bộ giao dịch,
    // hoặc toàn bộ giao dịch của một người), kết quả đã đủ mọi dòng nợ của
    // từng người nên phân bổ thẳng trong bộ nhớ mà không cần truy vấn thêm.
    final hasFullPersonHistory = limit == null &&
        walletId == null &&
        categoryId == null &&
        !uncategorized &&
        monthKey == null &&
        kind == null;

    if (hasFullPersonHistory) {
      return query.watch().map((rows) {
        final txs = [for (final row in rows) db.transactions.map(row.data)];
        final remaining = _allocateGroupedByPerson(txs);
        return [
          for (var i = 0; i < rows.length; i++)
            _rowToTxView(rows[i], debtRemaining: remaining[txs[i].id]),
        ];
      });
    }

    return query.watch().asyncMap((rows) async {
      final txs = [for (final row in rows) db.transactions.map(row.data)];
      final personIds = <int>{
        for (final tx in txs)
          if (tx.personId != null &&
              tx.debtDelta != 0 &&
              tx.settlesTxId == null)
            tx.personId!,
      };
      final remaining = await _allocateDebtsForPeople(personIds);
      return [
        for (var i = 0; i < rows.length; i++)
          _rowToTxView(rows[i], debtRemaining: remaining[txs[i].id]),
      ];
    });
  }

  /// Một giao dịch theo id, kể cả đã xoá mềm. Null nếu không có.
  Future<TxView?> getTransaction(int id) async {
    final row = await _txByIdQuery(id).getSingleOrNull();
    if (row == null) return null;
    return _rowToTxViewWithDebt(row);
  }

  /// Một giao dịch, phát lại khi nó (hoặc ví, danh mục, người của nó) đổi.
  Stream<TxView?> watchTransactionById(int id) => _txByIdQuery(id)
      .watchSingleOrNull()
      .asyncMap(
        (row) => row == null ? Future.value(null) : _rowToTxViewWithDebt(row),
      );

  Future<TxView> _rowToTxViewWithDebt(QueryRow row) async {
    final tx = db.transactions.map(row.data);
    if (tx.deletedAt != null ||
        tx.debtDelta == 0 ||
        tx.settlesTxId != null ||
        tx.personId == null) {
      return _rowToTxView(row);
    }
    final remaining = await _allocateDebtsForPerson(tx.personId!);
    return _rowToTxView(row, debtRemaining: remaining[tx.id]);
  }

  Selectable<QueryRow> _txByIdQuery(int id) => db.customSelect(
    '${Repository._txViewSelect} WHERE t.id = ?',
    variables: [Variable.withInt(id)],
    readsFrom: _txViewTables,
  );

  /// Thêm giao dịch.
  ///
  /// `debtDelta`, `fundDelta` và các khoá ngày tháng được suy ra tự động từ
  /// [kind], chân ví và [occurredAt], để không nơi nào khác trong app phải tự
  /// tính dấu. [intoFund] chỉ cần khi cả hai chân là ví giữ quỹ — xem
  /// [fundDeltaOf].
  Future<int> addTransaction({
    required TxKind kind,
    required int amount,
    required DateTime occurredAt,
    int? walletFromId,
    int? walletToId,
    int? categoryId,
    int? personId,
    int? fundId,
    bool? intoFund,
    String? note,
    String? groupId,
    int? recurringId,
    bool isWriteoff = false,
    int? settlesTxId,
    List<BillLine> bill = const [],
    int? autoEventId,
    bool needsReview = false,
  }) async {
    assert(amount > 0, 'amount phải dương, dấu suy ra từ kind');
    checkBill(amount, bill);
    checkPaidByOther(kind, personId, walletFromId, walletToId, fundId);
    final now = _now();
    final fundDelta = await _fundDeltaFor(
      fundId: fundId,
      amount: amount,
      walletFromId: walletFromId,
      walletToId: walletToId,
      intoFund: intoFund,
    );
    return db.transaction(() async {
      if (settlesTxId != null) {
        final target = await (db.select(
          db.transactions,
        )..where((t) => t.id.equals(settlesTxId))).getSingleOrNull();
        if (target == null || target.deletedAt != null) {
          throw ArgumentError(
            'Khoản nợ cần tất toán không tồn tại hoặc đã bị xoá',
          );
        }
        if (target.debtDelta == 0 || target.settlesTxId != null) {
          throw ArgumentError(
            'Giao dịch này không phải khoản nợ có thể tất toán',
          );
        }
        final remaining = target.personId == null
            ? 0
            : (await _allocateDebtsForPerson(target.personId!))[settlesTxId] ??
                  0;
        if (amount > remaining) {
          throw ArgumentError(
            'Số tiền tất toán ($amount) vượt quá phần còn lại ($remaining)',
          );
        }
      }
      final id = await db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              kind: kind,
              amount: amount,
              occurredAt: occurredAt.millisecondsSinceEpoch,
              dayKey: dayKeyOf(occurredAt),
              monthKey: monthKeyOf(occurredAt),
              walletFromId: Value(walletFromId),
              walletToId: Value(walletToId),
              categoryId: Value(categoryId),
              personId: Value(personId),
              fundId: Value(fundId),
              fundDelta: Value(fundDelta),
              debtDelta: Value(
                kind.debtDelta(amount, hasPerson: personId != null),
              ),
              note: Value(note),
              groupId: Value(groupId),
              recurringId: Value(recurringId),
              isWriteoff: Value(isWriteoff),
              settlesTxId: Value(settlesTxId),
              autoEventId: Value(autoEventId),
              needsReview: Value(needsReview),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _writeBill(id, bill);
      return id;
    });
  }

  /// [bill] null thì giữ nguyên hoá đơn đang có; danh sách rỗng là bỏ hoá
  /// đơn.
  Future<void> updateTransaction({
    required int id,
    required TxKind kind,
    required int amount,
    required DateTime occurredAt,
    int? walletFromId,
    int? walletToId,
    int? categoryId,
    int? personId,
    int? fundId,
    String? note,
    List<BillLine>? bill,
  }) async {
    assert(amount > 0);
    if (bill != null) checkBill(amount, bill);
    checkPaidByOther(kind, personId, walletFromId, walletToId, fundId);
    // Nạp / rút ngay trong ví giữ quỹ không suy được chiều từ chân ví, nên giữ
    // chiều cũ của chính giao dịch này.
    final old = await (db.select(db.transactions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    final fundDelta = await _fundDeltaFor(
      fundId: fundId,
      amount: amount,
      walletFromId: walletFromId,
      walletToId: walletToId,
      intoFund: old == null || old.fundDelta == 0 ? null : old.fundDelta > 0,
    );
    await db.transaction(() async {
      await (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          kind: Value(kind),
          amount: Value(amount),
          occurredAt: Value(occurredAt.millisecondsSinceEpoch),
          dayKey: Value(dayKeyOf(occurredAt)),
          monthKey: Value(monthKeyOf(occurredAt)),
          walletFromId: Value(walletFromId),
          walletToId: Value(walletToId),
          categoryId: Value(categoryId),
          personId: Value(personId),
          fundId: Value(fundId),
          fundDelta: Value(fundDelta),
          debtDelta: Value(kind.debtDelta(amount, hasPerson: personId != null)),
          note: Value(note),
          // Mở ra sửa rồi bấm lưu tức là đã xem lại.
          needsReview: const Value(false),
          updatedAt: Value(_now()),
        ),
      );
      if (bill != null) await _writeBill(id, bill);
    });
  }

  /// Xoá mềm, để còn hoàn tác được.
  Future<void> softDeleteTransaction(int id) =>
      (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(deletedAt: Value(_now())),
      );

  Future<void> restoreTransaction(int id) =>
      (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
        const TransactionsCompanion(deletedAt: Value(null)),
      );

  /// Xoá cả nhóm giao dịch sinh cùng lúc (ví dụ cặp giao dịch của trả dùm).
  /// Trả về danh sách id để hoàn tác.
  Future<List<int>> softDeleteGroup(String groupId) async {
    final rows = await (db.select(
      db.transactions,
    )..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull())).get();
    await (db.update(db.transactions)
          ..where((t) => t.groupId.equals(groupId) & t.deletedAt.isNull()))
        .write(TransactionsCompanion(deletedAt: Value(_now())));
    return rows.map((r) => r.id).toList();
  }

  Future<void> restoreMany(List<int> ids) =>
      (db.update(db.transactions)..where((t) => t.id.isIn(ids))).write(
        const TransactionsCompanion(deletedAt: Value(null)),
      );

  Future<int> countInGroup(String groupId) async {
    final t = db.transactions;
    final countExp = t.id.count();
    final q = db.selectOnly(t)
      ..addColumns([countExp])
      ..where(t.groupId.equals(groupId) & t.deletedAt.isNull());
    return (await q.getSingle()).read(countExp) ?? 0;
  }

  /// Ghi một bữa trả dùm: mình trả trước toàn bộ, những người khác nợ lại
  /// phần của họ.
  ///
  /// Sinh ra nhiều giao dịch cùng một [groupId]:
  ///   * một khoản chi đúng bằng phần của mình — chỉ phần này mới vào thống kê
  ///     và ngân sách, nên một bữa 200k chia bốn chỉ tính 50k tiền ăn;
  ///   * mỗi người một khoản cho mượn bằng phần của họ, vào sổ nợ.
  ///
  /// Tổng tiền rời ví vẫn đúng bằng số đã trả. Bỏ qua phần của tôi nếu bằng 0
  /// (trường hợp trả hộ hoàn toàn, mình không ăn).
  ///
  /// Trả về id của các giao dịch đã tạo.
  Future<List<int>> addSplitBill({
    required int walletFromId,
    required int myShare,
    required Map<int, int> sharesByPerson,
    required DateTime occurredAt,
    int? categoryId,
    String? note,
  }) async {
    assert(myShare >= 0);
    assert(sharesByPerson.values.every((v) => v > 0));

    final groupId = _uuid();
    final ids = <int>[];

    await db.transaction(() async {
      if (myShare > 0) {
        ids.add(
          await addTransaction(
            kind: TxKind.expense,
            amount: myShare,
            occurredAt: occurredAt,
            walletFromId: walletFromId,
            categoryId: categoryId,
            note: note,
            groupId: groupId,
          ),
        );
      }
      for (final entry in sharesByPerson.entries) {
        ids.add(
          await addTransaction(
            kind: TxKind.lend,
            amount: entry.value,
            occurredAt: occurredAt,
            walletFromId: walletFromId,
            personId: entry.key,
            note: note == null ? 'Trả dùm' : '$note (trả dùm)',
            groupId: groupId,
          ),
        );
      }
    });

    return ids;
  }

  /// Điều chỉnh số dư ví cho khớp thực tế.
  ///
  /// Không sửa thẳng số dư ban đầu mà ghi một giao dịch chênh lệch, để lịch sử
  /// vẫn giải thích được vì sao số dư nhảy. Trả về null nếu không có chênh
  /// lệch nào.
  Future<int?> adjustWalletBalance({
    required int walletId,
    required int newBalance,
    String? note,
  }) async {
    final current = await balanceOf(walletId);
    final delta = newBalance - current;
    if (delta == 0) return null;

    return addTransaction(
      kind: TxKind.adjust,
      amount: delta.abs(),
      occurredAt: DateTime.now(),
      walletFromId: delta < 0 ? walletId : null,
      walletToId: delta > 0 ? walletId : null,
      note: note ?? 'Điều chỉnh số dư',
    );
  }
}
