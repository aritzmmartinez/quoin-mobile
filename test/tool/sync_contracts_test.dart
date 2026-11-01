import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/sync_contracts.dart';

void main() {
  late Directory quoin;
  late Directory mobile;

  setUp(() {
    quoin = Directory.systemTemp.createTempSync('quoin');
    mobile = Directory.systemTemp.createTempSync('mobile');
  });
  tearDown(() {
    quoin.deleteSync(recursive: true);
    mobile.deleteSync(recursive: true);
  });

  List<String> problems() =>
      contractProblems(contracts(quoin), contracts(mobile));

  void write(Directory dir, String name, String text) =>
      File('${dir.path}/$name').writeAsStringSync(text);

  const lf = '{\n  "cases": [\n    0\n  ]\n}\n';
  final crlf = lf.replaceAll('\n', '\r\n');
  final bom = String.fromCharCode(0xFEFF);

  test('CRLF or a BOM on either side is the same contract', () {
    for (final (left, right) in [
      (lf, lf),
      (crlf, lf),
      (lf, crlf),
      (crlf, crlf),
      ('$bom$lf', lf),
      (lf, '$bom$crlf'),
    ]) {
      write(quoin, 'ingest.json', left);
      write(mobile, 'ingest.json', right);
      expect(problems(), isEmpty);
    }
  });

  test('a reformatted file differs, whatever its line ends', () {
    write(quoin, 'ingest.json', crlf);
    write(mobile, 'ingest.json', '{\n  "cases": [0]\n}\n');
    expect(problems(), ['differs: ingest.json']);
  });

  test('a missing final newline differs', () {
    write(quoin, 'ingest.json', lf);
    write(mobile, 'ingest.json', lf.trimRight());
    expect(problems(), ['differs: ingest.json']);
  });

  test('missing and extra files are named; other files are ignored', () {
    write(quoin, 'ingest.json', lf);
    write(quoin, 'sync.json', lf);
    write(mobile, 'ingest.json', lf);
    write(mobile, 'extra.json', lf);
    write(mobile, 'SOURCE', 'abc\n');
    expect(problems(), ['missing: sync.json', 'not in Quoin: extra.json']);
  });
}
