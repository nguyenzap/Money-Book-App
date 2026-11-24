import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneybook/core/domain/autotrack/mask.dart';
import 'package:moneybook/core/domain/autotrack/parsed_txn.dart';
import 'package:moneybook/core/domain/autotrack/parsers/bidv_parser.dart';
import 'package:moneybook/core/domain/autotrack/parsers/eximbank_parser.dart';
import 'package:moneybook/core/domain/autotrack/parsers/registry.dart';
import 'package:moneybook/core/domain/autotrack/text_fold.dart';
import 'package:moneybook/core/domain/autotrack/vnd_amount.dart';

/// Đọc thông báo ngân hàng. Các mẫu thật nằm trong
/// `test/fixtures/autotrack/<parser id>/*.txt`: dòng `# expect:` là kết quả
/// mong đợi, `# title:` là tiêu đề thông báo (nếu có), các dòng `#` khác là
/// ghi chú, phần còn lại là nguyên văn thân thông báo. Thêm mẫu mới không cần
/// viết thêm test.
void main() {
  group('mẫu thật', () {
    final root = Directory('test/fixtures/autotrack');
    for (final parser in kParsers) {
      final dir = Directory('${root.path}/${parser.id}');
      test('${parser.id} có thư mục mẫu', () {
        expect(dir.existsSync(), isTrue);
      });
      if (!dir.existsSync()) continue;
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.txt'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        test('${parser.id}/${file.uri.pathSegments.last}', () {
          final fixture = _Fixture.read(file);
          final result = parser.parse(fixture.title, fixture.body);
          fixture.check(result);
        });
      }
    }
  });

  group('parseVnd', () {
    test('dấu phẩy hoặc dấu chấm phân cách nghìn', () {
      expect(parseVnd('-80,000 VND', requireSign: true), -80000);
      expect(parseVnd('+5.000.000đ', requireSign: true), 5000000);
      expect(parseVnd('2,702,202 VND'), 2702202);
      expect(parseVnd('150000'), 150000);
      expect(parseVnd('1.000 ₫'), 1000);
      expect(parseVnd('- 80,000 vnd', requireSign: true), -80000);
    });

    test('thiếu dấu thì không đoán chiều', () {
      expect(parseVnd('80,000 VND', requireSign: true), isNull);
    });

    test('từ chối số không chắc đọc đúng', () {
      expect(parseVnd('80,00'), isNull, reason: 'không phải 8000');
      expect(parseVnd('1,234.567'), isNull, reason: 'trộn hai loại dấu');
      expect(parseVnd('1234,567'), isNull, reason: 'nhóm đầu quá 3 số');
      expect(parseVnd('80,000.50'), isNull, reason: 'VND không có lẻ');
      expect(parseVnd('abc'), isNull);
      expect(parseVnd(''), isNull);
      expect(parseVnd('1234567890123456'), isNull, reason: 'quá dài');
    });
  });

  group('foldVi', () {
    test('bỏ dấu, đ thành d, chữ thường, gộp khoảng trắng', () {
      expect(foldVi('  Số tiền   GD '), 'so tien gd');
      expect(foldVi('ĐÃ THANH TOÁN'), 'da thanh toan');
      expect(foldVi('Eximbank Mỹ Tho'), 'eximbank my tho');
    });

    test('chữ có dấu dạng tổ hợp cũng gấp như dạng dựng sẵn', () {
      // "Số" viết bằng "o" + dấu mũ U+0302 + dấu sắc U+0301.
      const decomposed = 'Số tiền GD';
      expect(foldVi(decomposed), foldVi('Số tiền GD'));
    });
  });

  group('BIDV', () {
    const p = BidvParser();
    String bidv({
      String amount = '-80,000 VND',
      String content = 'NGUYEN VAN A chuyen tien',
      String account = '1234567890',
    }) =>
        'BIDV xin thông báo tới Quý khách\n'
        'Thời gian giao dịch: 18:57 21/11/2026\n'
        'Tài khoản thanh toán: $account\n'
        'Số tiền GD: $amount\n'
        'Số dư cuối: 2,702,202 VND\n'
        'Nội dung giao dịch: $content\n'
        'Mã giao dịch: FT26325ABC123';

    test('đọc đủ các trường', () {
      final txn = _matched(p.parse('', bidv()));
      expect(txn.direction, TxDirection.expense);
      expect(txn.amount, 80000);
      expect(txn.occurredAt, DateTime(2026, 11, 21, 18, 57));
      expect(txn.accountSuffix, '7890', reason: 'chỉ giữ 4 số cuối');
      expect(txn.balanceAfter, 2702202);
      expect(txn.receiver, 'NGUYEN VAN A chuyen tien');
      expect(txn.reference, 'FT26325ABC123');
    });

    test('dòng đầu nằm ở tiêu đề, phần còn lại ở thân', () {
      final lines = bidv().split('\n');
      final txn = _matched(p.parse(lines.first, lines.skip(1).join('\n')));
      expect(txn.amount, 80000);
    });

    test('tiêu đề trùng dòng đầu của thân vẫn đọc được', () {
      final txn = _matched(
        p.parse('BIDV xin thông báo tới Quý khách', bidv()),
      );
      expect(txn.amount, 80000);
    });

    test('dòng lạ ngân hàng mới thêm vào không làm hỏng tin', () {
      final text = bidv().replaceFirst(
        'Số dư cuối',
        'Kênh giao dịch: Mobile\nSố dư cuối',
      );
      expect(_matched(p.parse('', text)).balanceAfter, 2702202);
    });

    test('xuống dòng kiểu Windows', () {
      final txn = _matched(p.parse('', bidv().replaceAll('\n', '\r\n')));
      expect(txn.amount, 80000);
    });

    test('nội dung có dấu hai chấm vẫn giữ nguyên', () {
      final txn = _matched(p.parse('', bidv(content: 'Thanh toan: hoa don 01')));
      expect(txn.receiver, 'Thanh toan: hoa don 01');
    });

    test('số tiền hỏng thì là failed, không lặng lẽ bỏ', () {
      expect(p.parse('', bidv(amount: '-80,00 VND')), isA<ParseFailed>());
      expect(p.parse('', bidv(amount: '80,000 VND')), isA<ParseFailed>(),
          reason: 'thiếu dấu thì không biết chiều');
      expect(p.parse('', bidv(amount: '+0 VND')), isA<ParseFailed>());
    });

    test('OTP, khuyến mãi, tin của ngân hàng khác đều bị bỏ qua', () {
      expect(
        p.parse('BIDV', 'Ma OTP cua Quy khach la 123456. Khong cung cap '
            'ma nay cho bat ky ai.'),
        isA<ParseIgnored>(),
      );
      expect(
        p.parse('BIDV', 'Uu dai hoan tien 50,000 VND khi thanh toan QR!'),
        isA<ParseIgnored>(),
      );
      expect(
        p.parse('', 'BIDV xin thông báo tới Quý khách\n'
            'Quý khách vừa đăng nhập trên thiết bị mới.'),
        isA<ParseIgnored>(),
        reason: 'có dòng đầu nhưng không có dòng số tiền',
      );
      expect(p.parse('', 'Eximbank Mỹ Tho: 17/11/2026 20:25\n'
          'Giao dịch: -328,000 VND'), isA<ParseIgnored>());
    });

    test('thông báo đẩy: tiêu đề "Thông báo BIDV" là dòng đầu', () {
      final body = bidv().split('\n').skip(1).join('\n');
      expect(_matched(p.parse('Thông báo BIDV', body)).amount, 80000);
      expect(p.parse('', body), isA<ParseIgnored>(),
          reason: 'không tiêu đề, không dòng đầu thì không nhận');
    });

    test('nội dung dài xuống dòng vẫn ghép đủ', () {
      final txn = _matched(
        p.parse(
          '',
          bidv(content: 'TKThe :123, tai Eximbank.\nNGUYEN VAN A chuyen tien'),
        ),
      );
      expect(txn.receiver, 'TKThe :123, tai Eximbank. NGUYEN VAN A chuyen tien');
      expect(txn.reference, 'FT26325ABC123',
          reason: 'dòng có nhãn sau đó vẫn đọc bình thường');
    });

    test('ngày giờ vô lý thì bỏ thời gian, vẫn ghi giao dịch', () {
      final text = bidv().replaceFirst('21/11/2026', '31/02/2026');
      final txn = _matched(p.parse('', text));
      expect(txn.occurredAt, isNull);
      expect(txn.amount, 80000);
    });
  });

  group('Eximbank', () {
    const p = EximbankParser();

    test('tên chi nhánh nào cũng được', () {
      final txn = _matched(p.parse(
        '',
        'Eximbank Sài Gòn: 01/12/2026 07:05\n'
            'Tài khoản: 200014851234567\n'
            'Giao dịch: -45,000 VND\n'
            'Số dư: 1,000,000 VND\n'
            'Nội dung: HIGHLANDS COFFEE Q1\n'
            'Số tham chiếu: 123456',
      ));
      expect(txn.occurredAt, DateTime(2026, 12, 1, 7, 5));
      expect(txn.accountSuffix, '4567');
      expect(txn.receiver, 'HIGHLANDS COFFEE Q1');
    });

    test('"Giao dịch" không bị nhầm với nhãn của BIDV', () {
      expect(
        p.parse('', 'BIDV xin thông báo tới Quý khách\n'
            'Số tiền GD: -80,000 VND'),
        isA<ParseIgnored>(),
      );
    });
  });

  test('che số tài khoản, giữ số tiền và ngày giờ', () {
    expect(
      maskDigits('Tài khoản thanh toán: 1234567890\n'
          'Thời gian giao dịch: 18:57 21/11/2026\n'
          'Số tiền GD: -80,000 VND\nMã giao dịch: FT26325123456'),
      'Tài khoản thanh toán: xxxxxxx890\n'
      'Thời gian giao dịch: 18:57 21/11/2026\n'
      'Số tiền GD: -80,000 VND\nMã giao dịch: FTxxxxxxxx456',
    );
  });

  test('id các parser không trùng nhau', () {
    final ids = kParsers.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('một gói Android không thuộc về hai ngân hàng', () {
    final all = kParsers.expand((p) => p.knownPackages).toList();
    expect(all.toSet(), hasLength(all.length));
  });
}

ParsedTxn _matched(ParseResult r) {
  if (r is ParseMatched) return r.txn;
  fail('mong đọc được, nhưng ra $r '
      '(${r is ParseIgnored ? r.reason : (r as ParseFailed).reason})');
}

/// Một file mẫu: `# expect: <ignored|failed|expense N|income N> [k=v ...]`.
class _Fixture {
  _Fixture(this.expect, this.title, this.body);

  factory _Fixture.read(File file) {
    final lines = file.readAsLinesSync();
    String? expect;
    var title = '';
    final body = <String>[];
    for (final l in lines) {
      if (l.startsWith('# expect:')) {
        expect = l.substring('# expect:'.length).trim();
      } else if (l.startsWith('# title:')) {
        title = l.substring('# title:'.length).trim();
      } else if (!l.startsWith('#')) {
        body.add(l);
      }
    }
    if (expect == null) fail('${file.path}: thiếu dòng "# expect:"');
    return _Fixture(expect, title, body.join('\n'));
  }

  final String expect;
  final String title;
  final String body;

  void check(ParseResult result) {
    final tokens = RegExp(r'(\w+)="([^"]*)"|(\S+)')
        .allMatches(expect)
        .map((m) => m[1] != null ? '${m[1]}=${m[2]}' : m[3]!)
        .toList();
    switch (tokens.first) {
      case 'ignored':
        expect_(result, isA<ParseIgnored>());
        return;
      case 'failed':
        expect_(result, isA<ParseFailed>());
        return;
    }
    final txn = _matched(result);
    expect_(txn.direction.name, tokens[0]);
    expect_(txn.amount, int.parse(tokens[1]));

    final kv = {
      for (final t in tokens.skip(2))
        t.substring(0, t.indexOf('=')): t.substring(t.indexOf('=') + 1),
    };
    // Trường không ghi trong `expect` thì phải trống, để mẫu nói đủ ý.
    expect_(
      txn.occurredAt?.toIso8601String().substring(0, 16),
      kv['at'],
      reason: 'at',
    );
    expect_(txn.balanceAfter?.toString(), kv['balance'], reason: 'balance');
    expect_(txn.receiver, kv['receiver'], reason: 'receiver');
    expect_(txn.accountSuffix, kv['account'], reason: 'account');
    expect_(txn.reference, kv['ref'], reason: 'ref');
  }
}

// `expect` là tên trường của _Fixture nên gọi hàm của flutter_test qua tên
// khác.
void expect_(dynamic actual, dynamic matcher, {String? reason}) =>
    expect(actual, matcher, reason: reason);
