import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quoin/src/app/licenses.dart';
import 'package:quoin/src/app/runtime_packages.dart';
import 'package:quoin/src/features/settings/presentation/providers/settings_providers.dart';

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

  test('the page leaves out what only development needs', () {
    expect(runtimePackages, containsAll(['go_router', 'drift', 'quoin_core']));
    expect(devPackages, containsAll(['build_runner', 'drift_dev']));
    expect(devPackages.intersection(runtimePackages), isEmpty);

    LicenseEntry entry(List<String> packages) =>
        LicenseEntryWithLineBreaks(packages, 'text');
    final shown = runtimeLicenses([
      entry(['build_runner']),
      entry(['go_router']),
      entry(['skia', 'drift_dev']),
      entry(['Geist', 'Geist Mono']),
      entry(['ZXing']),
      entry(['go_router']),
    ]);
    expect(shown.keys, ['Geist', 'Geist Mono', 'go_router', 'skia', 'ZXing']);
    expect(shown['go_router'], hasLength(2));
  });
}
