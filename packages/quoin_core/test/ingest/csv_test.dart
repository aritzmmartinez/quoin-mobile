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

  group('readCsv', () {
    Object? reasonOf(void Function() read) {
      try {
        read();
      } on CsvFileError catch (e) {
        return e.reason;
      }
      return null;
    }

    test('drops rows without a type, keeping each row its position', () {
      final read = readCsv('type,amount\nBUY,1\n,2\n  ,3\nSELL,4\n', [
        'type',
        'amount',
      ]);
      expect(read.missing, isEmpty);
      expect(read.records.map((r) => (r.raw['amount'], r.position)), [
        ('1', 1),
        ('4', 4),
      ]);
    });

    test('a row of the wrong length is kept, marked, with what it reached', () {
      final read = readCsv('type,a,b\nBUY,1\nBUY,1,2,3\n', ['type', 'a']);
      expect(read.records.map((r) => r.malformed), [true, true]);
      expect(read.records.map((r) => r.raw), [
        {'type': 'BUY', 'a': '1'},
        {'type': 'BUY', 'a': '1', 'b': '2'},
      ]);
    });

    test('names the missing columns; none of them is unparseable', () {
      expect(readCsv('type,a\n', ['type', 'b']).missing, ['b']);
      expect(
        reasonOf(() => requireColumns(readCsv('type,a\n', ['type', 'b']))),
        FileErrorReason.missingColumn,
      );
      expect(
        reasonOf(() => readCsv('x;y\n1;2\n', ['type'])),
        FileErrorReason.unparseable,
      );
    });

    test('a broken quote is unparseable', () {
      expect(
        reasonOf(() => readCsv('type,a\n"BUY,1\n', ['type'])),
        FileErrorReason.unparseable,
      );
    });
  });

  group('decodeCsv', () {
    test('drops a BOM and refuses bytes that are not UTF-8', () {
      expect(decodeCsv([0xEF, 0xBB, 0xBF, 0x61]), 'a');
      expect(
        () => decodeCsv([0x61, 0xF3, 0x6E]),
        throwsA(
          isA<CsvFileError>().having(
            (e) => e.reason,
            'reason',
            FileErrorReason.invalidEncoding,
          ),
        ),
      );
    });
  });
}
