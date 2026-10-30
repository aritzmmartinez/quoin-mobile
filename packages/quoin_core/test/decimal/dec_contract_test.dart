import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  final file = File('test/contract/decimal.json');
  final contract = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final cases =
      (contract['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

  group('decimal contract', () {
    for (final c in cases) {
      test(c['name'] as String, () {
        final op = c['op'] as String;
        final expectedError = c['error'] as String?;

        String run() {
          final a = Dec.parse(c['a'] as String);
          final bText = c['b'] as String?;
          final b = bText == null ? null : Dec.parse(bText);
          return switch (op) {
            'parse' => a.toString(),
            'add' => (a + b!).toString(),
            'sub' => (a - b!).toString(),
            'mul' => (a * b!).toString(),
            'div' => a.dividedBy(b!).toString(),
            'round' => a.roundTo(c['places'] as int).toString(),
            'compare' => a.compareTo(b!).toString(),
            'sign' => a.sign.toString(),
            _ => throw StateError('Unknown op "$op" in decimal.json'),
          };
        }

        switch (expectedError) {
          case null:
            expect(run(), c['result']);
          case 'invalid':
            expect(run, throwsA(isA<InvalidDecimal>()));
          case 'division-by-zero':
            expect(run, throwsA(isA<DivisionByZero>()));
          default:
            fail('Unknown error "$expectedError" in decimal.json');
        }
      });
    }
  });
}
