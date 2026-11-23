import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    Future<String> text(String name) => rootBundle.loadString(name);
    yield LicenseEntryWithLineBreaks(const [
      'Geist',
      'Geist Mono',
    ], await text('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'AndroidX',
      'AutoValue annotations',
      'CameraX',
      'error_prone_annotations',
      'failureaccess',
      'Gson',
      'Guava',
      'j2objc-annotations',
      'JetBrains annotations',
      'JSpecify',
      'jsr305',
      'Kotlin',
      'kotlinx.coroutines',
      'kotlinx.serialization',
      'listenablefuture',
      'Okio',
      'ReLinker',
      'Tink',
      'ZXing',
    ], await text('assets/licenses/Apache-2.0.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'checker-qual',
    ], await text('assets/licenses/checker-qual.txt'));
    yield LicenseEntryWithLineBreaks(const [
      'Protocol Buffers',
    ], await text('assets/licenses/protobuf.txt'));
  });
}
