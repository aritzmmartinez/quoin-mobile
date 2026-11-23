import 'dart:convert';
import 'dart:io';

import 'package:quoin_core/quoin_core.dart';
import 'package:test/test.dart';

void main() {
  final contract =
      jsonDecode(File('test/contract/exposure-default.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases =
      (contract['cases'] as List<dynamic>).cast<Map<String, dynamic>>();

  group('exposure-default contract', () {
    test('has every case', () => expect(cases, hasLength(11)));

    for (final c in cases) {
      test(c['name'] as String, () {
        final instrument = c['instrument'] as Map<String, dynamic>;
        final kind = instrument['exposureKind'] as String?;
        final expected = c['expect'] as Map<String, dynamic>;

        final exposure = effectiveExposure(
          instrument['type'] as String,
          kind == null ? null : ExposureKind.of(kind),
        );

        expect(exposure.kind?.code, expected['kind']);
        expect(exposure.source.name, expected['source']);
      });
    }
  });

  test('a type the app does not know has no category', () {
    final exposure = effectiveExposure('WARRANT', null);
    expect(exposure.kind, isNull);
    expect(exposure.source, ExposureSource.none);
  });
}
