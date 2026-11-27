part of 'backup_service.dart';

extension BackupExport on BackupService {
  // ----- Xuất ----------------------------------------------------------

  /// Dựng nội dung file sao lưu dạng JSON.
  Future<String> buildJson() async {
    final wallets = await db.select(db.wallets).get();
    final categories = await db.select(db.categories).get();
    final people = await db.select(db.people).get();
    final transactions = await db.select(db.transactions).get();
    final budgets = await db.select(db.budgets).get();
    final funds = await db.select(db.funds).get();
    final templates = await db.select(db.expenseTemplates).get();
    final billItems = await db.select(db.billItems).get();
    // Tự động ghi (v6). KHÔNG xuất notification_events: thông báo thô chứa số
    // tài khoản và số dư, lại chỉ dùng để gỡ lỗi.
    final trackedApps = await (db.select(
      db.trackedApps,
    )..where((t) => t.parserId.isNotNull())).get();
    final accountWallets = await db.select(db.accountWallets).get();
    final rules = await db.select(db.receiverRules).get();
    final keywords = await db.select(db.categoryKeywords).get();


    final data = <String, dynamic>{
      'formatVersion': kBackupFormatVersion,
      'schemaVersion': db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'MoneyBook',
      'wallets': wallets.map(_walletToMap).toList(),
      'categories': categories.map(_categoryToMap).toList(),
      'people': people.map(_personToMap).toList(),
      'transactions': transactions.map(_transactionToMap).toList(),
      'budgets': budgets.map(_budgetToMap).toList(),
      'funds': funds.map(_fundToMap).toList(),
      'templates': templates.map(_templateToMap).toList(),
      'billItems': billItems.map(_billItemToMap).toList(),
      'trackedApps': [
        for (final a in trackedApps)
          {
            'packageName': a.packageName,
            'parserId': a.parserId,
            'label': a.label,
            'enabled': a.enabled,
            'defaultWalletId': a.defaultWalletId,
          },
      ],
      'accountWallets': [
        for (final a in accountWallets)
          {
            'packageName': a.packageName,
            'accountSuffix': a.accountSuffix,
            'walletId': a.walletId,
          },
      ],
      'receiverRules': [
        for (final r in rules)
          {
            'matchType': r.matchType,
            'matchKey': r.matchKey,
            'flow': r.flow.name,
            'displayName': r.displayName,
            'categoryId': r.categoryId,
            'hitCount': r.hitCount,
            'lastUsedAt': r.lastUsedAt,
            'createdAt': r.createdAt,
            'updatedAt': r.updatedAt,
          },
      ],
      'categoryKeywords': [
        for (final k in keywords)
          {
            'keyword': k.keyword,
            'categoryId': k.categoryId,
            'isBuiltIn': k.isBuiltIn,
            'enabled': k.enabled,
            'createdAt': k.createdAt,
          },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Ghi file JSON vào thư mục tạm và trả về đường dẫn để chia sẻ.
  Future<File> writeJsonFile() async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final name =
        'moneybook_${dayKeyOf(now)}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}.json';
    final file = File(p.join(dir.path, name));
    await file.writeAsString(await buildJson(), encoding: utf8);
    return file;
  }

  Map<String, dynamic> _walletToMap(Wallet w) => {
    'id': w.id,
    'name': w.name,
    'type': w.type,
    'initialBalance': w.initialBalance,
    'iconKey': w.iconKey,
    'colorValue': w.colorValue,
    'note': w.note,
    'isArchived': w.isArchived,
    'sortOrder': w.sortOrder,
    'createdAt': w.createdAt,
    'updatedAt': w.updatedAt,
  };

  Map<String, dynamic> _categoryToMap(Category c) => {
    'id': c.id,
    'name': c.name,
    'flow': c.flow.name,
    'iconKey': c.iconKey,
    'colorValue': c.colorValue,
    'isArchived': c.isArchived,
    'sortOrder': c.sortOrder,
    'createdAt': c.createdAt,
    'updatedAt': c.updatedAt,
  };

  Map<String, dynamic> _personToMap(Person p) => {
    'id': p.id,
    'name': p.name,
    'phone': p.phone,
    'note': p.note,
    'avatarColor': p.avatarColor,
    'isArchived': p.isArchived,
    'sortOrder': p.sortOrder,
    'createdAt': p.createdAt,
    'updatedAt': p.updatedAt,
  };

  Map<String, dynamic> _transactionToMap(Transaction t) => {
    'id': t.id,
    'kind': t.kind.id,
    'amount': t.amount,
    'occurredAt': t.occurredAt,
    'dayKey': t.dayKey,
    'monthKey': t.monthKey,
    'walletFromId': t.walletFromId,
    'walletToId': t.walletToId,
    'categoryId': t.categoryId,
    'personId': t.personId,
    'fundId': t.fundId,
    'fundDelta': t.fundDelta,
    'debtDelta': t.debtDelta,
    'note': t.note,
    'groupId': t.groupId,
    'isWriteoff': t.isWriteoff,
    'settlesTxId': t.settlesTxId,
    'createdAt': t.createdAt,
    'updatedAt': t.updatedAt,
    'deletedAt': t.deletedAt,
    'needsReview': t.needsReview,
  };

  Map<String, dynamic> _fundToMap(Fund f) => {
    'id': f.id,
    'name': f.name,
    'walletId': f.walletId,
    'targetAmount': f.targetAmount,
    'dueDayKey': f.dueDayKey,
    'note': f.note,
    'iconKey': f.iconKey,
    'colorValue': f.colorValue,
    'isArchived': f.isArchived,
    'sortOrder': f.sortOrder,
    'createdAt': f.createdAt,
    'updatedAt': f.updatedAt,
  };

  Map<String, dynamic> _templateToMap(ExpenseTemplate t) => {
    'id': t.id,
    'note': t.note,
    'amount': t.amount,
    'walletId': t.walletId,
    'categoryId': t.categoryId,
    'sortOrder': t.sortOrder,
    'createdAt': t.createdAt,
    'updatedAt': t.updatedAt,
  };

  Map<String, dynamic> _billItemToMap(BillItem b) => {
    'id': b.id,
    'transactionId': b.transactionId,
    'name': b.name,
    'quantity': b.quantity,
    'unitPrice': b.unitPrice,
    'isDiscount': b.isDiscount,
    'sortOrder': b.sortOrder,
  };

  Map<String, dynamic> _budgetToMap(Budget b) => {
    'id': b.id,
    'categoryId': b.categoryId,
    'monthKey': b.monthKey,
    'limitAmount': b.limitAmount,
    'createdAt': b.createdAt,
    'updatedAt': b.updatedAt,
  };
}
