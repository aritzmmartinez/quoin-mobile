import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(r"^(?:import|export) '([^']+)'", multiLine: true);

List<String> _offenders(String dir, bool Function(String uri) isBad) => [
  for (final file
      in Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')))
    for (final m in _directive.allMatches(file.readAsStringSync()))
      if (isBad(m[1]!)) '${file.path}: ${m[1]}',
];

Iterable<String> _layers(String layer) =>
    Directory('lib/src/features')
        .listSync()
        .whereType<Directory>()
        .map((d) => '${d.path}/$layer')
        .where((p) => Directory(p).existsSync());

void main() {
  test('domain imports only Dart, quoin_core, core/error and domain', () {
    final allowed = RegExp(
      r'^(dart:(?!ui)|package:quoin_core/|package:quoin/src/core/error/'
      r'|package:quoin/src/features/\w+/domain/)',
    );
    for (final dir in _layers('domain')) {
      expect(_offenders(dir, (uri) => !allowed.hasMatch(uri)), isEmpty);
    }
  });

  test('core/error is plain Dart', () {
    expect(
      _offenders(
        'lib/src/core/error',
        (uri) => !uri.startsWith('dart:') && !uri.contains('/core/error/'),
      ),
      isEmpty,
    );
  });

  test('presentation does not import data', () {
    for (final dir in _layers('presentation')) {
      expect(_offenders(dir, (uri) => uri.contains('/data/')), isEmpty);
    }
  });

  test('data does not import presentation', () {
    for (final dir in _layers('data')) {
      expect(_offenders(dir, (uri) => uri.contains('/presentation/')), isEmpty);
    }
  });

  test('ui does not import features or app', () {
    expect(
      _offenders(
        'lib/src/ui',
        (uri) => uri.contains('/src/features/') || uri.contains('/src/app/'),
      ),
      isEmpty,
    );
  });
}
