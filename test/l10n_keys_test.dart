import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String locale) {
  final arb = jsonDecode(
    File('lib/src/core/l10n/app_$locale.arb').readAsStringSync(),
  ) as Map<String, Object?>;
  return arb.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test('es and en ARB files have the same keys', () {
    final es = _keys('es');
    final en = _keys('en');
    expect(es.difference(en), isEmpty, reason: 'missing in en');
    expect(en.difference(es), isEmpty, reason: 'missing in es');
  });
}
