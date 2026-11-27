import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/domain/debt_allocation.dart';

void main() {
  int signedSum(Iterable<DebtRow> rows, Map<int, int> allocated) {
    var total = 0;
    for (final r in rows) {
      if (r.deletedAt != null || r.debtDelta == 0) continue;
      final rem = allocated[r.id];
      if (rem == null) continue;
      total += r.debtDelta > 0 ? rem : -rem;
    }
    return total;
  }

  group('allocateDebts', () {
    test('tất toán toàn bộ không gắn đích đóng hết các khoản nợ', () {
      final rows = [
        const DebtRow(id: 1, occurredAt: 100, debtDelta: 200000),
        const DebtRow(id: 2, occurredAt: 200, debtDelta: 300000),
        const DebtRow(id: 3, occurredAt: 300, debtDelta: -500000),
      ];

      final res = allocateDebts(rows);

      expect(res, {1: 0, 2: 0, 3: 0});
      expect(signedSum(rows, res), 0);
    });

    test('trả một phần không gắn đích đóng khoản cũ nhất trước (FIFO)', () {
      final rows = [
        // Cố ý truyền ngược thứ tự thời gian để kiểm tra bước sắp xếp.
        const DebtRow(id: 3, occurredAt: 300, debtDelta: -250000),
        const DebtRow(id: 2, occurredAt: 200, debtDelta: 300000),
        const DebtRow(id: 1, occurredAt: 100, debtDelta: 200000),
      ];

      final res = allocateDebts(rows);

      expect(res, {1: 0, 2: 250000, 3: 0});
      expect(signedSum(rows, res), 250000);
    });

    test('cùng thời điểm occurredAt thì phá hoà theo id tăng dần', () {
      final rows = [
        const DebtRow(id: 12, occurredAt: 100, debtDelta: 100000),
        const DebtRow(id: 10, occurredAt: 100, debtDelta: 100000),
        const DebtRow(id: 15, occurredAt: 200, debtDelta: -140000),
      ];

      final res = allocateDebts(rows);

      expect(res, {10: 0, 12: 60000, 15: 0});
      expect(signedSum(rows, res), 60000);
    });

    test('khoản ngược chiều (cho mượn sau người khác trả dùm) tự bù trừ', () {
      final rows = [
        // Người khác trả dùm -> debtDelta âm (mình nợ họ 120k).
        const DebtRow(id: 1, occurredAt: 100, debtDelta: -120000),
        // Mình cho họ mượn 200k -> bù hết 120k, còn mở +80k ở dòng 2.
        const DebtRow(id: 2, occurredAt: 200, debtDelta: 200000),
      ];

      final res = allocateDebts(rows);

      expect(res, {1: 0, 2: 80000});
      expect(signedSum(rows, res), 80000);
    });

    test('tất toán đích danh khoản mới hơn giữ nguyên khoản cũ đang mở', () {
      final rows = [
        const DebtRow(id: 1, occurredAt: 100, debtDelta: 200000),
        const DebtRow(id: 2, occurredAt: 200, debtDelta: 300000),
        const DebtRow(
          id: 3,
          occurredAt: 300,
          debtDelta: -300000,
          settlesTxId: 2,
        ),
      ];

      final res = allocateDebts(rows);

      expect(res[1], 200000);
      expect(res[2], 0);
      expect(res.containsKey(3), isFalse, reason: 'dòng tất toán là null');
      expect(signedSum(rows, res), 200000);
    });

    test('dòng tất toán vượt quá phần còn lại của đích thì phần dư tràn sang khoản khác', () {
      final rows = [
        const DebtRow(id: 1, occurredAt: 100, debtDelta: 200000),
        const DebtRow(id: 2, occurredAt: 200, debtDelta: 100000),
        const DebtRow(
          id: 3,
          occurredAt: 300,
          debtDelta: -180000,
          settlesTxId: 2,
        ),
      ];

      final res = allocateDebts(rows);

      // 100k đóng đích (2), 80k dư tràn sang khoản cũ nhất (1).
      expect(res[1], 120000);
      expect(res[2], 0);
      expect(res.containsKey(3), isFalse);
      expect(signedSum(rows, res), 120000);
    });

    test('dòng tất toán vượt hết mọi khoản đang mở vẫn giữ phần dư để bù cho khoản sau', () {
      final rows = [
        const DebtRow(id: 1, occurredAt: 100, debtDelta: 100000),
        const DebtRow(
          id: 2,
          occurredAt: 200,
          debtDelta: -150000,
          settlesTxId: 1,
        ),
        const DebtRow(id: 3, occurredAt: 300, debtDelta: 80000),
      ];

      final res = allocateDebts(rows);

      // Dòng 2 đóng dòng 1 (100k) và dư -50k; dòng 3 (+80k) ăn hết -50k đó, còn +30k.
      expect(res[1], 0);
      expect(res.containsKey(2), isFalse);
      expect(res[3], 30000);
      expect(signedSum(rows, res), 30000);
    });

    test('bỏ qua dòng đã xoá mềm và dòng debtDelta == 0', () {
      final rows = [
        const DebtRow(id: 1, occurredAt: 100, debtDelta: 200000),
        const DebtRow(
          id: 2,
          occurredAt: 150,
          debtDelta: -200000,
          deletedAt: 999,
        ),
        const DebtRow(id: 3, occurredAt: 160, debtDelta: 0),
        const DebtRow(
          id: 4,
          occurredAt: 200,
          debtDelta: -50000,
          settlesTxId: 1,
          deletedAt: 999,
        ),
      ];

      final res = allocateDebts(rows);

      expect(res, {1: 200000});
      expect(res.containsKey(2), isFalse);
      expect(res.containsKey(3), isFalse);
      expect(res.containsKey(4), isFalse);
    });

    test('bất biến: tổng phần còn mở có dấu == tổng debtDelta trên chuỗi hỗn hợp', () {
      final rows = [
        const DebtRow(id: 1, occurredAt: 10, debtDelta: 100000),
        const DebtRow(id: 2, occurredAt: 20, debtDelta: 250000),
        const DebtRow(
          id: 3,
          occurredAt: 30,
          debtDelta: -100000,
          settlesTxId: 2,
        ),
        const DebtRow(id: 4, occurredAt: 40, debtDelta: -300000),
        const DebtRow(id: 5, occurredAt: 50, debtDelta: -80000),
        const DebtRow(id: 6, occurredAt: 60, debtDelta: 50000),
        const DebtRow(id: 7, occurredAt: 70, debtDelta: 200000),
        const DebtRow(
          id: 8,
          occurredAt: 80,
          debtDelta: -40000,
          settlesTxId: 7,
        ),
        const DebtRow(
          id: 9,
          occurredAt: 90,
          debtDelta: 999999,
          deletedAt: 100,
        ),
      ];

      final res = allocateDebts(rows);
      final net = rows
          .where((r) => r.deletedAt == null)
          .fold<int>(0, (s, r) => s + r.debtDelta);

      expect(signedSum(rows, res), net);
      // Kiểm tra từng giá trị cụ thể:
      // 1: +100k; 2: +250k -> (3) -100k vào 2 => 2 còn +150k
      // (4) -300k: ăn 1 (+100k -> 0), ăn 2 (+150k -> 0), dư -50k mở ở 4
      // (5) -80k: cùng dấu âm -> mở -80k ở 5
      // (6) +50k: ăn hết 4 (-50k -> 0), 6 còn 0
      // (7) +200k: ăn hết 5 (-80k -> 0), dư +120k mở ở 7
      // (8) -40k vào 7 => 7 còn +80k
      expect(res, {
        1: 0,
        2: 0,
        4: 0,
        5: 0,
        6: 0,
        7: 80000,
      });
      expect(net, 80000);
    });
  });
}
