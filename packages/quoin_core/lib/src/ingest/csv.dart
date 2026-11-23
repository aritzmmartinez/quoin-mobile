import 'reasons.dart';

final class CsvFormatException implements Exception {
  const CsvFormatException(this.message, this.line);

  final String message;
  final int line;

  @override
  String toString() => 'CsvFormatException (line $line): $message';
}

final class CsvTable {
  const CsvTable(this.fields, this.rows);

  final List<String> fields;
  final List<Map<String, String>> rows;
}

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

final class CsvRecord {
  const CsvRecord(this.raw, this.position, {required this.malformed});

  final Map<String, String> raw;
  final int position;
  final bool malformed;
}

final class CsvRecords {
  const CsvRecords(this.missing, this.records);
  final List<String> missing;
  final List<CsvRecord> records;
}

CsvRecords readCsv(String csv, List<String> columns) {
  List<String>? fields;
  final records = <CsvRecord>[];
  var position = 0;
  try {
    for (final (_, record) in csvRecords(csv)) {
      final header = fields;
      if (header == null) {
        fields = record;
        continue;
      }
      position += 1;
      final malformed = record.length != header.length;
      final raw = {
        for (var i = 0; i < header.length && i < record.length; i += 1)
          header[i]: record[i],
      };
      if (malformed || (raw['type'] ?? '').trim().isNotEmpty) {
        records.add(CsvRecord(raw, position, malformed: malformed));
      }
    }
  } on CsvFormatException {
    throw const CsvFileError(FileErrorReason.unparseable);
  }
  final header = fields ?? const <String>[];
  final missing = [
    for (final column in columns)
      if (!header.contains(column)) column,
  ];
  if (missing.length == columns.length) {
    throw const CsvFileError(FileErrorReason.unparseable);
  }
  return CsvRecords(missing, records);
}

void requireColumns(CsvRecords csv) {
  if (csv.missing.isNotEmpty) {
    throw CsvFileError(
      FileErrorReason.missingColumn,
      column: csv.missing.first,
    );
  }
}

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
