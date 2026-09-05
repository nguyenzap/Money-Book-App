import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/domain/tx_kind.dart';

void main() {
  group('debtDelta - dấu công nợ', () {
    // Quy ước: > 0 nghĩa là "người đó nợ tôi thêm", < 0 là "tôi nợ họ thêm".
    test('cho mượn / trả dùm => họ nợ tôi thêm', () {
      expect(TxKind.lend.debtDelta(200000), 200000);
    });

    test('thu nợ => họ nợ tôi ít đi', () {
      expect(TxKind.collect.debtDelta(200000), -200000);
    });

    test('vay nợ => tôi nợ họ thêm', () {
      expect(TxKind.borrow.debtDelta(1000000), -1000000);
    });

    test('trả nợ => tôi nợ họ ít đi', () {
      expect(TxKind.repay.debtDelta(400000), 400000);
    });

    test('các loại không liên quan tới nợ luôn cho 0', () {
      for (final kind in [
        TxKind.income,
        TxKind.expense,
        TxKind.transfer,
        TxKind.adjust,
      ]) {
        expect(TxKind.values.contains(kind), isTrue);
        expect(kind.debtDelta(999999), 0, reason: 'kind = ${kind.name}');
      }
    });

    test('cho mượn rồi thu lại đúng bằng đó thì về 0', () {
      final net = TxKind.lend.debtDelta(500000) +
          TxKind.collect.debtDelta(500000);
      expect(net, 0);
    });

    test('vay 1tr, trả 400k thì còn nợ 600k', () {
      final net =
          TxKind.borrow.debtDelta(1000000) + TxKind.repay.debtDelta(400000);
      expect(net, -600000, reason: 'âm nghĩa là tôi vẫn đang nợ họ');
    });

    test('vừa vay vừa cho mượn cùng một người thì bù trừ lẫn nhau', () {
      // Vay Nam 1tr, sau đó Nam mượn lại 200k => tôi còn nợ Nam 800k.
      final net =
          TxKind.borrow.debtDelta(1000000) + TxKind.lend.debtDelta(200000);
      expect(net, -800000);
    });
  });

  group('debtDelta - tính chất bất biến', () {
    test('chỉ 4 loại nợ mới sinh ra debtDelta khác 0', () {
      for (final kind in TxKind.values) {
        final delta = kind.debtDelta(100);
        expect(
          delta != 0,
          kind.isDebtKind,
          reason: '${kind.name}: isDebtKind=${kind.isDebtKind} '
              'nhưng debtDelta=$delta',
        );
      }
    });

    test('độ lớn của debtDelta luôn bằng amount', () {
      for (final kind in kDebtTxKinds) {
        expect(kind.debtDelta(123456).abs(), 123456, reason: kind.name);
      }
    });

    test('debtDelta tuyến tính theo amount', () {
      for (final kind in TxKind.values) {
        expect(
          kind.debtDelta(300),
          kind.debtDelta(100) * 3,
          reason: kind.name,
        );
      }
    });
  });

  group('yêu cầu về các trường của giao dịch', () {
    test('mỗi loại phải có ít nhất một chân ví', () {
      // Nếu không có ví nào thì giao dịch không ảnh hưởng số dư => vô nghĩa
      // (trừ trường hợp xoá nợ, được xử lý riêng bằng cờ isWriteoff).
      for (final kind in TxKind.values) {
        expect(
          kind.needsWalletFrom || kind.needsWalletTo,
          isTrue,
          reason: '${kind.name} không có chân ví nào',
        );
      }
    });

    test('chỉ chuyển ví và điều chỉnh mới đụng tới cả hai chân ví', () {
      // Chuyển ví dùng cả 2 chân CÙNG LÚC (rút ví này, bỏ vào ví kia).
      // Điều chỉnh thì dùng ĐÚNG MỘT trong 2, tuỳ số dư tăng hay giảm.
      // Các loại còn lại luôn cố định một chân duy nhất.
      for (final kind in TxKind.values) {
        if (kind == TxKind.transfer || kind == TxKind.adjust) continue;
        expect(
          kind.needsWalletFrom && kind.needsWalletTo,
          isFalse,
          reason: '${kind.name} không được dùng cả 2 chân ví',
        );
      }
      expect(TxKind.transfer.needsWalletFrom, isTrue);
      expect(TxKind.transfer.needsWalletTo, isTrue);
      expect(TxKind.adjust.needsWalletFrom, isTrue);
      expect(TxKind.adjust.needsWalletTo, isTrue);
    });

    test('chỉ thu nhập và chi tiêu mới cần danh mục', () {
      expect(TxKind.income.needsCategory, isTrue);
      expect(TxKind.expense.needsCategory, isTrue);
      for (final kind in TxKind.values) {
        if (kind == TxKind.income || kind == TxKind.expense) continue;
        expect(kind.needsCategory, isFalse, reason: kind.name);
      }
    });

    test('cần người <=> là loại nợ', () {
      for (final kind in TxKind.values) {
        expect(kind.needsPerson, kind.isDebtKind, reason: kind.name);
      }
      expect(kDebtTxKinds.every((k) => k.needsPerson), isTrue);
      expect(kDebtTxKinds.length, 4);
    });
  });

  group('thống kê', () {
    test('chỉ thu nhập và chi tiêu được tính vào thống kê', () {
      expect(TxKind.income.countsInStats, isTrue);
      expect(TxKind.expense.countsInStats, isTrue);
    });

    test('chuyển ví KHÔNG được tính là chi tiêu', () {
      // Chuyển tiền từ MB sang MoMo không làm mình nghèo đi.
      expect(TxKind.transfer.countsInStats, isFalse);
    });

    test('điều chỉnh số dư và các loại nợ KHÔNG vào thống kê', () {
      expect(TxKind.adjust.countsInStats, isFalse);
      for (final kind in kDebtTxKinds) {
        expect(kind.countsInStats, isFalse, reason: kind.name);
      }
    });
  });

  group('lưu trữ xuống DB', () {
    test('id chuyển đi chuyển lại không đổi', () {
      for (final kind in TxKind.values) {
        expect(TxKindX.fromId(kind.id), kind);
      }
    });

    test('id là chuỗi cố định - đổi là hỏng dữ liệu cũ', () {
      // Chốt cứng để lỡ có ai đổi tên enum thì test này gãy ngay.
      expect(TxKind.income.id, 'income');
      expect(TxKind.expense.id, 'expense');
      expect(TxKind.transfer.id, 'transfer');
      expect(TxKind.borrow.id, 'borrow');
      expect(TxKind.repay.id, 'repay');
      expect(TxKind.lend.id, 'lend');
      expect(TxKind.collect.id, 'collect');
      expect(TxKind.adjust.id, 'adjust');
      expect(TxKind.values.length, 8);
    });

    test('mọi loại đều có nhãn tiếng Việt', () {
      for (final kind in TxKind.values) {
        expect(kind.label, isNotEmpty, reason: kind.name);
        expect(kind.hint, isNotEmpty, reason: kind.name);
      }
    });
  });
}
