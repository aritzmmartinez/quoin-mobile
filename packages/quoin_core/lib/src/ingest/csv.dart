/// A CSV the importer cannot read: an unclosed quote, text after a closing
/// quote, or a row whose field count differs from the header's.
final class CsvFormatException implements Exception {
  const CsvFormatException(this.message, this.line);

  final String message;

  /// 1-based line where the faulty record starts.
  final int line;

  @override
  String toString() => 'CsvFormatException (line $line): $message';
}

/// A parsed CSV: the header as written and one map per data row.
final class CsvTable {
  const CsvTable(this.fields, this.rows);

  final List<String> fields;
  final List<Map<String, String>> rows;
}

/// Reads [text] as the web reads an export with Papa Parse (`header: true`,
/// `skipEmptyLines: "greedy"`): comma separated, RFC 4180 quoting, CRLF, LF or
/// CR line ends. Rows of blanks are skipped, before and after the header, and
/// a row with more or fewer fields than the header is an error, as Papa's
/// field-mismatch error makes the web reject the file.
///
/// The text arrives decoded and without a byte order mark.
CsvTable parseCsv(String text) {
  List<String>? fields;
  final rows = <Map<String, String>>[];
  for (final (line, record) in csvRecords(text)) {
    if (fields == null) {
      fields = record;
      continue;
    }
    if (record.length != fields.length) {
      throw CsvFormatException(
        'Expected ${fields.length} fields, found ${record.length}',
        line,
      );
    }
    rows.add({for (var i = 0; i < fields.length; i += 1) fields[i]: record[i]});
  }
  return CsvTable(fields ?? const [], rows);
}

/// Drops the rows without a `type`, as both brokers' adapters do in Quoin:
/// exports end in summary lines that carry none.
List<Map<String, String>> typedRows(CsvTable table) => [
      for (final row in table.rows)
        if ((row['type'] ?? '').trim().isNotEmpty) row,
    ];

/// The records of [text] with the line each starts on, rows of blanks left
/// out. Lazy, so the header can be read without parsing the rest.
Iterable<(int, List<String>)> csvRecords(String text) sync* {
  var i = 0;
  var line = 1;
  final n = text.length;
  while (i < n) {
    final start = line;
    final record = <String>[];
    final field = StringBuffer();
    var ended = false;
    while (!ended) {
      if (i >= n) {
        record.add(field.toString());
        break;
      }
      final c = text[i];
      if (c == '"' && field.isEmpty) {
        i += 1;
        while (true) {
          if (i >= n) throw CsvFormatException('Unclosed quote', start);
          final q = text[i];
          if (q == '"') {
            if (i + 1 < n && text[i + 1] == '"') {
              field.write('"');
              i += 2;
              continue;
            }
            i += 1;
            break;
          }
          if (q == '\n' || (q == '\r' && (i + 1 >= n || text[i + 1] != '\n'))) {
            line += 1;
          }
          field.write(q);
          i += 1;
        }
        if (i < n && !_isEnd(text, i)) {
          throw CsvFormatException('Text after a closing quote', start);
        }
        continue;
      }
      if (c == ',') {
        record.add(field.toString());
        field.clear();
        i += 1;
        continue;
      }
      if (c == '\r' || c == '\n') {
        record.add(field.toString());
        i += (c == '\r' && i + 1 < n && text[i + 1] == '\n') ? 2 : 1;
        line += 1;
        ended = true;
        continue;
      }
      field.write(c);
      i += 1;
    }
    if (record.any((cell) => cell.trim().isNotEmpty)) yield (start, record);
  }
}

bool _isEnd(String text, int i) =>
    text[i] == ',' || text[i] == '\r' || text[i] == '\n';
