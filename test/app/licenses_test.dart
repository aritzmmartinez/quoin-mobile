import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/app/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the licence page lists the fonts and the Maven libraries', () async {
    registerLicenses();
    final byPackage = <String, String>{};
    await for (final entry in LicenseRegistry.licenses) {
      final text = entry.paragraphs.map((p) => p.text).join('\n');
      for (final package in entry.packages) {
        byPackage[package] = text;
      }
    }

    expect(byPackage['Geist'], contains('SIL Open Font License'));
    for (final package in ['ZXing', 'Guava', 'CameraX', 'Tink', 'AndroidX']) {
      expect(byPackage[package], contains('Apache License'), reason: package);
    }
    expect(
      byPackage['checker-qual'],
      allOf(contains('Checker Framework developers'), contains('MIT')),
    );
    expect(byPackage['Protocol Buffers'], contains('Google Inc.'));
  });
}
