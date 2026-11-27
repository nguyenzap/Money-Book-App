import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/domain/tx_kind.dart';
import 'package:moneybook/features/transactions/tx_form_rules.dart';

/// Quy tắc của màn ghi giao dịch, chốt đúng như màn hình đang làm trước khi
/// tách khỏi State: trường nào hiện, đổi loại thì dọn gì, chọn thiếu gì, và
/// khi lưu thì gửi những id nào xuống.
void main() {
  const expense = TxForm(kind: TxKind.expense, walletFromId: 1, categoryId: 5);

  group('công tắc', () {
    test('chia tiền chỉ khi ghi mới khoản chi, không hoá đơn, không ai trả dùm',
        () {
      expect(expense.canSplit, isTrue);
      expect(expense.copyWithFlags(isEditing: true).canSplit, isFalse);
      expect(expense.copyWithFlags(billEnabled: true).canSplit, isFalse);
      expect(expense.copyWithFlags(paidByOther: true).canSplit, isFalse);
      expect(const TxForm(kind: TxKind.income).canSplit, isFalse);
      expect(expense.usesSplit, isFalse);
      expect(expense.copyWithFlags(splitEnabled: true).usesSplit, isTrue);
    });

    test('người khác trả dùm và chia tiền loại trừ nhau', () {
      final paid = expense.copyWithFlags(paidByOther: true);
      expect(paid.canPayByOther, isTrue);
      expect(paid.isPaidByOther, isTrue);
      final both = paid.copyWithFlags(splitEnabled: true);
      expect(both.canPayByOther, isFalse);
      expect(both.isPaidByOther, isFalse);
      expect(const TxForm(kind: TxKind.lend, paidByOther: true).isPaidByOther,
          isFalse);
    });

    test('hoá đơn chỉ với khoản chi không chia tiền', () {
      expect(expense.canBill, isTrue);
      expect(expense.usesBill, isFalse);
      expect(expense.copyWithFlags(billEnabled: true).usesBill, isTrue);
      expect(expense.copyWithFlags(splitEnabled: true).canBill, isFalse);
      expect(const TxForm(kind: TxKind.transfer).canBill, isFalse);
      // Sửa giao dịch vẫn được dùng hoá đơn.
      expect(expense.copyWithFlags(isEditing: true).canBill, isTrue);
    });

    test('lưu làm mẫu: ghi mới, khoản chi thường', () {
      expect(expense.canSaveAsTemplate, isTrue);
      for (final f in [
        expense.copyWithFlags(isEditing: true),
        expense.copyWithFlags(splitEnabled: true),
        expense.copyWithFlags(billEnabled: true),
        expense.copyWithFlags(paidByOther: true),
        const TxForm(kind: TxKind.income),
      ]) {
        expect(f.canSaveAsTemplate, isFalse);
      }
    });

    test('ô chọn quỹ: khoản chi không phải người khác trả', () {
      expect(expense.showsFundPicker, isTrue);
      expect(expense.copyWithFlags(paidByOther: true).showsFundPicker, isFalse);
      expect(const TxForm(kind: TxKind.transfer).showsFundPicker, isFalse);
    });

    test('chế độ Ghi nợ: ẩn chọn loại, hiện chọn người, tiêu đề Ghi nợ', () {
      final paid = expense.copyWithFlags(paidByOther: true);
      expect(paid.showsKindSelector, isFalse);
      expect(paid.showsPersonPicker, isTrue);
      expect(paid.title, 'Ghi nợ');
      expect(paid.copyWithFlags(isEditing: true).title, 'Ghi nợ');

      expect(expense.showsKindSelector, isTrue);
      expect(expense.showsPersonPicker, isFalse);
      expect(expense.title, 'Ghi giao dịch');
      expect(expense.copyWithFlags(isEditing: true).title, 'Sửa giao dịch');
      expect(const TxForm(kind: TxKind.lend).showsPersonPicker, isTrue);
    });
  });

  group('đổi loại', () {
    test('cùng loại thì không đổi gì', () {
      final f = expense.copyWithFlags(splitEnabled: true);
      expect(identical(f.afterKindChange(TxKind.expense), f), isTrue);
    });

    test('chi sang thu: ví đang chọn chuyển sang chân nhận, dọn chia tiền / quỹ',
        () {
      const f = TxForm(
        kind: TxKind.expense,
        walletFromId: 1,
        categoryId: 5,
        fundId: 9,
        splitEnabled: true,
        paidByOther: true,
      );
      final next = f.afterKindChange(TxKind.income);
      expect(next.kind, TxKind.income);
      expect(next.walletFromId, isNull);
      expect(next.walletToId, 1);
      expect(next.categoryId, 5, reason: 'thu nhập vẫn cần danh mục');
      expect(next.fundId, isNull);
      expect(next.splitEnabled, isFalse);
      expect(next.paidByOther, isFalse);
    });

    test('sang chuyển ví: giữ ví nguồn, không có thì lấy ví nhận', () {
      const income = TxForm(kind: TxKind.income, walletToId: 3, categoryId: 7);
      final t = income.afterKindChange(TxKind.transfer);
      expect(t.walletFromId, 3);
      expect(t.walletToId, isNull);
      expect(t.categoryId, isNull);

      final fromExpense = expense.afterKindChange(TxKind.transfer);
      expect(fromExpense.walletFromId, 1);
      expect(fromExpense.walletToId, isNull);
    });

    test('từ chuyển ví sang loại một chân: giữ ví nguồn', () {
      const t = TxForm(kind: TxKind.transfer, walletFromId: 1, walletToId: 2);
      final lend = t.afterKindChange(TxKind.lend);
      expect(lend.walletFromId, 1);
      expect(lend.walletToId, isNull);
      final borrow = t.afterKindChange(TxKind.borrow);
      expect(borrow.walletFromId, isNull);
      expect(borrow.walletToId, 1);
    });

    test('rời sổ nợ thì bỏ người, vào sổ nợ thì giữ', () {
      const lend = TxForm(kind: TxKind.lend, walletFromId: 1, personId: 4);
      expect(lend.afterKindChange(TxKind.expense).personId, isNull);
      expect(lend.afterKindChange(TxKind.repay).personId, 4);
    });

    test('điều chỉnh số dư dùng chân nguồn khi đến từ loại chân nguồn', () {
      final adj = expense.afterKindChange(TxKind.adjust);
      expect(adj.walletFromId, 1);
      expect(adj.walletToId, isNull);
    });
  });

  group('chọn thiếu', () {
    test('thiếu danh mục, thiếu người', () {
      expect(const TxForm(kind: TxKind.expense, walletFromId: 1)
          .validateSelection(), 'Hãy chọn danh mục');
      expect(const TxForm(kind: TxKind.lend, walletFromId: 1)
          .validateSelection(), 'Hãy chọn người');
    });

    test('người khác trả dùm thì chỉ cần người, không cần ví', () {
      const f = TxForm(kind: TxKind.expense, categoryId: 5, paidByOther: true);
      expect(f.validateSelection(), 'Hãy chọn người đã trả dùm');
      expect(
        const TxForm(
          kind: TxKind.expense,
          categoryId: 5,
          personId: 4,
          paidByOther: true,
        ).validateSelection(),
        isNull,
      );
    });

    test('chuyển ví', () {
      expect(const TxForm(kind: TxKind.transfer).validateSelection(),
          'Hãy chọn ví nguồn');
      expect(const TxForm(kind: TxKind.transfer, walletFromId: 1)
          .validateSelection(), 'Hãy chọn ví nhận');
      expect(
        const TxForm(kind: TxKind.transfer, walletFromId: 1, walletToId: 1)
            .validateSelection(),
        'Ví nguồn và ví nhận phải khác nhau',
      );
      expect(
        const TxForm(
          kind: TxKind.transfer,
          walletFromId: 1,
          walletToId: 1,
          fundId: 9,
        ).validateSelection(),
        isNull,
        reason: 'nạp / rút quỹ ngay trong ví giữ quỹ',
      );
    });

    test('thiếu ví', () {
      expect(const TxForm(kind: TxKind.expense, categoryId: 5)
          .validateSelection(), 'Hãy chọn ví');
      expect(const TxForm(kind: TxKind.income, categoryId: 5)
          .validateSelection(), 'Hãy chọn ví');
      expect(expense.validateSelection(), isNull);
    });
  });

  group('id gửi xuống khi lưu', () {
    test('khoản chi thường không mang người, kể cả còn sót', () {
      const f = TxForm(
        kind: TxKind.expense,
        walletFromId: 1,
        fundId: 9,
        personId: 4,
      );
      expect(f.walletFromIdToSave, 1);
      expect(f.fundIdToSave, 9);
      expect(f.personIdToSave, isNull);
    });

    test('người khác trả dùm: không ví, không quỹ, có người', () {
      const f = TxForm(
        kind: TxKind.expense,
        walletFromId: 1,
        fundId: 9,
        personId: 4,
        paidByOther: true,
      );
      expect(f.walletFromIdToSave, isNull);
      expect(f.fundIdToSave, isNull);
      expect(f.personIdToSave, 4);
    });

    test('loại nợ luôn mang người', () {
      const f = TxForm(kind: TxKind.lend, walletFromId: 1, personId: 4);
      expect(f.personIdToSave, 4);
      expect(f.walletFromIdToSave, 1);
    });
  });
}
