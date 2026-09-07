import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/db/repository.dart';
import 'package:moneybook/core/format/dates.dart';

/// Dựng một tiến độ ngân sách giả lập để kiểm tra riêng phần tính nhịp độ,
/// không cần đụng tới cơ sở dữ liệu.
BudgetProgress makeProgress({
  required int limit,
  required int spent,
  required int daysElapsed,
  int daysInMonth = 30,
}) {
  return BudgetProgress(
    budgetId: 1,
    categoryId: 1,
    categoryName: 'Ăn uống',
    limitAmount: limit,
    spent: spent,
    isRecurring: true,
    monthKey: 202609,
    daysInMonth: daysInMonth,
    daysElapsed: daysElapsed,
  );
}

void main() {
  group('mức tiêu mỗi ngày', () {
    test('ngân sách 3 triệu tháng 30 ngày là 100k mỗi ngày', () {
      final b = makeProgress(limit: 3000000, spent: 0, daysElapsed: 1);
      expect(b.dailyAllowance, 100000);
    });

    test('tháng 31 ngày thì mức mỗi ngày thấp hơn', () {
      final b = makeProgress(
        limit: 3000000,
        spent: 0,
        daysElapsed: 1,
        daysInMonth: 31,
      );
      expect(b.dailyAllowance, 96774);
    });

    test('trung bình thực tế tính trên số ngày đã qua', () {
      // Qua 3 ngày tiêu 450k tức là 150k mỗi ngày.
      final b = makeProgress(limit: 3000000, spent: 450000, daysElapsed: 3);
      expect(b.dailyAverage, 150000);
    });
  });

  group('phát hiện tiêu nhanh - đúng ví dụ người dùng nêu', () {
    test('ngày nào cũng 150k trong khi mức là 100k thì bị cảnh báo', () {
      // Ngân sách 3tr. Qua 4 ngày, mỗi ngày 150k -> đã tiêu 600k.
      final b = makeProgress(limit: 3000000, spent: 600000, daysElapsed: 4);

      expect(b.dailyAverage, 150000);
      expect(b.expectedByNow, 400000, reason: '4 ngày x 100k');
      expect(b.paceDelta, 200000, reason: 'vượt nhịp 200k');
      expect(b.pace, BudgetPace.fast);
      expect(b.needsAttention, isTrue);
    });

    test('app chỉ ra ngày mai được tiêu bao nhiêu để bù lại', () {
      // Đúng tình huống người dùng mô tả: hôm nay lỡ ăn 150k, ngày mai nên
      // rút xuống bao nhiêu.
      final b = makeProgress(limit: 3000000, spent: 150000, daysElapsed: 1);

      expect(b.daysRemaining, 29);
      expect(b.remaining, 2850000);
      // 2.850.000 chia 29 ngày còn lại.
      expect(b.remainingDailyAllowance, 98275);
      expect(
        b.remainingDailyAllowance < b.dailyAllowance,
        isTrue,
        reason: 'tiêu quá hôm nay thì mức những ngày sau phải giảm',
      );
    });

    test('lỡ tay nhiều thì mức còn lại giảm rõ rệt', () {
      // Nửa tháng đã tiêu hết 2/3 ngân sách.
      final b = makeProgress(limit: 3000000, spent: 2000000, daysElapsed: 15);

      expect(b.pace, BudgetPace.fast);
      expect(b.daysRemaining, 15);
      expect(b.remainingDailyAllowance, 66666,
          reason: 'phải hạ từ 100k xuống còn khoảng 67k mỗi ngày');
    });

    test('một bữa đắt lẻ tẻ KHÔNG làm nổ cảnh báo', () {
      // Đây là điểm mấu chốt: nếu ngày nào ăn hơn 100k cũng cảnh báo thì
      // người dùng sẽ bỏ qua nó. Qua 10 ngày tiêu 1.05tr, tức là chỉ nhỉnh
      // hơn nhịp đều 5%.
      final b = makeProgress(limit: 3000000, spent: 1050000, daysElapsed: 10);

      expect(b.expectedByNow, 1000000);
      expect(b.pace, BudgetPace.onTrack);
      expect(b.needsAttention, isFalse);
    });

    test('bám sát nhịp thì không nhắc gì', () {
      final b = makeProgress(limit: 3000000, spent: 1000000, daysElapsed: 10);
      expect(b.pace, BudgetPace.onTrack);
      expect(b.paceDelta, 0);
      expect(b.needsAttention, isFalse);
    });

    test('tiêu tiết kiệm thì được ghi nhận là đang dư dả', () {
      final b = makeProgress(limit: 3000000, spent: 500000, daysElapsed: 10);
      expect(b.pace, BudgetPace.slow);
      expect(b.paceDelta, -500000);
      expect(b.needsAttention, isFalse);
      expect(b.remainingDailyAllowance, 125000,
          reason: 'tiết kiệm được thì những ngày sau rộng tay hơn');
    });
  });

  group('mức nên tiêu hôm nay', () {
    test('ngân sách 2tr, đã tiêu 155k, hôm nay tiêu 108k', () {
      // Số liệu thật người dùng gặp: app từng hiện mốc 188.22k, cao hơn cả
      // số vừa tiêu, nên không bao giờ báo vượt.
      final b = makeProgress(
        limit: 2000000,
        spent: 155000,
        daysElapsed: 7,
      );

      expect(b.remaining, 1845000);
      expect(b.daysRemaining, 23);

      // Tiền còn lại đã trừ 108k của hôm nay, nên phải cộng lại rồi chia cho
      // 24 ngày (23 ngày còn lại cộng hôm nay).
      expect(b.budgetForToday(108000), 81375);
      expect(b.budgetForToday(108000) < 108000, isTrue,
          reason: 'tiêu 108k mà mốc chỉ 81k thì phải bị coi là vượt');
    });

    test('mốc hôm nay KHÔNG tăng theo số đã tiêu', () {
      // Đây là lỗi cũ: mốc = mức còn lại + đã tiêu hôm nay, nên càng tiêu
      // nhiều mốc càng cao và không bao giờ báo vượt được.
      //
      // Tiêu hôm nay làm `spent` tăng và `remaining` giảm đúng bằng đó, nên
      // khi cộng lại `spentToday` thì hai vế triệt tiêu — mốc giữ nguyên.
      final quiet = makeProgress(limit: 3000000, spent: 0, daysElapsed: 1)
          .budgetForToday(0);
      final splurged =
          makeProgress(limit: 3000000, spent: 500000, daysElapsed: 1)
              .budgetForToday(500000);

      expect(quiet, 100000);
      expect(splurged, quiet,
          reason: 'tiêu bao nhiêu thì mốc của hôm nay vẫn thế');
    });

    test('chưa tiêu gì hôm nay thì mốc là phần chia đều còn lại', () {
      // Ngân sách 3tr, tháng 30 ngày, ngày mùng 1, chưa tiêu gì.
      final b = makeProgress(limit: 3000000, spent: 0, daysElapsed: 1);
      expect(b.daysRemaining, 29);
      expect(b.budgetForToday(0), 100000, reason: '3tr chia đều 30 ngày');
    });

    test('tiêu lố hôm qua thì mốc hôm nay thấp xuống', () {
      // Ngân sách 3tr, qua 10 ngày đã tiêu 1.5tr (đáng lẽ chỉ 1tr).
      final b = makeProgress(limit: 3000000, spent: 1500000, daysElapsed: 10);
      expect(b.budgetForToday(0), 71428,
          reason: '1.5tr còn lại chia 21 ngày, thấp hơn mức 100k ban đầu');
    });

    test('tiết kiệm được thì mốc hôm nay rộng hơn', () {
      final b = makeProgress(limit: 3000000, spent: 500000, daysElapsed: 10);
      expect(b.budgetForToday(0), 119047,
          reason: '2.5tr còn lại chia 21 ngày, cao hơn mức 100k ban đầu');
    });

    test('hết sạch hạn mức thì mốc bằng 0', () {
      final b = makeProgress(limit: 3000000, spent: 3200000, daysElapsed: 20);
      expect(b.budgetForToday(0), 0);
    });

    test('ngày cuối tháng vẫn chia được cho chính hôm đó', () {
      final b = makeProgress(limit: 3000000, spent: 2900000, daysElapsed: 30);
      expect(b.daysRemaining, 0);
      expect(b.budgetForToday(0), 100000,
          reason: 'toàn bộ phần còn lại dồn cho ngày cuối');
    });

    test('mốc hôm nay và mức những ngày sau là hai con số khác nhau', () {
      // Sau khi đã tiêu hôm nay, mức cho các ngày sau phải thấp hơn mốc hôm
      // nay nếu hôm nay tiêu lố.
      final b = makeProgress(limit: 2000000, spent: 155000, daysElapsed: 7);
      expect(b.budgetForToday(108000), 81375);
      expect(b.remainingDailyAllowance, 80217);
    });
  });

  group('dự báo', () {
    test('giữ nhịp này thì cuối tháng tiêu hết bao nhiêu', () {
      // 150k mỗi ngày qua 4 ngày, cả tháng 30 ngày sẽ là 4.5tr.
      final b = makeProgress(limit: 3000000, spent: 600000, daysElapsed: 4);
      expect(b.projectedTotal, 4500000);
      expect(b.projectedTotal > b.limitAmount, isTrue);
    });

    test('báo còn cầm cự được mấy ngày và cạn vào ngày nào', () {
      // 150k mỗi ngày, đã tiêu 600k, còn 2.4tr -> thêm 16 ngày nữa.
      final b = makeProgress(limit: 3000000, spent: 600000, daysElapsed: 4);
      expect(b.daysUntilRunOut, 16);
      expect(b.projectedRunOutDay, 20, reason: 'ngày 4 + 16 ngày nữa');
    });

    test('số ngày cầm cự được đếm từ hôm nay, không từ đầu tháng', () {
      // Điểm dễ nhầm: "cạn vào ngày 10" nghe như còn xa, nhưng nếu hôm nay là
      // ngày 6 thì chỉ còn 4 hôm.
      final b = makeProgress(limit: 200000, spent: 116668, daysElapsed: 6);
      expect(b.dailyAverage, 19444);
      expect(b.daysUntilRunOut, 4);
      expect(b.projectedRunOutDay, 10);
    });

    test('tiêu đúng nhịp thì không cạn giữa chừng', () {
      final b = makeProgress(limit: 3000000, spent: 1000000, daysElapsed: 10);
      expect(b.daysUntilRunOut, isNull);
      expect(b.projectedRunOutDay, isNull);
    });

    test('chưa tiêu gì thì không dự báo bừa', () {
      final b = makeProgress(limit: 3000000, spent: 0, daysElapsed: 5);
      expect(b.daysUntilRunOut, isNull);
      expect(b.projectedRunOutDay, isNull);
      expect(b.projectedTotal, 0);
      expect(b.pace, BudgetPace.slow);
    });

    test('đã hết tiền thì không còn gì để dự báo', () {
      final b = makeProgress(limit: 3000000, spent: 3200000, daysElapsed: 20);
      expect(b.daysUntilRunOut, isNull);
      expect(b.projectedRunOutDay, isNull);
    });
  });

  group('các trường hợp biên', () {
    test('đã vượt hạn mức thì nhịp độ là đã vượt', () {
      final b = makeProgress(limit: 3000000, spent: 3500000, daysElapsed: 20);
      expect(b.pace, BudgetPace.over);
      expect(b.isOver, isTrue);
      expect(b.needsAttention, isTrue);
    });

    test('vượt rồi thì không còn tiền mỗi ngày để mà chia', () {
      final b = makeProgress(limit: 3000000, spent: 3500000, daysElapsed: 20);
      expect(b.remainingDailyAllowance, 0);
    });

    test('ngày cuối tháng thì không còn ngày nào để chia', () {
      final b = makeProgress(limit: 3000000, spent: 2000000, daysElapsed: 30);
      expect(b.daysRemaining, 0);
      expect(b.remainingDailyAllowance, 0);
    });

    test('tháng đã qua thì thôi không nhắc nữa', () {
      // Vượt hạn mức của một tháng đã kết thúc thì có nhắc cũng không sửa
      // được gì.
      final b = makeProgress(limit: 3000000, spent: 3500000, daysElapsed: 30);
      expect(b.isPastMonth, isTrue);
      expect(b.needsAttention, isFalse);
    });

    test('ngày đầu tháng chưa tiêu gì thì chưa kết luận', () {
      final b = makeProgress(limit: 3000000, spent: 0, daysElapsed: 1);
      expect(b.pace, BudgetPace.slow);
      expect(b.needsAttention, isFalse);
      expect(b.remainingDailyAllowance, 103448,
          reason: '3tr chia 29 ngày còn lại');
    });

    test('hạn mức bằng 0 không làm chia cho 0', () {
      final b = makeProgress(limit: 0, spent: 0, daysElapsed: 5);
      expect(b.dailyAllowance, 0);
      expect(b.expectedByNow, 0);
      expect(b.pace, BudgetPace.onTrack);
      expect(b.ratio, 0);
    });

    test('sắp chạm hạn mức vẫn được nhắc dù nhịp bình thường', () {
      // Cuối tháng, tiêu 85% nhưng đúng nhịp — vẫn nên nhắc vì sắp hết.
      final b = makeProgress(limit: 3000000, spent: 2550000, daysElapsed: 26);
      expect(b.pace, BudgetPace.onTrack);
      expect(b.isNearLimit, isTrue);
      expect(b.needsAttention, isTrue);
    });
  });

  group('helper ngày tháng', () {
    test('số ngày của tháng', () {
      expect(daysInMonth(202609), 30);
      expect(daysInMonth(202610), 31);
      expect(daysInMonth(202602), 28);
      expect(daysInMonth(202402), 29, reason: 'năm nhuận');
    });

    test('tháng đã qua thì coi như trôi hết ngày', () {
      final now = DateTime(2026, 9, 15);
      expect(daysElapsedIn(202608, now: now), 31);
      expect(daysRemainingIn(202608, now: now), 0);
    });

    test('tháng chưa tới thì chưa trôi ngày nào', () {
      final now = DateTime(2026, 9, 15);
      expect(daysElapsedIn(202610, now: now), 0);
      expect(daysRemainingIn(202610, now: now), 31);
    });

    test('tháng hiện tại tính theo ngày hôm nay', () {
      final now = DateTime(2026, 9, 15);
      expect(daysElapsedIn(202609, now: now), 15);
      expect(daysRemainingIn(202609, now: now), 15);
    });
  });
}
