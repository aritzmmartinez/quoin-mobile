import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only quoin_icons.dart and quoin_icon.dart import hugeicons', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('quoin_icons.dart'))
        .where((f) => !f.path.endsWith('quoin_icon.dart'))
        .where((f) => f.readAsStringSync().contains('package:hugeicons/'))
        .map((f) => f.path);
    expect(offenders, isEmpty);
  });

  test('only quoin_type.dart sets font sizes', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.contains('l10n${Platform.pathSeparator}gen'))
        .where((f) => !f.path.endsWith('quoin_type.dart'))
        .where((f) => f.readAsStringSync().contains('fontSize:'))
        .map((f) => f.path);
    expect(offenders, isEmpty);
  });
}
