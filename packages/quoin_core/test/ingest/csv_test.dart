import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseCsv', () {
    test('reads a header and its rows', () {
      final table = parseCsv('type,amount\nBUY,10\nSELL,5\n');
      expect(table.fields, ['type', 'amount']);
      expect(table.rows, [
        {'type': 'BUY', 'amount': '10'},
        {'type': 'SELL', 'amount': '5'},
      ]);
    });

    test('reads CRLF, CR and a last line without an end', () {
      expect(parseCsv('a,b\r\n1,2\r\n3,4').rows, [
        {'a': '1', 'b': '2'},
        {'a': '3', 'b': '4'},
      ]);
      expect(parseCsv('a,b\r1,2\r').rows, [
        {'a': '1', 'b': '2'},
      ]);
    });

    test('quotes keep commas, line ends and doubled quotes', () {
      final table = parseCsv(
        'name,note\n"Fondo, acc.","dice ""hola""\nen dos líneas"\n',
      );
      expect(table.rows.single, {
        'name': 'Fondo, acc.',
        'note': 'dice "hola"\nen dos líneas',
      });
    });

    test('an empty quoted field and an empty last field', () {
      expect(
        parseCsv('a,b,c\n"",x,\n').rows.single,
        {'a': '', 'b': 'x', 'c': ''},
      );
    });

    test('a quote inside an unquoted field is text, as in Papa', () {
      expect(parseCsv('a\n5"\n').rows.single, {'a': '5"'});
    });

    test('rows of blanks are skipped greedily, around the header too', () {
      final table = parseCsv('\n  \n,,\na,b\n\n1,2\n , \n3,4\n\n');
      expect(table.fields, ['a', 'b']);
      expect(table.rows, hasLength(2));
    });

    test('a row with another field count is an error with its line', () {
      expect(
        () => parseCsv('a,b\n1,2\n1,2,3\n'),
        throwsA(
          isA<CsvFormatException>().having((e) => e.line, 'line', 3),
        ),
      );
      expect(() => parseCsv('a,b\n1\n'), throwsA(isA<CsvFormatException>()));
    });

    test('the line counts the line ends inside quotes', () {
      expect(
        () => parseCsv('a,b\n"x\ny",1\nonly\n'),
        throwsA(
          isA<CsvFormatException>().having((e) => e.line, 'line', 4),
        ),
      );
    });

    test('an unclosed quote or text after a closing one is an error', () {
      expect(() => parseCsv('a\n"open\n'), throwsA(isA<CsvFormatException>()));
      expect(() => parseCsv('a\n"x"y\n'), throwsA(isA<CsvFormatException>()));
    });

    test('an empty text has no header and no rows', () {
      final table = parseCsv('');
      expect(table.fields, isEmpty);
      expect(table.rows, isEmpty);
    });
  });

  test('typedRows drops the rows without a type', () {
    final table = parseCsv('type,amount\nBUY,1\n,2\n  ,3\nSELL,4\n');
    expect(typedRows(table).map((r) => r['amount']), ['1', '4']);
    expect(typedRows(parseCsv('amount\n1\n')), isEmpty);
  });
}
