part of 'backup_service.dart';

extension BackupImport on BackupService {
  // ----- Nhập ----------------------------------------------------------

  /// Đọc thử file để xem có bao nhiêu dữ liệu, trước khi thực sự nhập.
  Future<BackupStats> peek(String jsonString) async {
    final data = _decodeAndValidate(jsonString);
    return BackupStats(
      wallets: (data['wallets'] as List).length,
      categories: (data['categories'] as List).length,
      people: (data['people'] as List).length,
      transactions: (data['transactions'] as List).length,
      budgets: (data['budgets'] as List?)?.length ?? 0,
      funds: (data['funds'] as List?)?.length ?? 0,
      templates: (data['templates'] as List?)?.length ?? 0,
    );
  }

  /// Nạp dữ liệu từ file sao lưu.
  ///
  /// Chạy trọn trong một giao dịch cơ sở dữ liệu: lỗi giữa chừng thì mọi thứ
  /// quay lại như cũ, không để lại dữ liệu dở dang.
  ///
  /// Id trong file không được dùng lại mà ánh xạ sang id mới, vì ở chế độ gộp
  /// chúng gần như chắc chắn đụng với id đang có.
  Future<ImportResult> import(
    String jsonString, {
    required ImportMode mode,
  }) async {
    final data = _decodeAndValidate(jsonString);

    final walletRows = (data['wallets'] as List).cast<Map<String, dynamic>>();
    final categoryRows = (data['categories'] as List)
        .cast<Map<String, dynamic>>();
    final peopleRows = (data['people'] as List).cast<Map<String, dynamic>>();
    final txRows = (data['transactions'] as List).cast<Map<String, dynamic>>();
    final budgetRows = ((data['budgets'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final fundRows = ((data['funds'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final templateRows = ((data['templates'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final billRows = ((data['billItems'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> listOf(String key) =>
        ((data[key] as List?) ?? const []).cast<Map<String, dynamic>>();
    final trackedRows = listOf('trackedApps');
    final accountWalletRows = listOf('accountWallets');
    final ruleRows = listOf('receiverRules');
    final keywordRows = listOf('categoryKeywords');
    // File cũ (trước v6) không có phần này.
    final hasKeywords = data.containsKey('categoryKeywords');

    // Kiểm tra trước khi đụng vào DB: chế độ ghi đè xoá sạch dữ liệu cũ, nên
    // file hỏng phải bị chặn từ đầu chứ không phải giữa chừng.
    _validateCategories(categoryRows);
    _validateTransactions(txRows, billRows);

    await db.transaction(() async {
      if (mode == ImportMode.replace) {
        // Xoá theo thứ tự ngược với phụ thuộc khoá ngoại.
        await db.delete(db.billItems).go();
        await db.delete(db.transactions).go();
        await db.delete(db.budgets).go();
        await db.delete(db.funds).go();
        await db.delete(db.expenseTemplates).go();
        await db.delete(db.wallets).go();
        await db.delete(db.categories).go();
        await db.delete(db.people).go();
      }

      final walletIds = <int, int>{};
      for (final row in walletRows) {
        walletIds[row['id'] as int] = await db
            .into(db.wallets)
            .insert(
              WalletsCompanion.insert(
                name: row['name'] as String,
                type: Value(row['type'] as String? ?? 'other'),
                initialBalance: Value(row['initialBalance'] as int? ?? 0),
                iconKey: Value(row['iconKey'] as String?),
                colorValue: Value(row['colorValue'] as int?),
                note: Value(row['note'] as String?),
                isArchived: Value(row['isArchived'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      final categoryIds = <int, int>{};
      for (final row in categoryRows) {
        categoryIds[row['id'] as int] = await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                name: row['name'] as String,
                flow: CategoryFlow.values.byName(row['flow'] as String),
                iconKey: Value(row['iconKey'] as String?),
                colorValue: Value(row['colorValue'] as int?),
                isArchived: Value(row['isArchived'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      final personIds = <int, int>{};
      for (final row in peopleRows) {
        personIds[row['id'] as int] = await db
            .into(db.people)
            .insert(
              PeopleCompanion.insert(
                name: row['name'] as String,
                phone: Value(row['phone'] as String?),
                note: Value(row['note'] as String?),
                avatarColor: Value(row['avatarColor'] as int?),
                isArchived: Value(row['isArchived'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      final fundIds = <int, int>{};
      // Ví giữ từng quỹ (theo id mới), để tính lại chiều tiền của quỹ.
      final fundWallets = <int, int>{};
      for (final row in fundRows) {
        final walletId = walletIds[row['walletId']];
        if (walletId == null) continue;
        final newId = fundIds[row['id'] as int] = await db
            .into(db.funds)
            .insert(
              FundsCompanion.insert(
                name: row['name'] as String,
                walletId: walletId,
                targetAmount: Value(row['targetAmount'] as int?),
                dueDayKey: Value(row['dueDayKey'] as int?),
                note: Value(row['note'] as String?),
                iconKey: Value(row['iconKey'] as String?),
                colorValue: Value(row['colorValue'] as int?),
                isArchived: Value(row['isArchived'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
        fundWallets[newId] = walletId;
      }

      final txIds = <int, int>{};
      // Giao dịch tất toán có thể đứng trước hoặc sau khoản nợ gốc trong file,
      // nên chèn hết giao dịch trước rồi mới nối lại settles_tx_id theo id mới.
      final pendingSettles = <(int newTxId, int oldTargetId)>[];
      // Nhóm cũng ánh xạ sang mã mới như id: gộp cùng một file hai lần thì
      // hai cặp trả dùm không được dính vào nhau, xoá một cặp là mất cả hai.
      final groupIds = <String, String>{};
      for (final row in txRows) {
        final kind = TxKindX.fromId(row['kind'] as String);
        final amount = row['amount'] as int;
        final occurredAt = row['occurredAt'] as int;
        final local = DateTime.fromMillisecondsSinceEpoch(occurredAt);
        final walletFromId = walletIds[row['walletFromId']];
        final walletToId = walletIds[row['walletToId']];
        final fundId = fundIds[row['fundId']];
        var personId = personIds[row['personId']];
        // Trước khi có "người khác trả dùm", người gắn trên khoản chi không
        // mang nghĩa nợ. Khoản chi đã trừ ví / quỹ mà vẫn có người là dữ liệu
        // kiểu cũ: bỏ người đi, nếu không sẽ vừa trừ ví vừa ghi nợ.
        if (kind.canBePaidByOther &&
            (walletFromId != null || walletToId != null || fundId != null)) {
          personId = null;
        }
        // Tính lại từ chân ví như lúc ghi. File chỉ được hỏi đúng một điều mà
        // chân ví không trả lời được: nạp / rút ngay trong ví giữ quỹ là chiều
        // nào. File cũ không có trường này thì cũng không có trường hợp đó.
        final fileDelta = row['fundDelta'] as int? ?? 0;
        final fundDelta = fundId == null
            ? 0
            : fundDeltaOf(
                amount: amount,
                fundWalletId: fundWallets[fundId]!,
                walletFromId: walletFromId,
                walletToId: walletToId,
                intoFund: fileDelta == 0 ? null : fileDelta > 0,
              );

        final newTxId = txIds[row['id'] as int] = await db
            .into(db.transactions)
            .insert(
              TransactionsCompanion.insert(
                kind: kind,
                amount: amount,
                occurredAt: occurredAt,
                // Tính lại từ thời điểm thay vì tin vào file: nếu máy nguồn ở
                // múi giờ khác thì khoá tháng cũ sẽ sai với máy này.
                dayKey: dayKeyOf(local),
                monthKey: monthKeyOf(local),
                walletFromId: Value(walletFromId),
                walletToId: Value(walletToId),
                categoryId: Value(categoryIds[row['categoryId']]),
                personId: Value(personId),
                fundId: Value(fundId),
                fundDelta: Value(fundDelta),
                // Tính lại từ kind, không tin số trong file.
                debtDelta: Value(
                  kind.debtDelta(amount, hasPerson: personId != null),
                ),
                note: Value(row['note'] as String?),
                groupId: Value(
                  row['groupId'] == null
                      ? null
                      : groupIds.putIfAbsent(
                          row['groupId'] as String,
                          () => const Uuid().v4(),
                        ),
                ),
                isWriteoff: Value(row['isWriteoff'] as bool? ?? false),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
                deletedAt: Value(row['deletedAt'] as int?),
                // Thông báo thô không đi theo file nên không còn gì để nối
                // auto_event_id; chỉ giữ việc còn chờ xem lại hay không.
                needsReview: Value(row['needsReview'] as bool? ?? false),
              ),
            );
        final oldSettlesId = row['settlesTxId'];
        if (oldSettlesId is int) {
          pendingSettles.add((newTxId, oldSettlesId));
        }
      }

      for (final (newTxId, oldTargetId) in pendingSettles) {
        final newTargetId = txIds[oldTargetId];
        if (newTargetId == null) continue;
        await (db.update(db.transactions)..where((t) => t.id.equals(newTxId)))
            .write(TransactionsCompanion(settlesTxId: Value(newTargetId)));
      }

      for (final row in billRows) {
        final txId = txIds[row['transactionId']];
        final unitPrice = row['unitPrice'] as int? ?? 0;
        if (txId == null || unitPrice <= 0) continue;
        await db
            .into(db.billItems)
            .insert(
              BillItemsCompanion.insert(
                transactionId: txId,
                name: row['name'] as String? ?? '',
                quantity: Value(row['quantity'] as int? ?? 1),
                unitPrice: unitPrice,
                isDiscount: Value(row['isDiscount'] as bool? ?? false),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
              ),
            );
      }

      for (final row in budgetRows) {
        final categoryId = categoryIds[row['categoryId']];
        if (categoryId == null) continue;
        await db
            .into(db.budgets)
            .insert(
              BudgetsCompanion.insert(
                categoryId: categoryId,
                monthKey: Value(row['monthKey'] as int?),
                limitAmount: row['limitAmount'] as int,
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      for (final row in templateRows) {
        final amount = row['amount'] as int?;
        await db
            .into(db.expenseTemplates)
            .insert(
              ExpenseTemplatesCompanion.insert(
                note: Value(row['note'] as String?),
                // Không tin số âm hay bằng 0 trong file: mẫu chỉ có số dương
                // hoặc để trống.
                amount: Value(amount != null && amount > 0 ? amount : null),
                walletId: Value(walletIds[row['walletId']]),
                categoryId: Value(categoryIds[row['categoryId']]),
                sortOrder: Value(row['sortOrder'] as int? ?? 0),
                createdAt: row['createdAt'] as int? ?? 0,
                updatedAt: row['updatedAt'] as int? ?? 0,
              ),
            );
      }

      await _importAutoTrack(
        mode: mode,
        walletIds: walletIds,
        categoryIds: categoryIds,
        trackedRows: trackedRows,
        accountWalletRows: accountWalletRows,
        ruleRows: ruleRows,
        keywordRows: keywordRows,
        hasKeywords: hasKeywords,
      );
    });

    return ImportResult(
      mode: mode,
      stats: BackupStats(
        wallets: walletRows.length,
        categories: categoryRows.length,
        people: peopleRows.length,
        transactions: txRows.length,
        budgets: budgetRows.length,
        funds: fundRows.length,
        templates: templateRows.length,
      ),
    );
  }

  void _validateCategories(List<Map<String, dynamic>> categoryRows) {
    for (var i = 0; i < categoryRows.length; i++) {
      final flow = categoryRows[i]['flow'];
      if (!CategoryFlow.values.any((f) => f.name == flow)) {
        throw BackupException(
          'Danh mục thứ ${i + 1} trong file có chiều "$flow" không hợp lệ.',
        );
      }
    }
  }

  /// Chặn những dòng giao dịch mà đường ghi thường ([Repository.addTransaction])
  /// không bao giờ tạo ra: số tiền không dương, loại lạ, hoá đơn lệch tổng.
  void _validateTransactions(
    List<Map<String, dynamic>> txRows,
    List<Map<String, dynamic>> billRows,
  ) {
    final billsByTx = <Object?, List<BillLine>>{};
    for (final row in billRows) {
      final unitPrice = row['unitPrice'] as int? ?? 0;
      // Dòng giá không dương vốn bị bỏ qua lúc nhập, nên cũng không đem so.
      if (unitPrice <= 0) continue;
      billsByTx.putIfAbsent(row['transactionId'], () => []).add(
        BillLine(
          name: row['name'] as String? ?? '',
          quantity: row['quantity'] as int? ?? 1,
          unitPrice: unitPrice,
          isDiscount: row['isDiscount'] as bool? ?? false,
        ),
      );
    }

    for (var i = 0; i < txRows.length; i++) {
      final row = txRows[i];
      final where = 'Giao dịch thứ ${i + 1} trong file';
      final kindId = row['kind'];
      if (!TxKind.values.any((k) => k.id == kindId)) {
        throw BackupException('$where có loại "$kindId" không hợp lệ.');
      }
      final amount = row['amount'];
      if (amount is! int || amount <= 0) {
        throw BackupException('$where có số tiền không hợp lệ ($amount).');
      }
      try {
        checkBill(amount, billsByTx[row['id']] ?? const []);
      } on ArgumentError catch (e) {
        throw BackupException('$where: ${e.message}');
      }
    }
  }

  /// Cài đặt tự động ghi và những gì đã học để phân loại.
  ///
  /// Ghi đè: thay bằng nội dung file. Gộp: thứ đang có trên máy thắng, file
  /// chỉ thêm những gì máy chưa có (ví nhận của ngân hàng, quy tắc trùng
  /// người nhận...).
  Future<void> _importAutoTrack({
    required ImportMode mode,
    required Map<int, int> walletIds,
    required Map<int, int> categoryIds,
    required List<Map<String, dynamic>> trackedRows,
    required List<Map<String, dynamic>> accountWalletRows,
    required List<Map<String, dynamic>> ruleRows,
    required List<Map<String, dynamic>> keywordRows,
    required bool hasKeywords,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (mode == ImportMode.replace) {
      // Danh mục đã xoá ở trên nên quy tắc và từ khoá cũng đã đi theo (khoá
      // ngoại cascade). Ví đã xoá nên ví nhận của ngân hàng thành trống.
      await (db.delete(
        db.trackedApps,
      )..where((t) => t.parserId.isNotNull())).go();
      if (!hasKeywords) {
        // File cũ không mang từ khoá: gieo lại từ khoá có sẵn theo tên danh
        // mục vừa nhập, ở lần đồng bộ tới.
        await (db.delete(db.settingsKv)
              ..where((s) => s.key.equals(AutoTrackRepository.kKeywordsSeededKey)))
            .go();
      }
    }

    for (final row in trackedRows) {
      final pkg = row['packageName'] as String?;
      final parserId = row['parserId'] as String?;
      if (pkg == null || parserId == null) continue;
      final existing = await (db.select(db.trackedApps)
            ..where((t) => t.packageName.equals(pkg)))
          .getSingleOrNull();
      if (existing != null && existing.parserId != null) continue;
      await db.into(db.trackedApps).insertOnConflictUpdate(
        TrackedAppsCompanion.insert(
          packageName: pkg,
          parserId: Value(parserId),
          label: Value(row['label'] as String?),
          enabled: Value(row['enabled'] as bool? ?? true),
          defaultWalletId: Value(walletIds[row['defaultWalletId']]),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    for (final row in accountWalletRows) {
      final walletId = walletIds[row['walletId']];
      final pkg = row['packageName'] as String?;
      final suffix = row['accountSuffix'] as String?;
      if (walletId == null || pkg == null || suffix == null) continue;
      final app = await (db.select(db.trackedApps)
            ..where((t) => t.packageName.equals(pkg)))
          .getSingleOrNull();
      if (app == null) continue;
      await db.into(db.accountWallets).insert(
        AccountWalletsCompanion.insert(
          packageName: pkg,
          accountSuffix: suffix,
          walletId: walletId,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    for (final row in ruleRows) {
      final categoryId = categoryIds[row['categoryId']];
      final key = row['matchKey'] as String?;
      final flow = CategoryFlow.values
          .where((f) => f.name == row['flow'])
          .firstOrNull;
      if (categoryId == null || key == null || key.isEmpty || flow == null) {
        continue;
      }
      await db.into(db.receiverRules).insert(
        ReceiverRulesCompanion.insert(
          matchType: row['matchType'] as String? ?? 'name',
          matchKey: key,
          flow: flow,
          displayName: row['displayName'] as String? ?? key,
          categoryId: categoryId,
          hitCount: Value(row['hitCount'] as int? ?? 0),
          lastUsedAt: Value(row['lastUsedAt'] as int?),
          createdAt: row['createdAt'] as int? ?? now,
          updatedAt: row['updatedAt'] as int? ?? now,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }

    for (final row in keywordRows) {
      final categoryId = categoryIds[row['categoryId']];
      final keyword = row['keyword'] as String?;
      if (categoryId == null || keyword == null || keyword.isEmpty) continue;
      await db.into(db.categoryKeywords).insert(
        CategoryKeywordsCompanion.insert(
          keyword: keyword,
          categoryId: categoryId,
          isBuiltIn: Value(row['isBuiltIn'] as bool? ?? false),
          enabled: Value(row['enabled'] as bool? ?? true),
          createdAt: row['createdAt'] as int? ?? now,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
    if (hasKeywords) {
      await db.into(db.settingsKv).insertOnConflictUpdate(
        SettingsKvCompanion.insert(
          key: AutoTrackRepository.kKeywordsSeededKey,
          value: 'true',
        ),
      );
    }
  }

  Map<String, dynamic> _decodeAndValidate(String jsonString) {
    late final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException {
      throw const BackupException(
        'File không đọc được. Hãy chọn đúng file .json do app này xuất ra.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const BackupException('File sao lưu không đúng định dạng.');
    }
    if (decoded['app'] != 'MoneyBook') {
      throw const BackupException(
        'File này không phải bản sao lưu của Quản Lý Chi Tiêu.',
      );
    }

    final version = decoded['formatVersion'];
    if (version is! int) {
      throw const BackupException('File sao lưu thiếu thông tin phiên bản.');
    }
    if (version > kBackupFormatVersion) {
      throw BackupException(
        'File này được tạo bởi phiên bản app mới hơn (v$version). '
        'Hãy cập nhật app rồi thử lại.',
      );
    }

    for (final key in ['wallets', 'categories', 'people', 'transactions']) {
      if (decoded[key] is! List) {
        throw BackupException('File sao lưu thiếu phần "$key".');
      }
    }

    return decoded;
  }
}
